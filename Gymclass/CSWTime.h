//
//  CSWTime.h
//  Gymclass
//
//  Created by Eric Colton on 12/30/12.
//  Copyright (c) 2012 Cindy Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kExceptionFormatError @"FORMAT ERROR"

@interface CSWTime : NSObject

+(CSWTime *)timeWithDate:(NSDate *)aDate;
+(CSWTime *)timeWithNumber:(NSNumber *)aNumber;

+(CSWTime *)timeWithDisplayTime:(NSString *)aDisplayTime;

-(id)initWithDate:(NSDate *)aDate;

-(void)setWithDate:(NSDate *)aDate;
-(NSDate *)toDate;

-(void)setWithDisplayTime:(NSString *)aTimeStr;

-(NSString *)toDisplayTime;
-(NSString *)toDisplayTime12Hour;
-(NSString *)toDisplayTimeAmPm;


@property (nonatomic, readonly) NSUInteger asInt;
@property (nonatomic, readonly) NSNumber *asNumber;


@end
