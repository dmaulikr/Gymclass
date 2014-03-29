//
//  CSWWorkout.m
//  Gymclass
//
//  Created by Eric Colton on 11/25/12.
//  Copyright (c) 2012 Cindy Software. All rights reserved.
//

#import "CSWWorkout.h"
#import "CSWDay.h"
#import "CSWTime.h"
#import "CSWAppDelegate.h"
#import "CSWLocation.h"
#import "CSWInstructor.h"
#import "CSWMembership.h"

static NSDictionary *displayTypesMap = nil;
static NSRegularExpression *preMapDisplayTypesRegEx = nil;

@interface CSWWorkout()

@end

@implementation CSWWorkout : NSManagedObject

@dynamic workoutId;
@dynamic gymId;
@dynamic location;
@dynamic instructor;
@dynamic attendanceId;
@dynamic waitlistId;
@dynamic day;
@dynamic time;
@dynamic duration;
@dynamic isFull;
@dynamic waitlistIsFull;
@dynamic isPast;
@dynamic didAttend;
@dynamic wasNoShow;
@dynamic isSignedUp;
@dynamic isOnWaitlist;
@dynamic placesAvailable;
@dynamic placesTotal;
@dynamic waitlistPlacesAvailable;
@dynamic waitlistPlacesTotal;
@dynamic type;
@dynamic displayable;
@dynamic lastRefreshed;
@dynamic deleted;

// isUpdatingToPurpose is volitile and not part of the data model
@synthesize isUpdatingToPurpose;


////
#pragma mark class methods (public)
////
+(void)initialize
{
    if ( self == [CSWWorkout class] ) {
        displayTypesMap = @{};
    }
}

+(void)setDisplayTypesMap:(NSDictionary *)aDisplayTypes
{
    displayTypesMap = [aDisplayTypes copy];
}

+(void)setPreMapDisplayTypesRegEx:(NSString *)aRegExString
{
    if ( !aRegExString ) return;
    
    NSError *error = nil;
    preMapDisplayTypesRegEx = [NSRegularExpression regularExpressionWithPattern:aRegExString
                                                                        options:0
                                                                          error:&error
                               ];
    if ( error ) {
        [NSException raise:kExceptionGymConfigError
                    format:@"Configured pre-map display types RegEx '%@' is not a valid regular expression: %@", aRegExString, [error localizedDescription]
         ];
    }
}

+(CSWWorkout *)workoutWithDict:(NSDictionary *)aDict gymId:(NSString *)aGymId withMoc:(NSManagedObjectContext *)aMoc
{
    NSString *workoutId = aDict[@"id"];
    CSWWorkout *workout = [CSWWorkout workoutWithId:workoutId gymId:aGymId withMoc:aMoc wasCreated:NULL];
    [workout populateWithDict:aDict withMoc:aMoc];
    
    return workout;
}

+(CSWWorkout *)workoutWithId:(NSString *)aWorkoutId gymId:(NSString *)aGymId withMoc:(NSManagedObjectContext *)aMoc wasCreated:(BOOL *)wasCreated
{
    //note: previously, grabbed gymId from Membership here.  But discarded that because in certain long-waiting web calls,
    // the user could potentially change gymIds before this code was called the gymId would be wrong for the eventually-returned results
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Workout"];
    request.predicate = [NSPredicate predicateWithFormat:@"gymId = %@ AND workoutId = %@", aGymId, aWorkoutId];
    
    NSError *err;
    CSWWorkout *workout = [[aMoc executeFetchRequest:request error:&err] lastObject];
    if ( err )
        [NSException raise:kExceptionCoreDataError format:@"Error fetching workout for workoutId '%@' for gymId %@", aWorkoutId, aGymId];
    
    if ( !workout ) {

        workout = [NSEntityDescription insertNewObjectForEntityForName:@"Workout"
                                                inManagedObjectContext:aMoc
                   ];
        workout.gymId = aGymId;
        workout.workoutId = aWorkoutId;
        workout.placesAvailable = @-1;
        workout.displayable = @-1;
        workout.lastRefreshed = [NSDate dateWithTimeIntervalSince1970:0];
        
        if ( wasCreated ) *wasCreated = YES;
    }

    return workout;
}

+(void)purgeAllWorkoutsForGymId:(NSString *)aGymId withMoc:(NSManagedObjectContext *)aMoc
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Workout"];
    if ( aGymId ) {
        request.predicate = [NSPredicate predicateWithFormat:@"gymId = %@", aGymId];
    }
    
    NSError *err;
    NSArray *workoutsToPurge = [aMoc executeFetchRequest:request error:&err];
    if ( err ) {
        [NSException raise:kExceptionCoreDataError format:@"Error fetching workouts for gymId '%@' to purge", aGymId];
    }
    
    for ( CSWWorkout *workout in workoutsToPurge ) {
        [aMoc deleteObject:workout];
    }
}

+(void)purgeWorkoutsNotInSet:(NSSet *)aSet
                      ForDay:(int)aDayAsInt
                    forGymId:(NSString *)aGymId
                     withMoc:(NSManagedObjectContext *)aMoc
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Workout"];
    if ( aGymId ) {
        request.predicate = [NSPredicate predicateWithFormat:@"gymId = %@ AND day = %d", aGymId, aDayAsInt];
    }
    
    NSError *err;
    NSArray *workoutsForDay = [aMoc executeFetchRequest:request error:&err];
    if ( err ) {
        [NSException raise:kExceptionCoreDataError format:@"Error fetching workouts for gymId '%@' that were depricated for day %d", aGymId, aDayAsInt];
    }
    
    for ( CSWWorkout *workout in workoutsForDay ) {
        if ( ![aSet containsObject:workout.workoutId] ) {
            [aMoc deleteObject:workout];
        }
    }
}


////
#pragma mark accessor methods (public)
////
-(NSString *)displayType
{
    NSString *type = self.type;
    
    if ( preMapDisplayTypesRegEx ) {
        NSTextCheckingResult *match = [preMapDisplayTypesRegEx firstMatchInString:type
                                                                          options:0
                                                                            range:NSMakeRange(0, type.length)
                                       ];
        if ( match ) type = [type substringWithRange:[match rangeAtIndex:1]];
    }
    
    if ( displayTypesMap ) {
        NSString *displayType = displayTypesMap[type];
        if ( displayType ) return displayType;
    }
    
    return type;
}

////
#pragma mark instance methods (public)
////
-(void)populateWithDict:(NSDictionary *)aDict withMoc:(NSManagedObjectContext *)aMoc
{
    static NSDateFormatter *dateFormatter;
    if ( !dateFormatter ) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
//        dateFormatter.dateFormat = @"EEEE, MMMM dd, yyyy hh:mm a";
        dateFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss";
    }

    @synchronized( self ) {
    
        for ( NSString *key in aDict.allKeys ) {
            
            id obj = aDict[key];
            if ( !obj || ([obj isKindOfClass:[NSString class]] && [obj isEqualToString:@""]) ) {
                continue;
            }
            
            id val = [aDict objectForKey:key];

            // API-supported
            if ( [key isEqualToString:@"title"] ) {
                
                self.type = val;
                
            } else if ( [key isEqualToString:@"location"] ) {

                CSWLocation *location = [CSWLocation locationWithName:val withMoc:aMoc];
                if ( !location ) {
                    location = [CSWLocation declareLocation:@{ @"name"  : val
                                                              ,@"gymId" : self.gymId
                                                             }
                                                    withMoc:aMoc
                                ];
                }
                
                self.location = location;
                
            } else if ( [key isEqualToString:@"instructor"] ) {
                
                CSWInstructor *instructor = [CSWInstructor instructorWithName:val withMoc:aMoc];
                if ( !instructor ) {
                    instructor = [CSWInstructor declareInstructor:@{ @"name" : val
                                                                    ,@"gymId" : self.gymId
                                                                   }
                                                          withMoc:aMoc
                                  ];
                }
                
                self.instructor = instructor;
                
            } else if ( [key isEqualToString:@"start"] ) {
                
                NSDate *dateTime = [dateFormatter dateFromString:val];
                self.day  = [CSWDay dayWithDate:dateTime].asNumber;
                self.time = [CSWTime timeWithDate:dateTime].asNumber;
            
            // "spots" API
            } else if ( [key isEqualToString:@"isFull"] ) {
                self.isFull = [NSNumber numberWithBool:[val integerValue]];
            } else if ( [key isEqualToString:@"spotsAvail"] ) {
                self.placesAvailable = [NSNumber numberWithInteger:[val integerValue]];
            }
        
            // non-API values
            else if ( [key isEqualToString:@"displayable"] ) {
                self.displayable = @1;
            } else if ( [key isEqualToString:@"!displayable"] ) {
                self.displayable = @0;
            } else if ( [key isEqualToString:@"waitlistIsFull"] ) {
                self.waitlistIsFull = @1;
            } else if ( [key isEqualToString:@"!waitlistIsFull"] ) {
                self.waitlistIsFull = @0;
            
            } else if ( [key isEqualToString:@"isPast"] ) {
                self.isPast = @1;
            } else if ( [key isEqualToString:@"!isPast"] ) {
                self.isPast = @0;

            } else if ( [key isEqualToString:@"isSignedUp"] ) {
                self.isSignedUp = @1;
                self.isOnWaitlist = @0;
            
            } else if ( [key isEqualToString:@"!isSignedUp"] ) {
                self.isSignedUp = @0;

            } else if ( [key isEqualToString:@"isOnWaitlist"] ) {
                self.isOnWaitlist = @1;
                self.isSignedUp = @0;
            } else if ( [key isEqualToString:@"!isOnWaitlist"] ) {
                self.isOnWaitlist = @0;
            
            } else if ( [key isEqualToString:@"didAttend"] ) {
                self.didAttend = @1;
                self.isPast = @1;
            
            } else if ( [key isEqualToString:@"!didAttend"] ) {
                self.didAttend = @0;
            
            } else if ( [key isEqualToString:@"wasNoShow"] ) {
                self.wasNoShow = @1;
                self.isPast = @1;
            
            } else if ( [key isEqualToString:@"!wasNoShow"] ) {
                self.wasNoShow = @0;

            } else if ( [key isEqualToString:@"attendanceId"] ) {
                self.attendanceId = val;
            } else if ( [key isEqualToString:@"waitlistId"] ) {
                self.waitlistId = val;
            } else if ( [key isEqualToString:@"duration"] ) {
                self.duration = [NSNumber numberWithFloat:[val floatValue]];
            } else if ( [key isEqualToString:@"placesTotal"] ) {
                self.placesTotal = [NSNumber numberWithInt:[val intValue]];
            } else if ( [key isEqualToString:@"waitlistPlacesAvailable"] ) {
                self.waitlistPlacesAvailable = [NSNumber numberWithInt:[val intValue]];
            } else if ( [key isEqualToString:@"waitlistPlacesTotal"] ) {
                self.waitlistPlacesTotal = [NSNumber numberWithInt:[val intValue]];
            }
        }
    }
}


@end
