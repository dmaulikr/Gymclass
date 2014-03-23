//
//  CSWTime.m
//  Gymclass
//
//  Created by Eric Colton on 12/30/12.
//  Copyright (c) 2012 Cindy Software. All rights reserved.
//

#import "CSWTime.h"

static NSCalendar *gCal;

@interface CSWTime()
{
    NSUInteger _time;
    NSNumber *_number;
}

-(id)initWithDate:(NSDate *)aDate;
-(id)initWithNumber:(NSNumber *)aNumber;

@end

@implementation CSWTime

////
#pragma mark init methods
////
+(void)initialize
{
    gCal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
}

+(id)timeWithDate:(NSDate *)aDate
{
    return [[CSWTime alloc] initWithDate:aDate];
}

+(id)timeWithDisplayTime:(NSString *)aDisplayTime
{
    return [[CSWTime alloc] initWithDisplayTime:aDisplayTime];
}

+(id)timeWithNumber:(NSNumber *)aNumber
{
    return [[CSWTime alloc] initWithNumber:aNumber];
}

-(id)initWithDate:(NSDate *)aDate
{
    if ( self = [super init] ) {
        [self setWithDate:aDate];
    }
    return self;
}

-(id)initWithNumber:(NSNumber *)aNumber
{
    if ( self = [super init] ) {
        [self setWithNumber:aNumber];
    }
    return self;
}

-(id)initWithDisplayTime:(NSString *)aDisplayTime
{
    if ( self = [super init] ) {
        [self setWithDisplayTime:aDisplayTime];
    }
    return self;
}

////
#pragma mark accessor methods (public)
////
-(NSUInteger)asInt {
    return _time;
}

-(NSNumber *)asNumber {
    return _number;
}

-(void)setWithDate:(NSDate *)aDate
{
    NSDateComponents *c = [gCal components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:aDate];
    _time = ( c.hour % 24 ) * 100 + c.minute;
    _number = [NSNumber numberWithInteger:_time];
}

-(void)setWithNumber:(NSNumber *)aNumber
{
    _number = aNumber;
    _time = aNumber.integerValue;
}

-(NSDate *)toDate
{
    NSDateComponents *c = [[NSDateComponents alloc] init];
    
    c.hour = (int)(_time / 100);
    c.minute = _time % 100;

    return [gCal dateFromComponents:c];
}

-(void)setWithDisplayTime:(NSString *)aTimeStr
{
    static NSRegularExpression *timeRegEx;
    if ( !timeRegEx ) {
        timeRegEx = [[NSRegularExpression alloc] initWithPattern:@"^(\\d\\d?):(\\d\\d)\\s*([A|P])M"
                                                         options:0
                                                           error:NULL
                     ];
    }
    
    NSArray *matches = [timeRegEx matchesInString:aTimeStr
                                          options:0
                                            range:NSMakeRange(0, aTimeStr.length)
                        ];
    
    if ( matches.count != 1 )
        [NSException raise:kExceptionFormatError format:@"Could not recognize time string: %@, found %d matches", aTimeStr, matches.count];
    
    NSTextCheckingResult *match = matches.lastObject;
    int hours      = [aTimeStr substringWithRange:[match rangeAtIndex:1]].integerValue;
    int minutes    = [aTimeStr substringWithRange:[match rangeAtIndex:2]].integerValue;
    
    if ( hours < 12 && [[aTimeStr substringWithRange:[match rangeAtIndex:3]] isEqualToString:@"P"] )
        hours += 12;
    
    _time = hours * 100 + minutes;
    _number = [NSNumber numberWithInteger:_time];
}

-(NSString *)toDisplayTime
{
    int hours   = _time / 100;
    int minutes = _time % 100;
    
    char ampm;
    if ( hours == 12 ) {
        ampm = 'P';
    } else if ( hours > 12 ) {
        hours -= 12;
        ampm = 'P';
    } else {
        ampm = 'A';
    }
    
    return [NSString stringWithFormat:@"%d:%02d %cM", hours, minutes, ampm];
}

-(NSString *)toDisplayTime12Hour
{
    int hours   = _time / 100;
    int minutes = _time % 100;
    
    if ( hours > 12 ) {
        hours -= 12;
    }
    
    return [NSString stringWithFormat:@"%d:%02d", hours, minutes];
}

-(NSString *)toDisplayTimeAmPm
{
    int hours = _time / 100;
    
    char ampm;
    if ( hours >= 12 ) {
        ampm = 'P';
    } else {
        ampm = 'A';
    }
    
    return [NSString stringWithFormat:@"%cM", ampm];
}


@end
