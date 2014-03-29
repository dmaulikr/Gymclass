//
//  CSWInstructor.m
//  Gymclass
//
//  Created by Eric Colton on 1/14/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import "CSWAppDelegate.h"
#import "CSWInstructor.h"
#import "CSWMembership.h"

static NSDictionary *displayNamesMap = nil;
static NSSet *depricatedInstructorNames = nil;

static bool fetchAllNeedsRegen = true;
static NSArray *_cachedFetchAllResults = nil;
static NSString *_cachedFetchAllGymId = nil;

@implementation CSWInstructor

@dynamic gymId;
@dynamic instructorId;
@dynamic name;

//
#pragma mark class methods (public)
//
+(void)initialize
{
    if ( self == [CSWInstructor class] ) {
        displayNamesMap = @{};
    }
}

+(void)setDisplayNamesMap:(NSDictionary *)aDisplayNames
{
    displayNamesMap = [aDisplayNames copy];
}

+(void)depricateInstructorNames:(NSArray *)aInstructorNames
{
    if ( aInstructorNames ) {

        NSMutableSet *buildSet = [NSMutableSet new];
    
        for ( NSString *instructorName in aInstructorNames ) {
            [buildSet addObject:instructorName];
        }
    
        depricatedInstructorNames = [NSSet setWithSet:buildSet];

    } else {
        
        depricatedInstructorNames = nil;
    }
}

+(CSWInstructor *)declareInstructor:(NSDictionary *)aDict withMoc:(NSManagedObjectContext *)aMoc
{
    if ( [depricatedInstructorNames containsObject:aDict[@"name"]] ) return nil;

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Instructor"];
    request.predicate = [NSPredicate predicateWithFormat:@"gymId = %@ AND name = %@", aDict[@"gymId"], aDict[@"name"]];
    
    NSError *err;
    CSWInstructor *instructor = [[aMoc executeFetchRequest:request error:&err] lastObject];
    if ( err )
        [NSException raise:kExceptionCoreDataError
                    format:@"Error fetching location for name '%@' for gymId %@", aDict[@"name"], aDict[@"gymId"]
         ];
    
    if ( !instructor ) {
        
        instructor = [NSEntityDescription insertNewObjectForEntityForName:@"Instructor"
                                                   inManagedObjectContext:aMoc
                      ];
        
        instructor.gymId = aDict[@"gymId"];
        instructor.name = aDict[@"name"];
    }
    
    instructor.instructorId = aDict[@"instructorId"];
    fetchAllNeedsRegen = true;
    
    return instructor;
}

+(CSWInstructor *)instructorWithName:(NSString *)aName withMoc:(NSManagedObjectContext *)aMoc
{
    if ( [depricatedInstructorNames containsObject:aName] ) return nil;
    
    NSString *gymId = [CSWMembership sharedMembership].gymId;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Instructor"];
    request.predicate = [NSPredicate predicateWithFormat:@"gymId = %@ AND name = %@", gymId, aName];
    
    NSError *err;
    CSWInstructor *instructor = [[aMoc executeFetchRequest:request error:&err] lastObject];
    if ( err )
        [NSException raise:kExceptionCoreDataError
                    format:@"Error fetching instructor for name '%@' for gymId %@", aName, gymId
         ];
    
    return instructor;
}

+(NSArray *)fetchAllInstructorsWithMoc:(NSManagedObjectContext *)aMoc
{
    NSString *gymId = [CSWMembership sharedMembership].gymId;
    
    if ( !fetchAllNeedsRegen && [gymId isEqualToString:_cachedFetchAllGymId] ) {
        return _cachedFetchAllResults;
    }
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Instructor"];
    request.predicate = [NSPredicate predicateWithFormat:@"gymId = %@", gymId];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                              ascending:TRUE
                                 ]];

    NSError *error;
    NSArray *results = [aMoc executeFetchRequest:request error:&error];

    if ( error ) {
        [NSException raise:kExceptionCoreDataError
                    format:@"Error fetching all instructors for gymIm %@: %@", gymId, [error localizedDescription]
         ];
    }
    
    bool didDelete = false;
    
    NSMutableArray *filteredResults = [NSMutableArray new];
    if ( depricatedInstructorNames ) {
        for ( CSWInstructor *instructor in results ) {
            if ( [depricatedInstructorNames containsObject:instructor.name] ) {
                [aMoc deleteObject:instructor];
                didDelete = true;
            } else {
                [filteredResults addObject:instructor];
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

+(void)purgeAllInstructorsForGymId:(NSString *)aGymId withMoc:(NSManagedObjectContext *)aMoc;
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Instructor"];
    if ( aGymId ) {
        request.predicate = [NSPredicate predicateWithFormat:@"gymId = %@", aGymId];
    }
    
    NSError *err;
    NSArray *instructorsToPurge = [aMoc executeFetchRequest:request error:&err];
    if ( err ) {
        [NSException raise:kExceptionCoreDataError format:@"Error fetching instructors for gymId '%@' to purge", aGymId];
    }
    
    for ( CSWInstructor *instructor in instructorsToPurge ) {
        [aMoc deleteObject:instructor];
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

-(NSComparisonResult)compare:(CSWInstructor *)aInstructor
{
    return [self.name compare:aInstructor.name];
}

@end
