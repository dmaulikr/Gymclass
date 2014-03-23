//
//  WebFetchLayer.m
//  WebAbstractDemo
//
//  Created by Eric Colton on 4/23/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import "WebFetchLayer.h"

#define LIVE_WEB_RESULTS 1

static NSDictionary *resourcePathMap;

@implementation WebFetchLayer

+(void)initialize {

    resourcePathMap = @{ @"/test/index.html"  : @"webAbstractTest"
                        ,@"workout"           : @"workout"
                        ,@"/cgi-bin/test.cgi" : @"testcgi"
                       };
}

+(NSData *)sendSynchronousRequest:(NSURLRequest *)aURLRequest
                returningResponse:(NSURLResponse *__autoreleasing *)aURLResponse
                            error:(NSError *__autoreleasing *)aError
{
    if ( LIVE_WEB_RESULTS ) {

        return [NSURLConnection sendSynchronousRequest:aURLRequest returningResponse:aURLResponse error:aError];
        
    } else {
        
        NSString *filename = [resourcePathMap objectForKey:aURLRequest.URL.path];
        if ( filename ) {
            
            NSError *error;
            NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"txt"];
            NSString *contents = [NSString stringWithContentsOfFile:path
                                                           encoding:NSUTF8StringEncoding
                                                              error:&error
                                  ];

            return [contents dataUsingEncoding:NSUTF8StringEncoding];

        } else {
            
            return nil;
        }
    }
}

@end
