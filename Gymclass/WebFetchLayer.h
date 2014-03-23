//
//  WebFetchLayer.h
//  WebAbstractDemo
//
//  Created by Eric Colton on 4/23/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WebFetchLayer : NSObject

+(NSData *)sendSynchronousRequest:(NSURLRequest *)aURLRequest
                returningResponse:(NSURLResponse *__autoreleasing *)aURLResponse
                            error:(NSError *__autoreleasing *)aError;

@end
