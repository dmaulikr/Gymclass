//
//  CSWIndicatorManager.h
//  Gymclass
//
//  Created by ERIC COLTON on 4/8/14.
//  Copyright (c) 2014 Cindy Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol CSWIndicatorManagerDelegate

@optional
-(void)didStart;
-(void)didStop;
@end

@interface CSWIndicatorManager : NSObject

+(instancetype)sharedManager;

@property (weak, nonatomic) id<CSWIndicatorManagerDelegate> delegate;

-(BOOL)increment;
-(BOOL)decrement;
-(BOOL)reset;
-(BOOL)getStatus;

@end
