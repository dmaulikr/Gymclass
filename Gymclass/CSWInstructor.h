//
//  CSWInstructor.h
//  Gymclass
//
//  Created by Eric Colton on 1/14/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface CSWInstructor : NSManagedObject

+(void)setDisplayNamesMap:(NSDictionary *)aDisplayNames;
+(void)depricateInstructorNames:(NSArray *)aInstructorNames;

+(CSWInstructor *)declareInstructor:(NSDictionary *)aDict withMoc:(NSManagedObjectContext *)aMoc;
+(CSWInstructor *)instructorWithName:(NSString *)aName withMoc:(NSManagedObjectContext *)aMoc;

+(NSArray *)fetchAllInstructorsWithMoc:(NSManagedObjectContext *)aMoc;
+(void)purgeAllInstructorsForGymId:(NSString *)aGymId withMoc:(NSManagedObjectContext *)aMoc;

@property (nonatomic, strong) NSString *gymId;
@property (nonatomic, strong) NSString *instructorId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, readonly) NSString *displayName;

-(NSComparisonResult)compare:(CSWInstructor *)aInstructor;

@end
