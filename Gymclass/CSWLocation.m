//
//  CSWLocation.m
//  Gymclass
//
//  Created by Eric Colton on 1/1/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import "CSWAppDelegate.h"
#import "CSWLocation.h"
#import "CSWMembership.h"

static NSDictionary *displayNamesMap = nil;
static NSSet *depricatedLocationNames = nil;

static bool fetchAllNeedsRegen = true;
static NSArray *_cachedFetchAllResults = nil;
static NSString *_cachedFetchAllGymId = nil;

@implementation CSWLocation

@dynamic locationId;
@dynamic gymId;
@dynamic name;


//
#pragma mark class methods (public)
//
+(void)initialize
{
    if ( self == [CSWLocation class] ) {
        displayNamesMap = @{};
    }
}

+(void)setDisplayNamesMap:(NSDictionary *)aDisplayNames
{
    displayNamesMap = [aDisplayNames copy];
}

+(void)depricateLocationNames:(NSArray *)aLocationNames
{
    if ( aLocationNames ) {
        
        NSMutableSet *buildSet = [NSMutableSet new];
        for ( NSString *locationName in aLocationNames ) {
            [buildSet addObject:locationName];
        }
    
        depricatedLocationNames = [NSSet setWithSet:buildSet];

    } else {
        
        depricatedLocationNames = nil;
    }
}

+(CSWLocation *)declareLocation:(NSDictionary *)aDict withMoc:(NSManagedObjectContext *)aMoc
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Location"];
    request.predicate = [NSPredicate predicateWithFormat:@"gymId = %@ AND name = %@", aDict[@"gymId"], aDict[@"name"]];
    
    NSError *err;
    CSWLocation *location = [[aMoc executeFetchRequest:request error:&err] lastObject];
    if ( err )
        [NSException raise:kExceptionCoreDataError
                    format:@"Error fetching location for name '%@' for gymId %@", aDict[@"name"], aDict[@"gymId"]
         ];
    
    if ( !location ) {
        
        location = [NSEntityDescription insertNewObjectForEntityForName:@"Location"
                                                 inManagedObjectContext:aMoc
                    ];
        
        location.gymId = aDict[@"gymId"];
        location.name = aDict[@"name"];
    }
    
    location.locationId = aDict[@"locationId"];

    fetchAllNeedsRegen = true;
    
    return location;
}

+(CSWLocation *)locationWithName:(NSString *)aName withMoc:(NSManagedObjectContext *)aMoc
{
    NSString *gymId = [CSWMembership sharedMembership].gymId;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Location"];
    request.predicate = [NSPredicate predicateWithFormat:@"gymId = %@ AND name = %@", gymId, aName];
    
    NSError *err;
    CSWLocation *location = [[aMoc executeFetchRequest:request error:&err] lastObject];
    if ( err )
        [NSException raise:kExceptionCoreDataError
                    format:@"Error fetching location for name '%@' for gymId %@", aName, gymId
         ];
    
    return location;
}

+(NSArray *)fetchAllLocationsWithMoc:(NSManagedObjectContext *)aMoc
{
    NSString *gymId = [CSWMembership sharedMembership].gymId;
    
    if ( !fetchAllNeedsRegen && [gymId isEqualToString:_cachedFetchAllGymId] ) {
        return _cachedFetchAllResults;
    }
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Location"];
    request.predicate = [NSPredicate predicateWithFormat:@"gymId = %@", gymId];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                              ascending:TRUE
                                 ]];
    
    NSError *error;
    NSArray *results = [aMoc executeFetchRequest:request error:&error];
    
    if ( error ) {
        [NSException raise:kExceptionCoreDataError
                    format:@"Error fetching all locations for gymIm %@: %@", gymId, [error localizedDescription]
         ];
    }
    
    bool didDelete = false;
    
    NSMutableArray *filteredResults = [NSMutableArray new];
    if ( depricatedLocationNames ) {
        for ( CSWLocation *location in results ) {
            if ( [depricatedLocationNames containsObject:location.name] ) {
                [aMoc deleteObject:location];
                didDelete = true;
            } else {
                [filteredResults addObject:location];
            }
        }
        
        if ( didDelete ) [aMoc save:nil];
        
        results = [NSArray arrayWithArray:filteredResults];
    }
    
    @synchronized ( self ) {
        _cachedFetchAllGymId = gymId;
        _cachedFetchAllResults = results;
        fetchAllNeedsRegen = false;
    }
    
    return results;
}

+(void)purgeAllLocationsForGymId:(NSString *)aGymId withMoc:(NSManagedObjectContext *)aMoc;
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Location"];
    if ( aGymId ) {
        request.predicate = [NSPredicate predicateWithFormat:@"gymId = %@", aGymId];
    }
    
    NSError *err;
    NSArray *locationsToPurge = [aMoc executeFetchRequest:request error:&err];
    if ( err ) {
        [NSException raise:kExceptionCoreDataError format:@"Error fetching locations for gymId '%@' to purge", aGymId];
    }
    
    for ( CSWLocation *location in locationsToPurge ) {
        [aMoc deleteObject:location];
    }
}

//
#pragma mark accessor methods (public)
//
-(NSString *)displayName
{
    if ( displayNamesMap ) {
        NSString *displayName = displayNamesMap[self.name];
        return ( displayName ) ? displayName : self.name;
    }
    
    return self.name;
}


@end
