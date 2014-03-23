//
//  CSWColors.m
//  Gymclass
//
//  Created by ERIC COLTON on 9/21/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import "CSWColors.h"

static NSDictionary *colors = nil;

@implementation CSWColors

+(UIColor *)colorForPurpose:(NSString *)aPurpose
{
    if ( !colors ) {
        
        colors = @{
                    @"signedUp" : [UIColor colorWithRed:50.0/255.0
                                                  green:255/255.0
                                                   blue:50.0/255.0
                                                  alpha:1.0
                                   ]
                   ,@"waitlisted" : [UIColor orangeColor]
                   ,@"notSignedUp" : [UIColor clearColor]
                  };
    }
    
    return colors[aPurpose];
}

@end
