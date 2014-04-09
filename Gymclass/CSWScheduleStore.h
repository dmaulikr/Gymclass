//
//  CSWScheduleStore.h
//  Gymclass
//
//  Created by Eric Colton on 11/25/12.
//  Copyright (c) 2012 Cindy Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSWWorkout.h"
#import "CSWMembership.h"
#import "CSWDay.h"


//#define kExceptionFetchConfiguration  @"FETCH CONFIGURATION EXCEPTION"
#define kExceptionStore             @"STORE EXCEPTION"
#define kExceptionNotLoggedIn       @"NOT LOGGED IN EXCEPTION"

//NSError domains
#define kErrorDomainLogin           @"LOGIN ERROR"
#define kErrorDomainSignup          @"MODIFY SIGNUP ERROR"

//
//NSError domain codes
//
#define kErrorCodeCouldNotGetToken           101
#define kErrorCodeInvalidCredentials         102
#define kErrorCodeUnexpectedServicerResponse 103
#define kErrorCodeCannotUndo                 104
#define kErrorCodeWaitlistIsFull             105

// kErrorDomainLogin error codes
#define kErrorCodeCouldNotLogin              201
#define kErrorCodeNotLoggedIn                202

typedef NS_ENUM( NSUInteger, WorkoutQueryType ) {
     WorkoutQueryTypeNone
    ,WorkoutQueryTypeSignup
    ,WorkoutQueryTypeCancelSignup
    ,WorkoutQueryTypeWaitlist
    ,WorkoutQueryTypeCancelWaitlist
};

@interface CSWScheduleStore : NSObject

+(CSWScheduleStore *)sharedStore;

@property (nonatomic, readonly) NSString *gymId;
@property (nonatomic, readonly) bool isLoggedIn;
@property (nonatomic, readonly) NSManagedObjectContext *backgroundThreadMoc;
@property (nonatomic, readonly) NSTimeZone *timeZone;
@property (nonatomic) u_int32_t currentSessionId;

// WARNING: fetchConfigForAllGyms and setupForGymId:error: make sychronous web requests, call in background thread only
-(bool)fetchConfigForAllGymsWithCompletion:(void(^)(bool, NSDictionary *, NSError *))aCompletionBlock;

-(BOOL)setupForGymId:(NSString *)aGymId error:(NSError *__autoreleasing *)aError;

-(void)unloadAllConfigurations;

//these must be called with a gymId set
-(bool)loadScheduleForDay:(CSWDay *)aDay
   weekScheduleCompletion:(void(^)(bool, NSError *))weekScheduleBlock
   reservationsCompletion:(void(^)(NSError *))reservationsBlock
   daySpotsLeftCompletion:(void(^)(NSError *))daySpotsLeftBlock
        wodDescCompletion:(void(^)(NSError *))wodDescBlock;

-(void)queryWorkout:(CSWWorkout *)aWorkout
      withQueryType:(WorkoutQueryType)aQueryType
      withMetaData:(NSDictionary *)aMetaData
     withCompletion:(void(^)(NSError *))aBlock;


-(id)fetchGymConfigValue:(NSString *)aPurpose;
-(id)fetchGymConfigValue:(NSString *)aPurpose forKey:(NSString *)aKey;
-(id)fetchGymConfigValue:(NSString *)aPurpose forKey:(NSString *)aKey forGymId:(NSString *)aGymId;

// These 3 functions below should all be privatized
+(void)logCookies;
+(void)resetCookies;
-(void)loginUserForcefully:(BOOL)aForcefully withCompletion:(void(^)(NSError *))aBlock;
-(void)logout;
-(void)resetState;


@end
