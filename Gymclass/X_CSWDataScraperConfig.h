//
//  CSWDataScraperConfig.h
//  Gymclass
//
//  Created by Eric Colton on 2/9/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kExceptionDataScraperConfigIllegalOp @"DATA SCRAPER CONFIG ILLEGAL OP ERROR"
#define kExceptionDataScraperConfigValidate  @"DATA SCRAPER CONFIG VALIDATION ERROR"
#define kExceptionDataScraperConfigBundle    @"DATA SCRAPER CONFIG BUNDLE ERROR"

@interface CSWDataScraperConfig : NSObject

@property (nonatomic, strong) NSDictionary *configStruct;
@property (nonatomic, strong) NSURL *url;

-(id)initWithStruct:(NSDictionary *)aStruct;
-(id)initWithBundledPlist:(NSString *)aPlistName;
-(id)initWithURL:(NSURL *)aUrl;

-(NSDictionary *)fetchConfigForOperation:(NSString *)aOperation forSourceTag:(NSString *)aSourceTag;
-(NSDictionary *)fetchConfigForOperation:(NSString *)aOperation forOutputTag:(NSString *)aOutputTag;

//
// WARNING: refreshFromWeb performs synchronous http request.  Do not run on main thread.
//
-(void)refreshFromWeb:(NSError **)aError;

@end
