//
//  CSWScheduleStore.m
//  Gymclass
//
//  Created by Eric Colton on 11/25/12.
//  Copyright (c) 2012 Cindy Software. All rights reserved.
//

#import "CSWAppDelegate.h"
#import "CSWScheduleStore.h"

#import "WebAbstract.h"

#import "CSWDay.h"
#import "CSWDayMarker.h"
#import "CSWWeek.h"
#import "CSWTime.h"
#import "CSWWorkout.h"
#import "CSWWod.h"
#import "CSWInstructor.h"
#import "CSWLocation.h"

#import "AFNetworking/AFNetworking.h"

#define kAppConfig       @"appConfig"
#define kLastCachedTimes @"lastCachedTimes"
#define kCookies         @"cookies"

static CSWScheduleStore *staticStore = nil;

static NSUserDefaults *userDefaults;
static NSLocale *gLocale;
static NSDateFormatter *gWorkoutDayFormatter;
static NSDateFormatter *gListingDateFormatter;
static NSMutableDictionary *gCachedLocationsByName;

@interface CSWScheduleStore()
{
    NSPersistentStoreCoordinator *psc;
    NSManagedObjectContext *mainThreadMoc;
    NSOperationQueue *webQueue;
    NSTimeZone *_timeZone;
    NSManagedObjectContext *_backgroundThreadMoc;
}

+(NSURL *)appDocumentsDir;
+(NSData *)synchronousWebRequest:(NSURLRequest *)aUrlRequest error:(NSError **)aError;

-(BOOL)refreshReservationStatusesWithCompletion:(void(^)(NSError *))aBlock;

+(void)saveCookies;
+(void)loadCookies;
+(void)deleteCookie:(NSString *)aCookieName;

-(BOOL)isCacheRefreshNeededForDataType:(NSString *)aCacheDataType forObject:(id)cacheObject;
-(void)recordCacheDidRefreshForDataType:(NSString *)aCacheDataType forObject:(id)cacheObject;

@property (nonatomic, readonly) WebAbstract *servicerWebAbstract;
@property (nonatomic, readonly) WebAbstract *signupWebAbstract;

@end

@implementation CSWScheduleStore

////
#pragma mark class methods (public)
////
+(void)initialize
{
    staticStore = nil;
    
    userDefaults = [NSUserDefaults standardUserDefaults];
    
    gLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    
    gWorkoutDayFormatter = [[NSDateFormatter alloc] init];
    gWorkoutDayFormatter.locale = gLocale;
    gWorkoutDayFormatter.dateFormat = @"EEEE, MMMM dd, yyyy";
    
    gListingDateFormatter = [[NSDateFormatter alloc] init];
    gListingDateFormatter.locale = gLocale;
    gListingDateFormatter.dateFormat = @"yyyy-MM-dd";
    
    gCachedLocationsByName = [[NSMutableDictionary alloc] init];
    
    [CSWScheduleStore loadCookies];
}

+(CSWScheduleStore *)sharedStore
{
    if ( !staticStore ) staticStore = [[CSWScheduleStore alloc] init];
    return staticStore;
}

////
#pragma mark init methods (public)
////
-(id)init {

    self = [super init];
    if ( self ) {
        mainThreadMoc = [(CSWAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
        webQueue = [NSOperationQueue new];
    }

    return self;
}

////
#pragma mark accessor methods
////
-(NSManagedObjectContext *)backgroundThreadMoc
{
    if ( _backgroundThreadMoc ) return _backgroundThreadMoc;
    
    static dispatch_once_t onceToken;
    dispatch_once (&onceToken, ^{
        _backgroundThreadMoc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _backgroundThreadMoc.persistentStoreCoordinator = [(CSWAppDelegate *)[[UIApplication sharedApplication] delegate] persistentStoreCoordinator];
        _backgroundThreadMoc.undoManager = nil;
    });

    return _backgroundThreadMoc;
}

-(NSTimeZone *)timeZone
{
    if ( _timeZone ) return _timeZone;
    
    NSString *timeZoneString = [self fetchGymConfigValue:@"timeZone"];
    if ( !timeZoneString ) timeZoneString = @"America/New_York";
    
    _timeZone = [NSTimeZone timeZoneWithName:timeZoneString];
    
    return _timeZone;
}

////
#pragma mark instance methods (public)
////
-(bool)fetchConfigForAllGymsWithCompletion:(void(^)(bool, NSDictionary *, NSError *))aCompletionBlock;
{
    if ( USE_BUNDLED_APP_CONFIG ) {
        
        static NSDictionary *appConfig = nil;
        
        if ( !appConfig ) {
            
            NSString *appConfigPath = [[NSBundle mainBundle] pathForResource:@"gymclassConfig" ofType:@"plist"];
            appConfig = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfFile:appConfigPath]
                                                                  options:NSPropertyListImmutable
                                                                   format:NULL
                                                                    error:nil
                         ];

            [userDefaults setObject:appConfig forKey:kAppConfig];

            if ( LOG_DEBUG )
                NSLog(@"Loaded app_config from bundled plist");
        }

        if ( aCompletionBlock ) {
            aCompletionBlock( false, appConfig[@"gyms"], nil );
        }

        return false;
    
    } else {

        bool refreshing;
        
        if ( [self isCacheRefreshNeededForDataType:kAppConfig forObject:nil] ) {
            
            NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:APP_CONFIG_URL]
                                                             cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                         timeoutInterval:WEB_TIMEOUT_SECS
                                        ];
            
            void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        
                    NSError *error;
                    NSDictionary *appConfig = [NSPropertyListSerialization propertyListWithData:operation.responseData
                                                                                        options:NSPropertyListImmutable
                                                                                         format:NULL
                                                                                          error:&error
                                               ];

                    if ( error ) {
                        aCompletionBlock( false, nil, error );
                        return;
                    }
                        
                    if ( ![appConfig objectForKey:@"_validated"] ) {

                        aCompletionBlock( false, nil, [NSError errorWithDomain:kExceptionStore
                                                                          code:0
                                                                      userInfo:@{NSLocalizedDescriptionKey : @"Unable to understand configuration from network." }
                                                       ]
                                         );
                        return;
                    }
                        
                    if ( LOG_DEBUG )
                        NSLog(@"Refreshed app config from web");
                        
                    [userDefaults setObject:appConfig forKey:kAppConfig];
                    
                    [self recordCacheDidRefreshForDataType:kAppConfig forObject:nil];
                        
                    if ( aCompletionBlock ) {
                        aCompletionBlock( true, appConfig[@"gyms"], nil );
                    }
                }];
            };
            
            void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if ( aCompletionBlock ) {
                        aCompletionBlock( false, nil, error );
                    }
                }];
            };
        
            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
            [operation setSuccessCallbackQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
            [operation setCompletionBlockWithSuccess:successBlock failure:failureBlock];
            [operation start];
            
            refreshing = true;
            
        } else {
            
            if ( LOG_DEBUG )
                NSLog(@"No appConfig refresh needed");
            
            if ( aCompletionBlock ) {
                
                NSDictionary *appConfig = [userDefaults dictionaryForKey:kAppConfig][@"gyms"];
                aCompletionBlock( false, appConfig, nil );
            }
            
            refreshing = false;
        }
        
        return refreshing;
    }
}

-(void)unloadAllConfigurations
{
    [self expireAllCachedConfigurations];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:kAppConfig];
    [userDefaults removeObjectForKey:kLastCachedTimes];
}

-(BOOL)setupForGymId:(NSString *)aGymId error:(NSError *__autoreleasing *)aError
{
    NSDictionary *appConfigForGym = [[[userDefaults dictionaryForKey:kAppConfig] objectForKey:@"gyms"] objectForKey:aGymId];
    static WebAbstractConfig *commonServicerWebConfig = nil, *signupWebConfig = nil;
    
    if ( !appConfigForGym )
        [NSException raise:kExceptionGymConfigError
                    format:@"Gym '%@' was specified, but this is not a valid gymId", aGymId
         ];

    // dont use any cached conifgurations if we're switching gyms
    NSString *prevGymId = [userDefaults objectForKey:@"prevGymId"];
    if ( !prevGymId || ![aGymId isEqualToString:prevGymId] ) {
        [self expireAllCachedConfigurations];
        _timeZone = nil;
    }
    
    if ( USE_BUNDLED_SERVICER_CONFIG ) {

        if ( !commonServicerWebConfig ) {
        
            NSString *commonServicerConfigPath = [NSString stringWithFormat:@"COMMON_servicer_web_config"];
            commonServicerWebConfig = [[WebAbstractConfig alloc] initWithBundledPlist:commonServicerConfigPath];

            if ( LOG_DEBUG )
                NSLog(@"Loaded servicer WebAbstract from bundled plist for gym '%@'", aGymId);
        }
        
    } else {
        
        NSString *commonUrlStr = [NSString stringWithFormat:@"%@/COMMON/COMMON_servicer_web_config.plist", GYM_CONFIG_URL_PREFIX];
        commonServicerWebConfig = [[WebAbstractConfig alloc] initWithURL:[NSURL URLWithString:commonUrlStr]];
        commonServicerWebConfig.cachePolicy = NSURLRequestReloadIgnoringCacheData;
       
        if ( [self isCacheRefreshNeededForDataType:@"servicerWebConfig" forObject:nil] ) {

            NSError *error;
            [commonServicerWebConfig refreshFromWeb:&error];
            if ( error ) {
                *aError = error;
                return YES;
            }
            
            [self recordCacheDidRefreshForDataType:@"servicerWebConfig" forObject:nil];
            
        } else {

            commonServicerWebConfig.configStruct = [userDefaults objectForKey:@"commonServicerWebConfigStruct"];
        }
    }

    if ( USE_BUNDLED_SIGNUP_CONFIG ) {
        
        if ( !signupWebConfig ) {
            
            NSString *signupConfigPath = [NSString stringWithFormat:@"COMMON_signup_web_config"];
            signupWebConfig = [[WebAbstractConfig alloc] initWithBundledPlist:signupConfigPath];
                
            if ( LOG_DEBUG )
                NSLog(@"Loaded '%@' from bundled plist for local gym", signupConfigPath);
        }
            
    } else {
            
        NSString *urlStr = [NSString stringWithFormat:@"%@/COMMON/COMMON_signup_web_config.plist", GYM_CONFIG_URL_PREFIX];
        signupWebConfig = [[WebAbstractConfig alloc] initWithURL:[NSURL URLWithString:urlStr]];
        signupWebConfig.cachePolicy = NSURLRequestReloadIgnoringCacheData;
        
        if ( [self isCacheRefreshNeededForDataType:@"signupWebConfig" forObject:nil] ) {
            
            NSError *error;
            [signupWebConfig refreshFromWeb:&error];
            if ( error ) {
                *aError = error;
                return YES;
            }
                
            [self recordCacheDidRefreshForDataType:@"signupWebConfig" forObject:nil];
                 
        } else {
            
            signupWebConfig.configStruct = [userDefaults objectForKey:@"signupWebConfigStruct"];
        }
    }

    //
    // The point of this last part is to set the 'urlHardPrefix' on the servicerDataScraper config.
    // Setting a hardPrefix (my term, meaning domain name in a url but not subdomain)
    // ensures (proves) no configuration could send servicer requests to any alternate
    // domain on the internet.  This is important because credentials are sent to the servicer.
    //
    // The subdomain portion of servicer URLs are not "hard" and can be configured as needed for a given gym.
    //
    // Not that localDataScraper (local gym website) does not have the same "hard" url domain restrictions,
    // but credentials are not sent there.
    //
    NSString *subdomain = [self fetchGymConfigValue:@"servicerSubdomain" forKey:nil forGymId:aGymId];

    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[a-zA-Z0-9\\-\\.]+$"
                                                                           options:0
                                                                             error:&error
                                  ];

    if ( error ) {
        [NSException raise:kExceptionGymConfigError
                    format:@"could not build subdomain parser for gym '%@'.  Error: '%@'", aGymId, [error localizedDescription]
         ];
    }
    
    NSArray *matches = [regex matchesInString:subdomain options:0 range:NSMakeRange(0, subdomain.length)];
    if ( !matches.count ) {
        [NSException raise:kExceptionGymConfigError format:@"specified subdomain for gym '%@' is invalid", aGymId];
    }

    //
    // All configurations succceeded without throwing exceptions or enountering network errors.
    // Finally we can set everything.
    //
    _gymId = aGymId;
    [userDefaults setObject:aGymId forKey:@"prevGymId"];

    _servicerWebAbstract = [[WebAbstract alloc] initWithConfig:commonServicerWebConfig];

    _servicerWebAbstract.urlHardPrefix = BACKEND_CONFIGURATION_DOMAIN;
    [userDefaults setObject:commonServicerWebConfig.configStruct forKey:@"commonServicerWebConfigStruct"];

    _signupWebAbstract = [[WebAbstract alloc] initWithConfig:signupWebConfig];
    _signupWebAbstract.urlHardPrefix = [NSString stringWithFormat:@"%@.%@", subdomain, BACKEND_SERVICER_DOMAIN];
    [userDefaults setObject:signupWebConfig.configStruct forKey:@"signupWebConfigStruct"];
        
    NSDictionary *locationsNamesMap = [self fetchGymConfigValue:@"locationNamesMap"];
    [CSWLocation setDisplayNamesMap:locationsNamesMap];

    NSDictionary *instructorsNamesMap = [self fetchGymConfigValue:@"instructorsNamesMap"];
    [CSWInstructor setDisplayNamesMap:instructorsNamesMap];
    
    NSDictionary *workoutTypesMap = [self fetchGymConfigValue:@"workoutTypesMap"];
    [CSWWorkout setDisplayTypesMap:workoutTypesMap];
    
    NSString *workoutPreMapDisplayTypesRegEx = [self fetchGymConfigValue:@"workoutPreMapDisplayNameRegEx"];
    [CSWWorkout setPreMapDisplayTypesRegEx:workoutPreMapDisplayTypesRegEx];
    
    NSArray *depricatedLocations = [self fetchGymConfigValue:@"depricatedLocations"];
    [CSWLocation depricateLocationNames:depricatedLocations];
    
    NSArray *depricatedInstructors = [self fetchGymConfigValue:@"depricatedInstructors"];
    [CSWInstructor depricateInstructorNames:depricatedInstructors];
    
    return NO;
}


-(bool)loadScheduleForDay:(CSWDay *)aDay
   weekScheduleCompletion:(void(^)(bool, NSError *))weekScheduleBlock
   reservationsCompletion:(void(^)(NSError *))reservationsBlock
   daySpotsLeftCompletion:(void(^)(NSError *))daySpotsLeftBlock
        wodDescCompletion:(void(^)(NSError *))wodDescBlock
{
    
    if ( !self.gymId ) {
        [NSException raise:kExceptionNoGymId format:@"Cannot fetch workoutSummaries without a gymId configured"];
    }

    CSWDay *sundayDay = [aDay findPreviousSunday];
    
    CSWWeek *week = [CSWWeek weekWithStartDay:sundayDay
                                        gymId:self.gymId
                                          moc:mainThreadMoc
                     ];

    CSWMembership *membership = [CSWMembership sharedMembership];

    bool queryByWeek = [[self fetchGymConfigValue:@"queryByWeek"] boolValue];
    __block bool didRequestReservationStatuses = false;
    
    int refreshing = 0;
    if ( [self isCacheRefreshNeededForDataType:@"workoutListings" forObject:week] ) {
        
        refreshing |= 1;
        
        int queryCount = ( queryByWeek ) ? 1 : 7;
        __block int querySucceededCount = 0;
        __block bool didFail = NO;

        // Zenplanner API allows only 1 day at a time querying per request, so restrict to that
        for ( int i = 0; i < queryCount; i++ ) {
            
            CSWDay *activeDay = [sundayDay addDays:i];
            
            NSURLRequest *urlRequest = [self.servicerWebAbstract buildUrlRequestForOperation:@"fetchWorkouts"
                                                                                forSourceTag:@"fetchWorkouts"
                                                                               withVariables:@{ @"startDate" : activeDay.asNumber
                                                                                               ,@"timeZone"  : self.timeZone.name
                                                                                               ,@"gymId"     : membership.gymId
                                                                                               ,@"period"    : ( queryByWeek ) ? @"week" : @"day"
                                                                                              }
                                        ];
            
            void (^successBlock)(AFHTTPRequestOperation*, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
            
                NSDictionary *responseStruct = [self.servicerWebAbstract parseData:operation.responseData
                                                                      forOperation:@"fetchWorkouts"
                                                                      forOutputTag:@"fetchWorkouts"
                                                ];
                
                @synchronized(self.backgroundThreadMoc) {
                
                    NSMutableSet *workoutIds = [NSMutableSet new];
                    
                    for ( NSDictionary *workoutDict in responseStruct[@"schedule"] ) {
                        
                        // a slight hack; it would be nice if we could shove 'displayable' into the output from parseData: call above
                        NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:workoutDict];
                        mutableDict[@"displayable"] = @1;
                        
                        [workoutIds addObject:workoutDict[@"id"]];

                        [CSWWorkout workoutWithDict:mutableDict withMoc:self.backgroundThreadMoc];
                     }

                    [CSWWorkout purgeWorkoutsNotInSet:workoutIds
                                               ForDay:responseStruct[@"date"]
                                             forGymId:membership.gymId
                                              withMoc:self.backgroundThreadMoc
                     ];

                     [self.backgroundThreadMoc save:NULL];
                }
                
                if ( ++querySucceededCount == queryCount ) {
                    
//                    @synchronized( self ) {
                        
                        if ( !didRequestReservationStatuses && self.isLoggedIn ) {
                            
                            didRequestReservationStatuses = true;
                            
                            if ( [self isCacheRefreshNeededForDataType:@"workoutSignupStatuses" forObject:nil] ) {
                                
                                [self refreshReservationStatusesWithCompletion:^(NSError *error) {
                                    
                                    if ( reservationsBlock ) {
                                        reservationsBlock( error ); // error may be nil
                                    }
                                    
                                    if ( !error ) {
                                        [self recordCacheDidRefreshForDataType:@"workoutSignupStatuses" forObject:nil];
                                    }
                                }];
                                
                            } else {
                                
                                if ( reservationsBlock ) {
                                    reservationsBlock( nil );
                                }
                            }
                        }
//                    }
                    
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        
                        if ( weekScheduleBlock ) {
                            weekScheduleBlock( true, nil );
                        }
        
                        [self recordCacheDidRefreshForDataType:@"workoutListings" forObject:week];
                        [mainThreadMoc save:NULL];
                    }];
                }
            };
            
            void (^failureBlock)(AFHTTPRequestOperation*, NSError*) = ^void(AFHTTPRequestOperation *operation, NSError *error){
                
                //avoiding calling didFail repeatedly
                if ( !didFail ) {
                    didFail = YES;
                    if ( weekScheduleBlock ) {
                        weekScheduleBlock( false, error );
                    }
                }
            };

            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
            operation.successCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            operation.failureCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            [operation setCompletionBlockWithSuccess:successBlock failure:failureBlock];
            
            [operation start];
        }
        
    } else {
        
        if ( !didRequestReservationStatuses && self.isLoggedIn ) {
            
            if ( [self isCacheRefreshNeededForDataType:@"workoutSignupStatuses" forObject:nil] ) {
        
                [self refreshReservationStatusesWithCompletion:^(NSError *error) {
                    
                    if ( reservationsBlock ) {
                        reservationsBlock( error ); // error may be nil
                    }
            
                    [self recordCacheDidRefreshForDataType:@"workoutSignupStatuses" forObject:nil];
                }];
                
            } else {
                
                if ( reservationsBlock ) {
                    reservationsBlock( nil );
                }
            }
        }
        
        if ( weekScheduleBlock ) {
            weekScheduleBlock( false, nil );
        }
    }
    
    if ( [self.servicerWebAbstract isOperationAvailable:@"fetchWorkouts" forSourceTag:@"fetchSpotsRemaining"] ) {

        CSWDayMarker *dayMarker = [CSWDayMarker dayMarkerWithDay:aDay withMoc:mainThreadMoc];

        if (    [[self fetchGymConfigValue:@"canFetchSpotsRemaining"] boolValue]
             && [self isCacheRefreshNeededForDataType:@"workoutSpotsRemaining" forObject:dayMarker]
           ) {
            
            refreshing |= 1;

            NSURLRequest *urlRequestForSpots = [self.servicerWebAbstract buildUrlRequestForOperation:@"fetchWorkouts"
                                                                                        forSourceTag:@"fetchSpotsRemaining"
                                                                                       withVariables:@{ @"date"  : aDay.asNumber
                                                                                                       ,@"gymId" : membership.gymId
                                                                                                      }
                                                ];
            
            void (^successBlock)(AFHTTPRequestOperation*, id) = ^(AFHTTPRequestOperation *operation, id responseObject){

                NSDictionary *responseStruct = [self.servicerWebAbstract parseData:operation.responseData
                                                                      forOperation:@"fetchWorkouts"
                                                                      forOutputTag:@"fetchSpotsRemaining"
                                                ];
                    
                @synchronized( self.backgroundThreadMoc ) {
                        
                    for ( NSDictionary *dict in responseStruct[@"appointmentSpots"] ) {
                    
                        CSWWorkout *workout = [CSWWorkout workoutWithId:dict[@"workoutId"] withMoc:self.backgroundThreadMoc wasCreated:NULL];
                            
                        NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:dict];
                        [workout populateWithDict:mutableDict withMoc:self.backgroundThreadMoc];
                    }
                        
                    [self.backgroundThreadMoc save:NULL];
                }
                
                //i think this block could include only mainThreadMoc save
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        
                    if ( daySpotsLeftBlock ) {
                        daySpotsLeftBlock( nil );
                    }
                        
                    [self recordCacheDidRefreshForDataType:@"workoutSpotsRemaining" forObject:dayMarker];
                    [mainThreadMoc save:NULL];
                }];
            };
            
            void (^failureBlock)(AFHTTPRequestOperation*, NSError*) = ^(AFHTTPRequestOperation *operation, NSError *error) {
                if ( daySpotsLeftBlock ) {
                    daySpotsLeftBlock( error );
                }
            };
    
            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequestForSpots];
            [operation setCompletionBlockWithSuccess:successBlock failure:failureBlock];
            operation.successCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            operation.failureCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            [operation start];

        } else {
            
            if ( daySpotsLeftBlock ) {
                daySpotsLeftBlock( nil );
            }
        }
    }

    NSNumber *canFetchWodDesc = [self fetchGymConfigValue:@"canFetchWodDesc"];
    if ( canFetchWodDesc && canFetchWodDesc.boolValue ) {

        CSWWod *wod = [CSWWod wodWithDay:aDay withMoc:mainThreadMoc];
    
        if ( [self isCacheRefreshNeededForDataType:@"wodDesc" forObject:wod] ) {
            
            refreshing |= 1;
            
            NSURLRequest *urlRequestForWod = [self.servicerWebAbstract buildUrlRequestForOperation:@"fetchWorkouts"
                                                                                      forSourceTag:@"fetchWorkoutDesc"
                                                                                     withVariables:@{ @"date"  : aDay.asNumber
                                                                                                     ,@"gymId" : membership.gymId
                                                                                                    }
                                              ];
            
            void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject){

                NSDictionary *wodDict = [self.servicerWebAbstract parseData:operation.responseData
                                                               forOperation:@"fetchWorkouts"
                                                               forOutputTag:@"fetchWorkoutDesc"
                                         ];

                @synchronized(self.backgroundThreadMoc) {
                    [wod populateWithDict:wodDict withMoc:self.backgroundThreadMoc];
                    [self.backgroundThreadMoc save:NULL];
                }
 
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                    if ( wodDescBlock ) {
                        wodDescBlock( nil );
                    }
                                
                    [self recordCacheDidRefreshForDataType:@"wodDesc" forObject:wod];
                    [mainThreadMoc save:NULL];
                }];
            };
            
            void (^failureBlock)(AFHTTPRequestOperation*, NSError*) = ^(AFHTTPRequestOperation *operation, NSError *error){

                // we record cache refresh even on failure because failure is normal here
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if ( wodDescBlock ) {
                        wodDescBlock( nil );
                    }
                                
                    [self recordCacheDidRefreshForDataType:@"wodDesc" forObject:wod];
                    [mainThreadMoc save:NULL];
                }];
            };

            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequestForWod];
            [operation setCompletionBlockWithSuccess:successBlock failure:failureBlock];
            operation.successCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            operation.failureCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            [operation start];
        
        } else {
        
            if ( wodDescBlock ) {
                wodDescBlock( nil );
            }
        }
        
    } else {
        
        if ( wodDescBlock ) {
            wodDescBlock( nil );
        }
    }

    return !!refreshing;
}


-(void)queryWorkout:(CSWWorkout *)aWorkout
      withQueryType:(WorkoutQueryType)aQueryType
     withCompletion:(void(^)(NSError *))aBlock
{
    if ( !self.gymId )
        [NSException raise:kExceptionNoGymId format:@"Cannot query workout without a gymId configured"];

    NSString *sourceTag;
    switch ( aQueryType ) {
                
        case WorkoutQueryTypeSignup:
            sourceTag = @"signup";
            break;
        case WorkoutQueryTypeCancelSignup:
            sourceTag = @"cancelSignup";
            break;
        case WorkoutQueryTypeWaitlist:
            sourceTag = @"waitlist";
            break;
        case WorkoutQueryTypeCancelWaitlist:
            sourceTag = @"cancelWaitlist";
            break;
        default:
            [NSException raise:kExceptionStore
                        format:@"Invalid WorkoutQueryType specified"
             ];
    }
    
    CSWMembership *membership = [CSWMembership sharedMembership];
    
    NSMutableDictionary *urlVariables = [NSMutableDictionary dictionaryWithDictionary:@{ @"workoutId"    : aWorkout.workoutId      ? aWorkout.workoutId      : @""
                                                                                        ,@"membershipId" : membership.membershipId ? membership.membershipId : @""
                                                                                        ,@"personId"     : membership.personId     ? membership.personId     : @""
                                                                                        ,@"attendanceId" : @""   // may be overridden
                                                                                        ,@"waitlistId"   : @""   // may be overridden
                                                                                       }
                                         ];

    if (    ( !membership.membershipId && ( aQueryType == WorkoutQueryTypeSignup || aQueryType == WorkoutQueryTypeWaitlist ) )
         || ( aQueryType == WorkoutQueryTypeCancelSignup || aQueryType == WorkoutQueryTypeCancelWaitlist )
       ) {
        
        // Annoyingly, membership is only available on a workout detail page
        NSURLRequest *mRequest = [self.signupWebAbstract buildUrlRequestForOperation:@"queryWorkout"
                                                                        forSourceTag:@"getDetail"
                                                                       withVariables:@{ @"workoutId" : aWorkout.workoutId }
                                  ];
        
        void (^getDetailSuccessBlock)(AFHTTPRequestOperation*, id) = ^(AFHTTPRequestOperation *operation, NSError *error) {

            NSDictionary *workoutDetailDict = [self.signupWebAbstract parseData:operation.responseData
                                                                   forOperation:@"queryWorkout"
                                                                   forOutputTag:@"getDetail"
                                               ];

            if ( !workoutDetailDict || workoutDetailDict.count == 0 ) {
                
                if ( aBlock ) {
                    NSError *error = [NSError errorWithDomain:kErrorDomainSignup
                                                         code:kErrorCodeUnexpectedServicerResponse
                                                     userInfo:nil
                                      ];
                    aBlock(error);

                }
                
                return;
                
            } else if ( aQueryType == WorkoutQueryTypeWaitlist && workoutDetailDict[@"waitlistIsFull"] ) {
                
                if ( aBlock ) {
                    NSError *error = [NSError errorWithDomain:kErrorDomainSignup
                                                         code:kErrorCodeWaitlistIsFull
                                                     userInfo:nil
                                      ];
                    aBlock(error);
                }
                
                return;
            }
            
            if ( aQueryType == WorkoutQueryTypeSignup || aQueryType == WorkoutQueryTypeWaitlist ) {
                
                if ( !membership.membershipId && workoutDetailDict[@"membershipId"] && ![workoutDetailDict[@"membershipId"] isEqualToString:@""] ) {
                    membership.membershipId = workoutDetailDict[@"membershipId"];
                    [membership persistSave];
                    urlVariables[@"membershipId"] = workoutDetailDict[@"membershipId"];
                }
                
            } else if ( aQueryType == WorkoutQueryTypeCancelSignup ) {
                
                if ( [workoutDetailDict objectForKey:@"cannotUndo"] ) {
                    
                    if ( aBlock ) {
                        
                        NSError *error = [NSError errorWithDomain:kErrorDomainSignup
                                                             code:kErrorCodeCannotUndo
                                                         userInfo:nil
                                          ];
                        aBlock(error);
                    }
                    
                    return;
                    
                } else {
                    
                    urlVariables[@"attendanceId"] = workoutDetailDict[@"attendanceId"];
                }
                
            } else if ( aQueryType == WorkoutQueryTypeCancelWaitlist ) {
                
                urlVariables[@"waitlistId"] = workoutDetailDict[@"waitlistId"];
            }
            
            NSURLRequest *executeQueryRequest = [self.signupWebAbstract buildUrlRequestForOperation:@"queryWorkout"
                                                                                       forSourceTag:sourceTag
                                                                                      withVariables:urlVariables
                                                 ];
            
            [self executeQuery:executeQueryRequest withCompletion:aBlock];
        };
        
        void (^getDetailFailureBlock)(AFHTTPRequestOperation*, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error){
            
            if ( aBlock ) {
                aBlock( error );
            }
        };

        AFHTTPRequestOperation *getDetailOperation = [[AFHTTPRequestOperation alloc] initWithRequest:mRequest];
        getDetailOperation.successCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        getDetailOperation.failureCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        [getDetailOperation setCompletionBlockWithSuccess:getDetailSuccessBlock failure:getDetailFailureBlock];
        [getDetailOperation start];

    } else {
        
        NSURLRequest *executeQueryRequest = [self.signupWebAbstract buildUrlRequestForOperation:@"queryWorkout"
                                                                                   forSourceTag:sourceTag
                                                                                  withVariables:urlVariables
                                             ];
        
        [self executeQuery:executeQueryRequest withCompletion:aBlock];
    }
}

-(BOOL)refreshReservationStatusesWithCompletion:(void(^)(NSError *))aBlock
{
    if ( !self.gymId )
        [NSException raise:kExceptionNoGymId format:@"Cannot refresh without a gymId configured"];

    CSWMembership *membership = [CSWMembership sharedMembership];
    
    NSDictionary *urlVariables = @{ @"personId" : membership.personId ? membership.personId : @"" };
    
    NSURLRequest *urlRequest = [self.signupWebAbstract buildUrlRequestForOperation:@"refreshReservations"
                                                                      forSourceTag:@"refreshReservations"
                                                                     withVariables:urlVariables
                                ];

    void (^successBlock)(AFHTTPRequestOperation*, id) = ^(AFHTTPRequestOperation *operation, id respsonseObject){

        CSWDay *today = [CSWDay day];
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Workout"];
        request.predicate = [NSPredicate predicateWithFormat:@"gymId = %@ AND day >= %d", self.gymId, today.asNumber.intValue];
        
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES]];
        
        NSArray *reservationStatuses = [self.signupWebAbstract parseData:operation.responseData
                                                            forOperation:@"refreshReservations"
                                                            forOutputTag:@"refreshReservations"
                                        ];
        
        NSString *reservedStatus = [self fetchGymConfigValue:@"workoutStatusReserved" forKey:nil forGymId:self.gymId];
        NSString *waitlistStatus = [self fetchGymConfigValue:@"workoutStatusWaitlist" forKey:nil forGymId:self.gymId];
        
        NSMutableSet *reservedWorkouts = [NSMutableSet new];
        NSMutableSet *waitlistWorkouts = [NSMutableSet new];
        
        @synchronized( self.backgroundThreadMoc ) {

            for ( NSDictionary *reservationStatus in reservationStatuses ) {

               BOOL didCreateWorkout = NO;
                CSWWorkout *workout = [CSWWorkout workoutWithId:reservationStatus[@"workoutId"]
                                                        withMoc:self.backgroundThreadMoc
                                                    wasCreated:&didCreateWorkout
                                       ];
                
                //this is a hack to get future reservations that were made to appear in "future"
                //workouts listing so they can be marked as reserved/waitlisted.
                if ( didCreateWorkout ) {
                    workout.day = [NSNumber numberWithInt:99999999];
                }
                
                if ( [reservationStatus[@"status"] isEqualToString:reservedStatus] ) {
                    [reservedWorkouts addObject:reservationStatus[@"workoutId"]];
                } else if ( [reservationStatus[@"status"] isEqualToString:waitlistStatus] ) {
                    [waitlistWorkouts addObject:reservationStatus[@"workoutId"]];
                } else {
                    NSLog(@"warning!: unknown reservation status: '%@'", reservationStatus[@"status"]);
                }
            }
            
            NSError *error;
            NSArray *todayAndFutureWorkouts = [self.backgroundThreadMoc executeFetchRequest:request error:&error];
        
            if ( error ) {
                [NSException raise:kExceptionCoreDataError
                            format:@"could not execute request to workouts for today and in the future: %@", [error localizedDescription]
                 ];
            }
        
            NSDictionary *loggedInDict = [self.signupWebAbstract parseData:operation.responseData
                                                              forOperation:@"loginUser"
                                                              forOutputTag:@"isLoggedIn"
                                          ];
            
            if ( !loggedInDict[@"isLoggedIn"] ) {

                // should be logged in ... but apparently the user somehow logged out!
                NSError *error = [NSError errorWithDomain:kErrorDomainLogin
                                                     code:kErrorCodeNotLoggedIn
                                                 userInfo:nil
                                  ];

                if ( aBlock ) aBlock( error );
                return;
            }
        
            for ( CSWWorkout *workout in todayAndFutureWorkouts ) {

                if ( workout.isSignedUp.boolValue ) {
                    if ( ![reservedWorkouts containsObject:workout.workoutId] ) {
                        workout.isSignedUp = [NSNumber numberWithBool:NO];
                    }
                } else {
                    if ( [reservedWorkouts containsObject:workout.workoutId] ) {
                        workout.isSignedUp = [NSNumber numberWithBool:YES];
                    }
                }
            
                if ( workout.isOnWaitlist.boolValue ) {
                    if ( ![waitlistWorkouts containsObject:workout.workoutId] ) {
                        workout.isOnWaitlist = [NSNumber numberWithBool:NO];
                    }
                } else {
                    if ( [waitlistWorkouts containsObject:workout.workoutId] ) {
                        workout.isOnWaitlist = [NSNumber numberWithBool:YES];
                    }
                }
            }
        
            [self.backgroundThreadMoc save:NULL];
        }
        
        if ( aBlock ) {
            aBlock( nil );
        }
    };
    

    
    void (^failureBlock)(AFHTTPRequestOperation*, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error){
        
        if ( aBlock ) {
            aBlock( error );
        }
    };
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    operation.successCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    operation.failureCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    [operation setCompletionBlockWithSuccess:successBlock failure:failureBlock];
    
    [operation start];
    
    return YES;
}


-(void)loginUserForcefully:(BOOL)aForcefully withCompletion:(void(^)(NSError *))aBlock
{
    CSWMembership *membership = [CSWMembership sharedMembership];
    
    NSURLRequest *isLoggedInUrlRequest = [self.signupWebAbstract buildUrlRequestForOperation:@"loginUser"
                                                                                forSourceTag:@"isLoggedIn"
                                                                               withVariables:@{}
                                          ];

    void (^coldLogin)() = ^{
        
        // is resetting cookies needed?
        [CSWScheduleStore resetCookies];
        
        // it looks like we need to refresh the session
        NSURLRequest *sessionUrlRequest = [self.signupWebAbstract buildUrlRequestForOperation:@"loginUser"
                                                                                 forSourceTag:@"sessionRefresh"
                                                                                withVariables:nil
                                           ];

        NSError *error;
        [CSWScheduleStore synchronousWebRequest:sessionUrlRequest error:&error];
        
        if ( error ) {
            
            if ( aBlock ) {
                aBlock( error );
            }
            
            return;
            
        } else {
        
            NSData *isLoggedInHtmlData = [CSWScheduleStore synchronousWebRequest:isLoggedInUrlRequest error:&error];

            if ( error ) {
                
                if ( aBlock ) {
                    aBlock( error );
                }
                
                return;
                
            } else {
            
                NSDictionary *isLoggedInDict = [self.signupWebAbstract parseData:isLoggedInHtmlData
                                                                    forOperation:@"loginUser"
                                                                    forOutputTag:@"fetchToken"
                                                ];
        
                NSString *xsToken = isLoggedInDict[@"xsToken"];
        
                if ( !xsToken ) {
            
                    _isLoggedIn = false;
            
                    if ( aBlock ) {
                        NSError *error = [NSError errorWithDomain:kErrorDomainLogin
                                                             code:kErrorCodeCouldNotGetToken
                                                         userInfo:nil
                                          ];
                        aBlock(error);
                    }
                    return;
                }
        
                NSURLRequest *urlRequest = [self.signupWebAbstract buildUrlRequestForOperation:@"loginUser"
                                                                                  forSourceTag:@"submitCredentials"
                                                                                 withVariables:@{ @"user"    : membership.username
                                                                                                 ,@"pass"    : membership.password
                                                                                                 ,@"xsToken" : xsToken
                                                                                                }
                                            ];
        
                // lets attempt login again
                NSData *htmlData = [CSWScheduleStore synchronousWebRequest:urlRequest error:&error];
                
                if ( error ) {
                    
                    if ( aBlock ) {
                        aBlock(error);
                    }
                    
                    return;
                    
                } else {
        
                    NSDictionary *membershipDict = [self.signupWebAbstract parseData:htmlData
                                                                        forOperation:@"loginUser"
                                                                        forOutputTag:@"verifyCredentials"
                                                    ];
        
                    if ( membershipDict.count == 0 || !membershipDict[@"personId"] ) {
            
                        _isLoggedIn = false;
            
                        if ( aBlock ) {
                            NSError *error = [NSError errorWithDomain:kErrorDomainLogin code:kErrorCodeInvalidCredentials userInfo:nil];
                            aBlock(error);
                        }
                        return;
                    }
        
                    [membership populateWithDict:membershipDict];
                    [membership persistSave];
        
                    [CSWScheduleStore saveCookies];
        
                    _isLoggedIn = true;
        
                    if( aBlock ) {
                        aBlock(nil);
                    }
                }
            }
        }
    };
    
    if ( aForcefully ) {

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), coldLogin);
        
    } else {

        void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *membershipDict = [self.signupWebAbstract parseData:operation.responseData
                                                                forOperation:@"loginUser"
                                                                forOutputTag:@"isLoggedIn"
                                            ];
            
            if ( membershipDict[@"isLoggedIn"] ) {
                
                _isLoggedIn = true;
                
                // already logged in
                if ( aBlock ) {
                    aBlock(nil);
                }
                
                return;
                
            } else {
            
                coldLogin();
            }
        };
        
        void (^failureBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, NSError *error) {
            if ( aBlock ) {
                aBlock(error);
            }
        };
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:isLoggedInUrlRequest];
        [operation setCompletionBlockWithSuccess:successBlock failure:failureBlock];
        operation.successCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        operation.failureCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        [operation start];
    }
}

-(void)logout
{
    _isLoggedIn = FALSE;
}


////
#pragma mark instance methods (private)
////
-(void)expireAllCachedConfigurations
{
    [userDefaults removeObjectForKey:kLastCachedTimes];
    
    if ( LOG_DEBUG )
        NSLog(@"Expiring all cached app-level configuation objects");
}

-(void)executeQuery:(NSURLRequest *)aRequest
     withCompletion:(void(^)(NSError *))aBlock
{
    void (^successBlock)(AFHTTPRequestOperation*, id) = ^(AFHTTPRequestOperation *operation, id respsonseObject){
        
        [self refreshReservationStatusesWithCompletion:^(NSError *error) {
            
            [self recordCacheDidRefreshForDataType:@"workoutSignupStatuses" forObject:nil];
            
            if ( aBlock ) {
                aBlock( nil );
            }
        }];
    };
    
    void (^failureBlock)(AFHTTPRequestOperation*, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error){
        
        if ( aBlock ) {
            aBlock( error );
        }
    };
    
    AFHTTPRequestOperation *executeQueryOperation = [[AFHTTPRequestOperation alloc] initWithRequest:aRequest];
    executeQueryOperation.successCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    [executeQueryOperation setCompletionBlockWithSuccess:successBlock failure:failureBlock];
    [executeQueryOperation start];
}


////
#pragma mark class methods (private)
////
+(NSURL *)appDocumentsDir
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationDirectory inDomains:NSUserDomainMask] lastObject];
}


+(void)saveCookies
{
    NSData *cookiesData = [NSKeyedArchiver archivedDataWithRootObject:[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies];
    [userDefaults setObject:cookiesData forKey:kCookies];
    [userDefaults synchronize];
}

+(void)loadCookies
{
    NSData *cookiesData = [[NSUserDefaults standardUserDefaults] objectForKey:kCookies];
    if( cookiesData.length ) {
        
        NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesData];
        [cookies enumerateObjectsUsingBlock:^(id cookie, NSUInteger idx, BOOL *stop) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }];
        
//        for ( NSHTTPCookie *cookie in cookies ) {
//            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
//        }
    }
}

+(void)deleteCookie:(NSString *)aCookieName
{
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    
    //copy array because we're deleting them as we enumerate
    NSArray *cookiesCopy = [NSArray arrayWithArray:cookieStorage.cookies];
    [cookiesCopy enumerateObjectsUsingBlock:^(id cookie, NSUInteger idx, BOOL *stop) {
        if ( [[cookie name] isEqualToString:aCookieName] ) {
            [cookieStorage deleteCookie:cookie];
        }
    }];
}

+(void)resetCookies
{
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    [cookieStorage.cookies enumerateObjectsUsingBlock:^(id cookie, NSUInteger idx, BOOL *stop) {
        [cookieStorage deleteCookie:cookie];
    }];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCookies];
}

+(void)logCookies
{
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    [cookieStorage.cookies enumerateObjectsUsingBlock:^(id cookie, NSUInteger idx, BOOL *stop) {
        NSLog(@"COOKIE: %@, %@, %@", [cookie name], [cookie expiresDate], [(NSHTTPCookie *)cookie value]);
    }];
}

+(NSData *)synchronousWebRequest:(NSURLRequest *)aUrlRequest error:(NSError **)aError
{
    NSURLResponse *urlResponse;
    NSData *htmlData = [NSURLConnection sendSynchronousRequest:aUrlRequest
                                             returningResponse:&urlResponse
                                                         error:aError
                        ];
  
    return ( aError && *aError ) ? nil : htmlData;
}

////
#pragma mark instance methods (private)
////
-(BOOL)isCacheRefreshNeededForDataType:(NSString *)aCacheDataType forObject:(id)cacheObject
{
    int cacheTimeoutInterval;
    
    id cacheTimeoutIntervalObj = [self fetchGymConfigValue:@"timeoutInterval" forKey:aCacheDataType];
    if ( !cacheTimeoutIntervalObj ) {
        
        if ( LOG_DEBUG )
            NSLog(@"Fetching initial top-level app configuration");
        
        // app configuration has not yet been downloaded
        cacheTimeoutInterval = 0;
        
    } else {
        
        cacheTimeoutInterval = [cacheTimeoutIntervalObj integerValue];
    }

    NSDate *now = [NSDate date];
    
    if ( cacheObject ) {
        
        int cacheStaleness = [now timeIntervalSinceDate:[cacheObject lastRefreshed]];
        if ( cacheStaleness < cacheTimeoutInterval ) {
            
            if ( LOG_DEBUG )
                NSLog(@"Using existing cache value for '%@'[%@] (staleness: %d/%d)", aCacheDataType, [cacheObject description], cacheStaleness, cacheTimeoutInterval);
            
            return NO;
            
        } else {
            
            if ( LOG_DEBUG )
                NSLog(@"Cache value expired for '%@'[%@] (staleness: %d/%d)", aCacheDataType, [cacheObject description], cacheStaleness, cacheTimeoutInterval);

            return YES;
        }
        
    } else {
        
        NSDictionary *lastCachedTimes = [userDefaults dictionaryForKey:kLastCachedTimes];
        if ( lastCachedTimes ) {
            
            NSDate *lastCachedVal = (NSDate *)[lastCachedTimes objectForKey:aCacheDataType];
            
            if ( lastCachedVal ) {
                
                int cacheStaleness = [now timeIntervalSinceDate:lastCachedVal];
                if ( cacheStaleness < cacheTimeoutInterval ) {
                    
                    if ( LOG_DEBUG )
                        NSLog(@"Using existing cache value for '%@' (staleness: %d/%d)", aCacheDataType, cacheStaleness, cacheTimeoutInterval);
                    
                    return NO;
                    
                } else {
                    
                    if ( LOG_DEBUG )
                        NSLog(@"Cache value expired, fetching new '%@' (goodfor: %d)", aCacheDataType,cacheTimeoutInterval);
                }
                
            } else {
                
                if ( LOG_DEBUG )
                    NSLog(@"Fetch initial cache value for '%@' (goodfor: %d)", aCacheDataType,cacheTimeoutInterval);
            }
            
        } else {
            
            if ( LOG_DEBUG )
                NSLog(@"(New Cache) Fetch initial cache value for '%@' (goodfor: %d)", aCacheDataType, cacheTimeoutInterval);
        }
        
        return YES;
    }
}

-(void)recordCacheDidRefreshForDataType:(NSString *)aCacheDataType forObject:(id)cacheObject
{
    NSDate *now = [NSDate date];
    
    if ( cacheObject ) {
        
        [cacheObject setLastRefreshed:now];
        
    } else {
        
        NSMutableDictionary *newLastCachedTimes;
        NSDictionary *lastCachedTimes = [userDefaults dictionaryForKey:kLastCachedTimes];
        
        if ( lastCachedTimes ) {
            
            newLastCachedTimes = [NSMutableDictionary dictionaryWithDictionary:lastCachedTimes];

        } else {
            
            newLastCachedTimes = [NSMutableDictionary new];
        }
        
        newLastCachedTimes[aCacheDataType] = now;
        
        [userDefaults setObject:newLastCachedTimes forKey:kLastCachedTimes];
        [userDefaults synchronize];
    }
}

-(id)fetchGymConfigValue:(NSString *)aPurpose
{
    return [self fetchGymConfigValue:aPurpose forKey:nil forGymId:self.gymId];
}

-(id)fetchGymConfigValue:(NSString *)aPurpose forKey:(NSString *)aKey
{
    return [self fetchGymConfigValue:aPurpose forKey:aKey forGymId:self.gymId];
}

-(id)fetchGymConfigValue:(NSString *)aPurpose forKey:(NSString *)aKey forGymId:(NSString *)aGymId
{
    id config;
    if ( aGymId ) {
        
        config = [[[[userDefaults dictionaryForKey:kAppConfig]
                                      objectForKey:@"gyms"]
                                      objectForKey:aGymId]
                                      objectForKey:aPurpose
                  ];
        
        if ( config ) {
            
            if ( aKey ) {
            
                id value = [config objectForKey:aKey];
                if ( value ) return value;
            
            } else {
            
                return config;
            }
        }
    }
    
    config = [[[userDefaults dictionaryForKey:kAppConfig]
                                objectForKey:@"_common"]
                                objectForKey:aPurpose
              ];
    
    if ( !config ) {

        //userDefaults return 0x0 if the dictionary doesn't even exist, not "nil"
        return nil;
        
    } else if ( aKey ) {

        return [config objectForKey:aKey];
        
    } else {
        
        return config;
    }
}

@end
