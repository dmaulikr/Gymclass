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
    NSUInteger _day;
    NSNumber *_number;
}

-(void)setFromDate:(NSDate *)aDate;
-(void)setFromNumber:(NSNumber *)aNumber;

@end

@implementation CSWDay

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

//
#pragma mark accessor methods (public)
//
-(NSUInteger)asInt
{
    return _day;
}

-(NSNumber *)asNumber
{
    return _number;
}

-(void)setFromDate:(NSDate *)aDate
{
    NSDateComponents *c = [gCal components: NSYearCalendarUnit
                                           |NSMonthCalendarUnit
                                           |NSDayCalendarUnit
                                  fromDate:aDate
                           ];

    _day = c.year * 10000 + c.month * 100 + c.day;
    _number = [NSNumber numberWithInteger:_day];
    
    
}

-(void)setFromNumber:(NSNumber *)aNumber;
{
    _day = [aNumber integerValue];
    _number = aNumber;
}

////
#pragma mark instance methods (public)
////
-(NSDate *)toDate
{
    NSDateComponents *c = [[NSDateComponents alloc] init];
    
    int dayClone = _day;
    c.year = (int)(dayClone / 10000);
    dayClone %= 10000;
    c.month = (int)(dayClone / 100);
    c.day = dayClone % 100;
        
    return [gCal dateFromComponents:c];
}

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
    
    NSString *day = [dayOfWeekFormatter stringFromDate:self.toDate];
    int days = [[daysToSubtract objectForKey:day] integerValue];
    NSTimeInterval daysBackInSeconds = days * 60 * 60 * 24 * -1;
    
    NSDate *sundayDate = [self.toDate dateByAddingTimeInterval:daysBackInSeconds];
    return [CSWDay dayWithDate:sundayDate];
}

-(CSWDay *)addDays:(NSInteger)aDays
{
    NSUInteger secs = [self.toDate timeIntervalSince1970] + ( 60 * 60 * 24 * aDays );
    return [CSWDay dayWithDate:[NSDate dateWithTimeIntervalSince1970:secs]];
}


-(NSInteger)daysBetween:(CSWDay *)aDay
{
    NSInteger aSecs = [self.toDate timeIntervalSince1970];
    NSInteger bSecs = [aDay.toDate timeIntervalSince1970];
    
    return (NSInteger)( ( bSecs - aSecs ) / ( 60 * 60 * 24 * 1.0 ) );
}


@end
