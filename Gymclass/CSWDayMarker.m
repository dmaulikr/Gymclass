//
//  CSWDayMarker.m
//  Gymclass
//
//  Created by ERIC COLTON on 9/14/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import "CSWDayMarker.h"
#import "CSWDay.h"
#import "CSWMembership.h"

@implementation CSWDayMarker

@dynamic gymId;
@dynamic day;
@dynamic lastRefreshed;

////
#pragma mark class methods (public)
////
+(CSWDayMarker *)dayMarkerWithDay:(CSWDay *)aDay withMoc:(NSManagedObjectContext *)aMoc
{
    NSString *gymId = [CSWMembership sharedMembership].gymId;
    
    NSFetchRequest *dayMarkerRequest = [[NSFetchRequest alloc] initWithEntityName:@"DayMarker"];
    dayMarkerRequest.predicate = [NSPredicate predicateWithFormat:@"gymId = %@ AND day = %d", gymId, aDay.asInt];
    
    NSError *error;
    CSWDayMarker *dayMarker = [aMoc executeFetchRequest:dayMarkerRequest error:&error].lastObject;
    
    if ( error )
        [NSException raise:kExceptionCoreDataError
                    format:@"Could not fetch DayMarker for day: '%@'", [error localizedDescription]
         ];
    
    if ( !dayMarker ) {
        dayMarker = [NSEntityDescription insertNewObjectForEntityForName:@"DayMarker" inManagedObjectContext:aMoc];
        
        dayMarker.gymId = gymId;
        dayMarker.day = [NSNumber numberWithInt:aDay.asInt];
        dayMarker.lastRefreshed = [NSDate dateWithTimeIntervalSince1970:0];
    }
    
    return dayMarker;
}

+(void)purgeAllDayMarkersWithMoc:(NSManagedObjectContext *)aMoc;
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"DayMarker"];
    
    NSError *err;
    NSArray *dayMarkersToPurge = [aMoc executeFetchRequest:request error:&err];
    if ( err ) {
        [NSException raise:kExceptionCoreDataError format:@"Error fetching day markers to purge"];
    }
    
    for ( CSWDayMarker *dayMarker in dayMarkersToPurge ) {
        [aMoc deleteObject:dayMarker];
    }
}

////
#pragma mark superclass instance methods (public)
////
-(NSString *)description
{
    return [NSString stringWithFormat:@"%d", self.day.intValue];
}

@end
