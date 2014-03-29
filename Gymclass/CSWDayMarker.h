//
//  CSWDayMarker.h
//  Gymclass
//
//  Created by ERIC COLTON on 9/14/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSWDay.h"

@interface CSWDayMarker : NSManagedObject

@property (nonatomic, strong) NSString *gymId;
@property (nonatomic, strong) NSNumber *day;
@property (nonatomic, strong) NSDate *lastRefreshed;

+(CSWDayMarker *)dayMarkerWithDay:(CSWDay *)aDay gymId:(NSString *)aGymId withMoc:(NSManagedObjectContext *)aMoc;
+(void)purgeAllDayMarkersWithMoc:(NSManagedObjectContext *)aMoc;

@end
