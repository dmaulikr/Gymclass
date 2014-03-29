//
//  CSWWod.h
//  Gymclass
//
//  Created by Eric Colton on 1/31/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "CSWDay.h"

@interface CSWWod : NSManagedObject

+(CSWWod *)wodWithDay:(CSWDay *)aDay gymId:(NSString *)aGymId withMoc:(NSManagedObjectContext *)aMoc;
+(void)purgeAllWodsForGymId:(NSString *)aGymId withMoc:(NSManagedObjectContext *)aMoc;
-(void)populateWithDict:(NSDictionary *)aDict withMoc:(NSManagedObjectContext *)aMoc;

@property (strong) NSNumber *day;
@property (strong) NSString *gymId;
@property (strong) NSString *wodDesc;
@property (strong) NSString *wodDescFormat;
@property (strong) NSDate *lastRefreshed;

@end
