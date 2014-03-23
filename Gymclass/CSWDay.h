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

-(id)initWithNumber:(NSNumber *)aNumber;
-(CSWDay *)findPreviousSunday;
-(CSWDay *)addDays:(int)aDays;

-(int)daysBetween:(CSWDay *)aDay;

@property (nonatomic, readonly) int asInt;
@property (nonatomic, readonly) NSNumber *asNumber;
@property (nonatomic, readonly) NSString *dayOfWeek;
@property (nonatomic, readonly) NSDate *date;

+(CSWDay *)day;
+(CSWDay *)dayWithDate:(NSDate *)aDate;
+(CSWDay *)dayWithNumber:(NSNumber *)aNumber;
+(int)numberOfDaysForward:(CSWDay *)aDay;

@end
