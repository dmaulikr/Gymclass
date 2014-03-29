//
//  CSWDay.m
//  Gymclass
//
//  Created by Eric Colton on 12/30/12.
//  Copyright (c) 2012 Cindy Software. All rights reserved.
//

#import "CSWDay.h"

static NSCalendar *gCal;
static NSLocale *gLocale;

@interface CSWDay()
{
    int _day;
    NSNumber *_number;
}

-(void)setFromDate:(NSDate *)aDate;
-(void)setFromNumber:(NSNumber *)aNumber;

@end

@implementation CSWDay

@synthesize dayOfWeek = _dayOfWeek, date = _date;

////
#pragma mark class methods
////
+(void)initialize
{
    gCal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    gLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
}

//
#pragma mark init methods
//
+(id)day
{
    return [CSWDay new];
}

+(id)dayWithDate:(NSDate *)aDate
{
    return [[CSWDay alloc] initWithDate:aDate];
}

+(id)dayWithNumber:(NSNumber *)aNumber
{
    return [[CSWDay alloc] initWithNumber:aNumber];
}

-(id)init
{
    self = [super init];
    if ( self ) {
        [self setFromDate:[NSDate date]];
    }
    
    return self;
}

-(id)initWithDate:(NSDate *)aDate
{
    if ( self = [super init] ) {
        [self setFromDate:aDate];
    }
    return self;
}

-(id)initWithNumber:(NSNumber *)aNumber
{
    if ( self = [super init] ) {
        [self setFromNumber:aNumber];
    }
    return self;
}

////
#pragma mark superclass methods (public)
////
+(int)numberOfDaysForward:(CSWDay *)aDay
{
    return (int)([[NSDate date] timeIntervalSinceDate:aDay.date] / ( 60 * 60 * 24 * 1.0 ));
}

//
#pragma mark accessor methods (public)
//
-(int)asInt
{
    return _day;
}

-(NSNumber *)asNumber
{
    return _number;
}

-(NSDate *)date
{
    return _date;
}

-(NSString *)dayOfWeek
{
    return _dayOfWeek;
}

-(void)setFromDate:(NSDate *)aDate
{
    NSDateComponents *c = [gCal components: NSYearCalendarUnit
                                           |NSMonthCalendarUnit
                                           |NSDayCalendarUnit
                                           |NSWeekdayCalendarUnit
                                  fromDate:aDate
                           ];

    _date = aDate;
    _day = (int)c.year * 10000 + (int)c.month * 100 + (int)c.day;
    _number = [NSNumber numberWithInteger:_day];
    
    switch ( c.weekday ) {
        case (1) :
            _dayOfWeek = @"sunday";
            break;
        case (2) :
            _dayOfWeek = @"monday";
            break;
        case (3) :
            _dayOfWeek = @"tuesday";
            break;
        case (4) :
            _dayOfWeek = @"wednesday";
            break;
        case (5) :
            _dayOfWeek = @"thursday";
            break;
        case (6) :
            _dayOfWeek = @"friday";
            break;
        case (7) :
            _dayOfWeek = @"saturday";
            break;
    }
}

-(void)setFromNumber:(NSNumber *)aNumber;
{
//    _day = [aNumber intValue];
//    _number = aNumber;
    
    NSDateComponents *c = [[NSDateComponents alloc] init];
    
    int dayClone = _day;
    c.year = (int)(dayClone / 10000);
    dayClone %= 10000;
    c.month = (int)(dayClone / 100);
    c.day = dayClone % 100;
    NSDate *date = [gCal dateFromComponents:c];
    return [self setFromDate:date];
}

////
#pragma mark instance methods (public)
////
-(CSWDay *)findPreviousSunday
{
    static NSDateFormatter *dayOfWeekFormatter = nil;
    static NSDictionary *daysToSubtract;
    
    if ( !dayOfWeekFormatter ) {
        dayOfWeekFormatter = [[NSDateFormatter alloc] init];
        dayOfWeekFormatter.locale = gLocale;
        dayOfWeekFormatter.dateFormat = @"EEEE";
        
        daysToSubtract = @{ @"Sunday"    : @0
                           ,@"Monday"    : @1
                           ,@"Tuesday"   : @2
                           ,@"Wednesday" : @3
                           ,@"Thursday"  : @4
                           ,@"Friday"    : @5
                           ,@"Saturday"  : @6
                          };
    }
    
    NSString *day = [dayOfWeekFormatter stringFromDate:self.date];
    int days = [[daysToSubtract objectForKey:day] intValue];
    NSTimeInterval daysBackInSeconds = days * 60 * 60 * 24 * -1;
    
    NSDate *sundayDate = [self.date dateByAddingTimeInterval:daysBackInSeconds];
    return [CSWDay dayWithDate:sundayDate];
}

-(CSWDay *)addDays:(int)aDays
{
    NSUInteger secs = [self.date timeIntervalSince1970] + ( 60 * 60 * 24 * aDays );
    return [CSWDay dayWithDate:[NSDate dateWithTimeIntervalSince1970:secs]];
}


-(int)daysBetween:(CSWDay *)aDay
{
    NSInteger aSecs = [self.date timeIntervalSince1970];
    NSInteger bSecs = [aDay.date timeIntervalSince1970];
    
    return (int)( ( bSecs - aSecs ) / ( 60 * 60 * 24 * 1.0 ) );
}



@end
