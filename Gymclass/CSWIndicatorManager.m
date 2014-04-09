//
//  CCSWIndicatorManager.m
//  Gymclass
//
//  Created by ERIC COLTON on 4/8/14.
//  Copyright (c) 2014 Cindy Software. All rights reserved.
//

#import "CSWIndicatorManager.h"

static CSWIndicatorManager *sharedInstance;

@interface CSWIndicatorManager()
{
    int _count;
}

@end

@implementation CSWIndicatorManager

+(void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = nil;
    });
}

+(instancetype)sharedManager
{
    @synchronized(self) {
        
        if ( !sharedInstance ) {
            sharedInstance = [CSWIndicatorManager new];
        }
        
        return sharedInstance;
    }
}

-(instancetype)init
{
    self = [super init];
    if ( self ) {
        _count = 0;
    }
    return self;
}

-(BOOL)increment
{
    @synchronized( self ) {
        
        NSLog(@"UP\t%d", _count + 1 );
        
        if ( _count++ ) {
            
            return NO;
            
        } else {
            
            if ( self.delegate ) [self.delegate didStart];
            return YES;
        }
    }
}

-(BOOL)decrement
{
    @synchronized( self ) {
        
        NSLog(@"DOWN\t%d", _count - 1 );
        
        if ( _count <= 0 ) {
            
            _count = 0;
            
        } else if ( _count == 1 ) {
            
            _count = 0;
            if ( self.delegate ) [self.delegate didStop];
            return YES;
            
        } else {
            
            _count--;
        }
        
        return NO;
    }
}

-(BOOL)reset
{
    @synchronized( self ) {
        if ( _count > 0 ) {
            _count = 0;
            if ( self.delegate ) [self.delegate didStop];
            return YES;
        } else {
            _count = 0;
            return NO;
        }

    }
}

-(BOOL)getStatus
{
    @synchronized( self ) {
        if ( _count > 0 ) {
            if ( self.delegate ) [self.delegate didStart];
            return YES;
        } else {
            if ( self.delegate ) [self.delegate didStop];
            return NO;
        }
    }
}

@end

