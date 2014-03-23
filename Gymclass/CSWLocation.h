//
//  CSWLocation.h
//  Gymclass
//
//  Created by Eric Colton on 1/1/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface CSWLocation : NSManagedObject

+(void)setDisplayNamesMap:(NSDictionary *)aDisplayNames;
+(void)depricateLocationNames:(NSArray *)aLocationNames;

+(CSWLocation *)declareLocation:(NSDictionary *)aDict withMoc:(NSManagedObjectContext *)aMoc;
+(CSWLocation *)locationWithName:(NSString *)aNamewith withMoc:(NSManagedObjectContext *)aMoc;

+(NSArray *)fetchAllLocationsWithMoc:(NSManagedObjectContext *)aMoc;

+(void)purgeAllLocationsForGymId:(NSString *)aGymId withMoc:(NSManagedObjectContext *)aMoc;

@property (nonatomic, strong) NSString *locationId;
@property (nonatomic, strong) NSString *gymId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, readonly) NSString *displayName;

@end
