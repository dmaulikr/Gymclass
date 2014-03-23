//
//  CSWDataScraper.h
//  Gymclass
//
//  Created by Eric Colton on 12/5/12.
//  Copyright (c) 2012 Cindy Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSWDataScraperConfig.h"

#define kExceptionDataScraperSetup @"DATA SCRAPER CONFIG ERROR"
#define kExceptionDataScraperRuntime @"DATA SCRAPER RUNTIME ERROR"

@interface CSWDataScraper : NSObject

/* initialize with configuration */
-(id)initWithConfig:(CSWDataScraperConfig *)aConfig;
-(id)initWithConfigs:(NSArray *)aConfigs;

-(BOOL)isOperationAvailable:(NSString *)aOperation
               forSourceTag:(NSString *)aSourceTag;

-(BOOL)isOperationAvailable:(NSString *)aOperation
               forOutputTag:(NSString *)aOutputTag;

/* Build a URL string from configuartion */
-(NSURLRequest *)buildUrlRequestForOperation:(NSString *)aOperation
                                forSourceTag:(NSString *)aSourceTag
                            withUrlVariables:(NSDictionary *)aUrlVariables
                           withPostVariables:(NSDictionary *)aPostVariables;

/* Parse results from configuration */
-(id)parseDataString:(NSString *)aDataString
        forOperation:(NSString *)aOperation
        forOutputTag:(NSString *)aOutputTag;

-(void)setUrlHardPrefix:(NSString *)aPrefix;

@end
