//
//  CSWWeek.m
//  Gymclass
//
//  Created by Eric Colton on 1/26/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import "CSWWeek.h"
#import "CSWDay.h"
#import "CSWMembership.h"

@implementation CSWWeek

@dynamic gymId;
@dynamic startDay;
@dynamic lastRefreshed;

////
#pragma mark class methods (public)
////
+(CSWWeek *)weekWithStartDay:(CSWDay *)aDay gymId:(NSString *)aGymId moc:(NSManagedObjectContext *)aMoc
{
    NSFetchRequest *weekRequest = [[NSFetchRequest alloc] initWithEntityName:@"Week"];
    weekRequest.predicate = [NSPredicate predicateWithFormat:@"gymId = %@ AND startDay = %d", aGymId, aDay.asInt];
    
    NSError *error;
    CSWWeek *week = [aMoc executeFetchRequest:weekRequest error:&error].lastObject;
    
    if ( error )
        [NSException raise:kExceptionCoreDataError format:@"Could not load week for startDay: '%@'", [error localizedDescription]];
    
    if ( !week ) {
        week = [NSEntityDescription insertNewObjectForEntityForName:@"Week" inManagedObjectContext:aMoc];
        
        week.gymId = aGymId;
        week.startDay = [NSNumber numberWithInt:aDay.asInt];
        week.lastRefreshed = [NSDate dateWithTimeIntervalSince1970:0];
    }
    
    return week;
}

+(void)purgeAllWeeksForGymId:(NSString *)aGymId withMoc:(NSManagedObjectContext *)aMoc
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Week"];
    if ( aGymId ) {
        request.predicate = [NSPredicate predicateWithFormat:@"gymId = %@", aGymId];
    }
    
    NSError *err;
    NSArray *weeksToPurge = [aMoc executeFetchRequest:request error:&err];
    if ( err ) {
        [NSException raise:kExceptionCoreDataError format:@"Error fetching weeks for gymId '%@' to purge", aGymId];
    }
    
    for ( CSWWeek *week in weeksToPurge ) {
        [aMoc deleteObject:week];
    }
}

////
#pragma mark superclass instance methods (public)
////
-(NSString *)description
{
    return [NSString stringWithFormat:@"%d", self.startDay.intValue];
}

@end
