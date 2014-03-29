//
//  CSWWod.m
//  Gymclass
//
//  Created by Eric Colton on 1/31/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import "CSWWod.h"
#import "CSWMembership.h"

@implementation CSWWod

@dynamic day;
@dynamic gymId;
@dynamic wodDesc;
@dynamic wodDescFormat;
@dynamic lastRefreshed;

////
#pragma mark superclass methods (public)
////
-(NSString *)description
{
    return [NSString stringWithFormat:@"%@:%@", self.gymId, self.day];
}

////
#pragma mark class methods (public)
////
+(CSWWod *)wodWithDay:(CSWDay *)aDay gymId:(NSString *)aGymId withMoc:(NSManagedObjectContext *)aMoc
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Wod"];
    
    request.predicate = [NSPredicate predicateWithFormat:@"gymId = %@ AND day = %d", aGymId, aDay.asInt];
    
    NSError *err;
    CSWWod *wod = [[aMoc executeFetchRequest:request error:&err] lastObject];
    if ( err )
        [NSException raise:kExceptionCoreDataError format:@"Error fetching wod for day='%d' for gymId='%@'", aDay.asInt, aGymId];
    
    if ( !wod ) {
        wod = [NSEntityDescription insertNewObjectForEntityForName:@"Wod"
                                            inManagedObjectContext:aMoc
               ];
        wod.gymId = aGymId;
        wod.day = [NSNumber numberWithInt:aDay.asInt];
        wod.lastRefreshed = [NSDate dateWithTimeIntervalSince1970:0];
    }
    
    return wod;
}

-(void)populateWithDict:(NSDictionary *)aDict withMoc:(NSManagedObjectContext *)aMoc
{
    @synchronized( self ) {
        
        for ( NSString *key in aDict.allKeys ) {
            
            NSString *val = aDict[key];
            if ( ![val isKindOfClass:[NSString class]] || [val isEqualToString:@""] )
                continue;
            
            if ( [key isEqualToString:@"wodDesc"] ) {
                self.wodDesc = val;
            }
        }
    }
}

+(void)purgeAllWodsForGymId:(NSString *)aGymId withMoc:(NSManagedObjectContext *)aMoc
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Wod"];
    if ( aGymId ) {
        request.predicate = [NSPredicate predicateWithFormat:@"gymId = %@", aGymId];
    }
    
    NSError *err;
    NSArray *wodsToPurge = [aMoc executeFetchRequest:request error:&err];
    if ( err ) {
        [NSException raise:kExceptionCoreDataError format:@"Error fetching wods for gymId '%@' to purge", aGymId];
    }
    
    for ( CSWWod *wod in wodsToPurge ) {
        [aMoc deleteObject:wod];
    }
}

@end
