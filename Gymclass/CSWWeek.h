//
//  CSWWeek.h
//  Gymclass
//
//  Created by Eric Colton on 1/26/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSWDay.h"

@interface CSWWeek : NSManagedObject

@property (nonatomic, strong) NSString *gymId;
@property (nonatomic, strong) NSNumber *startDay;
@property (nonatomic, strong) NSDate *lastRefreshed;

+(CSWWeek *)weekWithStartDay:(CSWDay *)aDay gymId:(NSString *)aGymId moc:(NSManagedObjectContext *)aMoc;
+(void)purgeAllWeeksForGymId:(NSString *)aGymId withMoc:(NSManagedObjectContext *)aMoc;

@end
