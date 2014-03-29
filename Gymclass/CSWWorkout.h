//
//  CSWWorkout.h
//  Gymclass
//
//  Created by Eric Colton on 11/25/12.
//  Copyright (c) 2012 Cindy Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSWLocation.h"
#import "CSWInstructor.h"
#import "CSWDay.h"

@interface CSWWorkout : NSManagedObject

+(void)setDisplayTypesMap:(NSDictionary *)aDisplayTypes;
+(void)setPreMapDisplayTypesRegEx:(NSString *)aRegExString;

+(CSWWorkout *)workoutWithDict:(NSDictionary *)aDict gymId:(NSString *)aGymId withMoc:(NSManagedObjectContext *)aMoc;
+(CSWWorkout *)workoutWithId:(NSString *)aWorkoutId gymId:(NSString *)aGymId withMoc:(NSManagedObjectContext *)aMoc wasCreated:(BOOL *)wasCreated;
+(void)purgeWorkoutsNotInSet:(NSSet *)aSet ForDay:(int)aDayAsInt forGymId:(NSString *)aGymId withMoc:(NSManagedObjectContext *)aMoc;
+(void)purgeAllWorkoutsForGymId:(NSString *)aGymId withMoc:(NSManagedObjectContext *)aMoc;
-(void)populateWithDict:(NSDictionary *)aDict withMoc:(NSManagedObjectContext *)aMoc;


@property (strong) NSString *workoutId;
@property (strong) NSString *gymId;
@property (strong) CSWLocation *location;
@property (strong) CSWInstructor *instructor;
@property (strong) NSString *attendanceId;
@property (strong) NSString *waitlistId;
@property (strong) NSNumber *day;
@property (strong) NSNumber *time;
@property (strong) NSNumber *duration;
@property (strong) NSNumber *placesAvailable;
@property (strong) NSNumber *placesTotal;
@property (strong) NSNumber *waitlistPlacesAvailable;
@property (strong) NSNumber *waitlistPlacesTotal;
@property (strong) NSString *type;
@property (readonly) NSString *displayType;
@property (strong) NSNumber *isSignedUp;
@property (strong) NSNumber *isOnWaitlist;
@property (strong) NSNumber *isFull;
@property (strong) NSString *isUpdatingToPurpose;
@property (strong) NSNumber *waitlistIsFull;
@property (strong) NSNumber *isPast;
@property (strong) NSNumber *wasNoShow;
@property (strong) NSNumber *didAttend;
@property (strong) NSDate *lastRefreshed;
@property (strong) NSNumber *displayable;
@property (strong) NSNumber *deleted;  // not currently used


@end
