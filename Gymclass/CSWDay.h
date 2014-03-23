//
//  CSWDay.h
//  Gymclass
//
//  Created by Eric Colton on 12/30/12.
//  Copyright (c) 2012 Cindy Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSWDay : NSObject

-(id)initWithDate:(NSDate *)aDate;
-(NSDate *)toDate;

-(id)initWithNumber:(NSNumber *)aNumber;
-(CSWDay *)findPreviousSunday;
-(CSWDay *)addDays:(NSInteger)aDays;

-(NSInteger)daysBetween:(CSWDay *)aDay;

@property (nonatomic, readonly) NSUInteger asInt;
@property (nonatomic, readonly) NSNumber *asNumber;

+(CSWDay *)day;
+(CSWDay *)dayWithDate:(NSDate *)aDate;
+(CSWDay *)dayWithNumber:(NSNumber *)aNumber;


@end
