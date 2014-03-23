//
//  CSWDataScraper.m
//  Gymclass
//
//  Created by Eric Colton on 12/5/12.
//  Copyright (c) 2012 Cindy Software. All rights reserved.
//

#import "CSWDataScraper.h"

@interface CSWDataScraper()

-(NSDictionary *)fetchOperation:(NSString *)aOperation
                   forSourceTag:(NSString *)aSourceTag;

-(NSString *)buildVariableStr:(id)aVarRaw withInputVariables:(NSDictionary *)aInputVars withPathDesc:(NSString *)aPathDesc;

-(NSDictionary *)fetchOperation:(NSString *)aOperation
                   forOutputTag:(NSString *)aOutputTag;

-(NSDictionary *)parseDataString:(NSString *)aDataString
               forGroupByPattern:(NSString *)aGroupByPattern
                  forParseConfig:(NSDictionary *)aParseConfig;

-(id)parseDataString:(NSString *)aDataString
     forOutputConfig:(NSDictionary *)aOutputConfig;

-(id)parseDataStringForSingleCycle:(NSString *)aDataString
                   forOutputConfig:(NSDictionary *)aParseConfig;

-(NSDictionary *)buildDictionaryForMatch:(NSTextCheckingResult *)aMatch
                          withDataString:(NSString *)aDataString
                      withCapturesConfig:(NSDictionary *)aCapturesConfig
                           startWithDict:(NSDictionary *)aDict;

@property (nonatomic, readonly) NSArray *configs;
@property (nonatomic, readonly) NSString *urlHardPrefix;

@end

@implementation CSWDataScraper

@synthesize urlHardPrefix = _urlHardPrefix, configs = _configs;

////
#pragma mark init methods
////
-(id)initWithConfig:(CSWDataScraperConfig *)aConfig
{
    return [self initWithConfigs:@[aConfig]];
}

-(id)initWithConfigs:(NSArray *)aConfigs
{
    if ( aConfigs.count < 1 )
        [NSException raise:kExceptionDataScraperSetup
                    format:@"Data scraper must be initialized with at least one configuration"
         ];
    
    self = [super init];
    if ( self ) {
        _configs = aConfigs;
    }
    
    return self;
}

////
#pragma mark instance methods (public)
////
-(BOOL)isOperationAvailable:(NSString *)aOperation
               forOutputTag:(NSString *)aOutputTag
{
    return !![self fetchOperation:aOperation forOutputTag:aOutputTag];
}

-(BOOL)isOperationAvailable:(NSString *)aOperation
               forSourceTag:(NSString *)aSourceTag
{
    return !![self fetchOperation:aOperation forOutputTag:aSourceTag];
}

-(NSURLRequest *)buildUrlRequestForOperation:(NSString *)aOperation
                                forSourceTag:(NSString *)aSourceTag
                            withUrlVariables:(NSDictionary *)aUrlVariables
                           withPostVariables:(NSDictionary *)aPostVariables
{
    NSString *pathDesc = [NSString stringWithFormat:@"output sourceTag '%@' for operation '%@'", aSourceTag, aOperation];
    
    NSDictionary *sourceConfig = [self fetchOperation:aOperation forSourceTag:aSourceTag];
    if ( !sourceConfig )
        [NSException raise:kExceptionDataScraperRuntime
                    format:@"No configuration found for %@", pathDesc
         ];

    NSDictionary *urlConfig = [sourceConfig objectForKey:@"url"];
    NSString *urlFormatStr = [urlConfig objectForKey:@"format"];
    NSArray *urlInterpolations = [urlConfig objectForKey:@"variables"];
    
    NSMutableArray *urlInterpolationValues = [[NSMutableArray alloc] initWithCapacity:10];
    
    for ( int i = 0; i < urlInterpolations.count; i++ ) {
        id interpolationRaw = [urlInterpolations objectAtIndex:i];
        NSString *entryPathDesc = [NSString stringWithFormat:@"url variable %d in %@", i, pathDesc];
        [urlInterpolationValues addObject:[self buildVariableStr:interpolationRaw
                                              withInputVariables:aUrlVariables
                                                    withPathDesc:entryPathDesc
                                           ]
         ];
    }

    while ( urlInterpolationValues.count < 10 ) {
        [urlInterpolationValues addObject:[NSString string]];
    }
    
    NSString *fullUrlFormatStr = self.urlHardPrefix
                                 ? [NSString stringWithFormat:@"%@/%@", self.urlHardPrefix, urlFormatStr]
                                 : urlFormatStr;

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:fullUrlFormatStr,[urlInterpolationValues objectAtIndex:0]
                                                                                 ,[urlInterpolationValues objectAtIndex:1]
                                                                                 ,[urlInterpolationValues objectAtIndex:2]
                                                                                 ,[urlInterpolationValues objectAtIndex:3]
                                                                                 ,[urlInterpolationValues objectAtIndex:4]
                                                                                 ,[urlInterpolationValues objectAtIndex:5]
                                                                                 ,[urlInterpolationValues objectAtIndex:6]
                                                                                 ,[urlInterpolationValues objectAtIndex:7]
                                                                                 ,[urlInterpolationValues objectAtIndex:8]
                                                                                 ,[urlInterpolationValues objectAtIndex:9]
                                       ]
                  ];

    NSString *urlMethod = [urlConfig objectForKey:@"httpMethod"];
    if ( [urlMethod isEqualToString:@"POST"] ) {

        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
        urlRequest.HTTPMethod = @"POST";
        
        NSArray *configuredPostVars = [urlConfig objectForKey:@"postVariables"];
        NSMutableString *postString = [[NSMutableString alloc] init];
        
        for ( NSDictionary *entry in configuredPostVars ) {
            NSString *configKey = entry.allKeys.lastObject;
            NSString *configValue = entry.allValues.lastObject;
            if ( postString.length > 0 ) [postString appendString:@"&"];
            [postString appendFormat:@"%@=%@", configValue, [aPostVariables objectForKey:configKey]];
        }

        const char *postCString = [postString cStringUsingEncoding:NSUTF8StringEncoding];
        urlRequest.HTTPBody = [NSData dataWithBytes:postCString length:strlen(postCString)];
        
        return urlRequest;
        
    } else {
        
        return [NSURLRequest requestWithURL:url];
    }
}

-(NSString *)buildVariableStr:(id)aVarRaw withInputVariables:(NSDictionary *)aInputVars withPathDesc:(NSString *)aPathDesc
{
    if ( [aVarRaw isKindOfClass:[NSString class]] ) {
        
        return [aInputVars objectForKey:aVarRaw];
        
    } else if ( [aVarRaw isKindOfClass:[NSDictionary class]] ) {
        
        if ( [[aVarRaw objectForKey:@"type"] isEqualToString:@"date"] ) {
            
            long totalOffset = 0;
            
            NSNumber *dayOffset;
            if ( ( dayOffset = [aVarRaw objectForKey:@"dayOffset"] ) ) {
                totalOffset += 24 * 60 * 60 * dayOffset.floatValue;
            }
            
            NSNumber *secondOffset;
            if ( ( secondOffset = [aVarRaw objectForKey:@"secondOffset"] ) ) {
                totalOffset += secondOffset.floatValue;
            }
            
            NSDate *initDate, *dateVariableName;
            if ( ( dateVariableName = [aVarRaw objectForKey:@"useDateFromVariable"] ) ) {
                
                if ( !( initDate = [aInputVars objectForKey:dateVariableName] ) )
                    [NSException raise:kExceptionDataScraperRuntime
                                format:@"useDateFromVariable '%@' not found in urlVariables for %@", dateVariableName, aPathDesc
                     ];

            } else {
                
                initDate = [NSDate date];
            }
            
            NSDate *date = [NSDate dateWithTimeInterval:totalOffset sinceDate:initDate];
            
            static NSCalendar *calendar;
            if ( !calendar ) {
                calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
            }
            
            NSDateComponents *c = [calendar components:  NSEraCalendarUnit
                                                       | NSYearCalendarUnit
                                                       | NSMonthCalendarUnit
                                                       | NSDayCalendarUnit
                                                       | NSHourCalendarUnit
                                                       | NSMinuteCalendarUnit
                                                       | NSSecondCalendarUnit
                                                       | NSWeekCalendarUnit
                                                       | NSWeekdayCalendarUnit
                                                       | NSWeekdayOrdinalCalendarUnit
                                                       | NSQuarterCalendarUnit
                                                       | NSWeekOfMonthCalendarUnit
                                                       | NSWeekOfYearCalendarUnit
                                                       | NSYearForWeekOfYearCalendarUnit
                                                       | NSCalendarCalendarUnit
                                                       | NSTimeZoneCalendarUnit
                                              fromDate:date
                                   ];
            
            NSMutableArray *varValues = [[NSMutableArray alloc] initWithCapacity:10];
            
            for ( NSString *dateComponent in [aVarRaw objectForKey:@"dateVariables"] ) {
                if ( [dateComponent isEqualToString:@"era"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.era]];
                } else if ( [dateComponent isEqualToString:@"year"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.year]];
                } else if ( [dateComponent isEqualToString:@"twoDigitYear"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.year]];
                } else if ( [dateComponent isEqualToString:@"month"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.month]];
                } else if ( [dateComponent isEqualToString:@"day"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.day]];
                } else if ( [dateComponent isEqualToString:@"hour"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.hour]];
                } else if ( [dateComponent isEqualToString:@"minute"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.minute]];
                } else if ( [dateComponent isEqualToString:@"second"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.second]];
                } else if ( [dateComponent isEqualToString:@"week"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.week]];
                } else if ( [dateComponent isEqualToString:@"weekday"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.weekday]];
                } else if ( [dateComponent isEqualToString:@"weekdayOrdinal"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.weekdayOrdinal]];
                } else if ( [dateComponent isEqualToString:@"quarter"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.quarter]];
                } else if ( [dateComponent isEqualToString:@"weekOfMonth"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.weekOfMonth]];
                } else if ( [dateComponent isEqualToString:@"weekOfYear"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.weekOfYear]];
                } else if ( [dateComponent isEqualToString:@"yearForWeekOfYear"] ) {
                    [varValues addObject:[NSNumber numberWithInteger:c.yearForWeekOfYear]];
                } else {
                    [NSException raise:kExceptionDataScraperRuntime
                                format:@"Unknown date component '%@' in dateVariables for %@", dateComponent, aPathDesc
                     ];
                }
            }
            
            while ( varValues.count < 10 ) {
                [varValues addObject:[NSString string]];
            }

            NSString *dateStr = [NSString stringWithFormat:[aVarRaw objectForKey:@"format"] ,[[varValues objectAtIndex:0] integerValue]
                                                                                            ,[[varValues objectAtIndex:1] integerValue]
                                                                                            ,[[varValues objectAtIndex:2] integerValue]
                                                                                            ,[[varValues objectAtIndex:3] integerValue]
                                                                                            ,[[varValues objectAtIndex:4] integerValue]
                                                                                            ,[[varValues objectAtIndex:5] integerValue]
                                                                                            ,[[varValues objectAtIndex:6] integerValue]
                                                                                            ,[[varValues objectAtIndex:7] integerValue]
                                                                                            ,[[varValues objectAtIndex:8] integerValue]
                                                                                            ,[[varValues objectAtIndex:9] integerValue]
                                 ];
            
NSLog(@"returned date string is: %@", dateStr);
            return dateStr;
        }
    }
    
    return nil; //never reached
}


-(id)parseDataString:(NSString *)aDataString
        forOperation:(NSString *)aOperation
        forOutputTag:(NSString *)aOutputTag
{
    
    NSDictionary *outputConfig = [self fetchOperation:aOperation forOutputTag:aOutputTag];
    if ( !outputConfig )
        [NSException raise:kExceptionDataScraperRuntime
                    format:@"No output config '%@' found for operation '%@'", aOutputTag, aOperation
         ];

    return [self parseDataString:aDataString forOutputConfig:outputConfig];
}

-(void)setUrlHardPrefix:(NSString *)aPrefix
{
    if ( self.urlHardPrefix ) {
        [NSException raise:kExceptionDataScraperRuntime format:@"Cannot set hardUrlPrefix on a data scraper more than once"];
    } else {
        _urlHardPrefix = aPrefix;
    }
}

////
#pragma mark instance methods (private)
////
-(NSDictionary *)fetchOperation:(NSString *)aOperation forSourceTag:(NSString *)aSourceTag
{
    for ( CSWDataScraperConfig *config in self.configs ) {
        
        NSDictionary *sourceConfig;
        if ( ( sourceConfig = [config fetchConfigForOperation:aOperation forSourceTag:aSourceTag] ) ) {
            return  sourceConfig;
        }
    }
    
    return nil;
}

-(NSDictionary *)fetchOperation:(NSString *)aOperation forOutputTag:(NSString *)aOutputTag
{
    for ( CSWDataScraperConfig *config in self.configs ) {
        
        NSDictionary *outputConfig;
        if ( ( outputConfig = [config fetchConfigForOperation:aOperation forOutputTag:aOutputTag] ) ) {
            return  outputConfig;
        }
    }
    
    return nil;
}

-(id)parseDataString:(NSString *)aDataString forOutputConfig:(NSDictionary *)aOutputConfig
{
    id config;
    if ( ( config = [aOutputConfig objectForKey:@"parseCycles"] ) ) {
        
        NSMutableArray *cyclesResults = [[NSMutableArray alloc] init];
        for ( NSDictionary *parseCycleConfig in config ) {
            [cyclesResults addObject:[self parseDataStringForSingleCycle:aDataString forOutputConfig:parseCycleConfig]];
        }
        return cyclesResults;
        
    } else if ( ( config = [aOutputConfig objectForKey:@"parseCyclesUntilSuccess"] ) ) {
        
        for ( NSDictionary *parseCycleConfig in config ) {
            id result = [self parseDataStringForSingleCycle:aDataString forOutputConfig:parseCycleConfig];

            if ( result
                 && ( [result isKindOfClass:[NSArray class]] || [result isKindOfClass:[NSDictionary class]] )
                 && [result count] > 0
               ) {
                return result;
            }
        }
        return nil;
        
    } else if ( ( config = [aOutputConfig objectForKey:@"combineParseCycles"] ) ) {
        
        NSMutableDictionary *combinedDict = [[NSMutableDictionary alloc] init];
        for ( NSDictionary *parseCycleConfig in config ) {
            NSDictionary *partialDict = [self parseDataStringForSingleCycle:aDataString forOutputConfig:parseCycleConfig];
            [combinedDict addEntriesFromDictionary:partialDict];
        }
        return combinedDict;
        
    } else if ( ( config = [aOutputConfig objectForKey:@"parse"] ) ) {
        
        return [self parseDataStringForSingleCycle:aDataString forOutputConfig:config];

    } else if ( ( config = [aOutputConfig objectForKey:@"eachGroupBy"] ) ) {
        
        return [self parseDataString:aDataString
                   forGroupByPattern:[aOutputConfig objectForKey:@"groupByPattern"]
                      forParseConfig:config
                ];
    }

    return nil;  // never reached
}

-(NSDictionary *)parseDataString:(NSString *)aDataString
               forGroupByPattern:(NSString *)aGroupByPattern
                  forParseConfig:(NSDictionary *)aParseConfig
{
    NSError *error;
    NSRegularExpression *groupByRegEx = [[NSRegularExpression alloc] initWithPattern:aGroupByPattern
                                                                             options:NSRegularExpressionDotMatchesLineSeparators
                                                                               error:&error
                                         ];
    if ( error )
        [NSException raise:kExceptionDataScraperRuntime
                    format:@"Unable to parse group by expression: %@", [error localizedDescription]
         ];
    
    NSArray *groupByMatches = [groupByRegEx matchesInString:aDataString
                                                    options:0
                                                      range:NSMakeRange(0, aDataString.length)
                               ];
    
    if ( groupByMatches.count < 1 ) return [NSDictionary dictionary];

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for ( int i = 0; i < groupByMatches.count; i++ ) {
        
        NSTextCheckingResult *groupByMatch = [groupByMatches objectAtIndex:i];
        NSString *activeKey = [aDataString substringWithRange:[groupByMatch rangeAtIndex:1]];
        NSRange groupByRange = [groupByMatch rangeAtIndex:0];
        
        int startLocation = groupByRange.location + groupByRange.length;
        
        int endLocation;
        if ( groupByMatches.count == i+1 ) {
            endLocation = aDataString.length;
        } else {
            endLocation = [[groupByMatches objectAtIndex:i+1] rangeAtIndex:0].location;
        }

        NSString *elementsStr = [aDataString substringWithRange:NSMakeRange(startLocation, endLocation - startLocation)];
        [dict setObject:[self parseDataString:elementsStr forOutputConfig:aParseConfig] forKey:activeKey];
    }

    return dict;
}

-(id)parseDataStringForSingleCycle:(NSString *)aDataString forOutputConfig:(NSDictionary *)aParseConfig
{
    NSDictionary *capturesConfig = [aParseConfig objectForKey:@"captures"];

    NSDictionary *defaultsDict = [aParseConfig objectForKey:@"defaultValues"];
    if ( !defaultsDict ) defaultsDict = [NSDictionary dictionary];
    
    NSMutableDictionary *onMatchDict = [NSMutableDictionary dictionaryWithDictionary:defaultsDict];
    [onMatchDict addEntriesFromDictionary:[aParseConfig objectForKey:@"matchValues"]];
    
    NSString *parsePatternStr = [aParseConfig objectForKey:@"pattern"];
    
    NSRegularExpression *parsePatternRegEx = [[NSRegularExpression alloc] initWithPattern:parsePatternStr
                                                                                  options:NSRegularExpressionDotMatchesLineSeparators
                                                                                    error:NULL
                                              ];
    
    NSArray *dataMatches = [parsePatternRegEx matchesInString:aDataString
                                                      options:0
                                                        range:NSMakeRange(0, aDataString.length)
                            ];

    NSDictionary *matchWithinRange = [aParseConfig objectForKey:@"matchWithinRange"];
    if ( matchWithinRange ) {
        
        int startIndexMatchNo    = [[matchWithinRange objectForKey:@"startIndexMatchNo"] integerValue];
        NSString *startAtPattern = [matchWithinRange objectForKey:@"startAtPattern"];
        NSString *endAtPattern   = [matchWithinRange objectForKey:@"endAtPattern"];
        
        int startMarker = -1;
        if ( startAtPattern ) {

            NSRegularExpression *startAtPatternRegEx = [[NSRegularExpression alloc] initWithPattern:startAtPattern
                                                                                            options:NSRegularExpressionDotMatchesLineSeparators
                                                                                              error:NULL
                                                        ];
            NSArray *startMatches = [startAtPatternRegEx matchesInString:aDataString
                                                                 options:0
                                                                   range:NSMakeRange(0, aDataString.length)
                                     ];
            
            if ( startMatches.count <= startIndexMatchNo ) return [NSArray array];
            
            NSTextCheckingResult *startMatch = [startMatches objectAtIndex:startIndexMatchNo];
            
            NSRange startRange = [startMatch rangeAtIndex:0];
            startMarker = startRange.location + startRange.length;
        }

        int endMarker = -1;
        if ( endAtPattern ) {
            
            NSRegularExpression *endAtPatternRegEx = [[NSRegularExpression alloc] initWithPattern:endAtPattern
                                                                                          options:NSRegularExpressionDotMatchesLineSeparators
                                                                                            error:NULL
                                                      ];
        
            NSArray *endMatches = [endAtPatternRegEx matchesInString:aDataString
                                                             options:0
                                                               range:NSMakeRange(0, aDataString.length)
                                   ];
            
            if ( endMatches.count ) {
            
                for ( NSTextCheckingResult *endMatch in endMatches ) {
             
                    int endMatchLoc = [endMatch rangeAtIndex:0].location;
                
                    if ( endMatchLoc > startMarker ) {
                        endMarker = endMatchLoc;
                        break;
                    }
                }
            }
        }

        NSArray *usableMatches;
        if ( startMarker < 0 && endMarker < 0 ) {
            
            usableMatches = dataMatches;
            
        } else {
            
            NSMutableArray *usableMatchesBuilder = [[NSMutableArray alloc] init];
                             
            for ( NSTextCheckingResult *dataMatch in dataMatches ) {

                NSRange matchRange = [dataMatch rangeAtIndex:0];
                if ( endMarker >= 0 && matchRange.location + matchRange.length > endMarker ) break;

                if ( matchRange.location > startMarker ) {
                    [usableMatchesBuilder addObject:dataMatch];
                }
            }
            
            dataMatches = [NSArray arrayWithArray:usableMatchesBuilder];
        }
    }
    
    NSDictionary *matchesAsArray  = [aParseConfig objectForKey:@"matchesAsArray"];
    NSDictionary *matchesAsDict   = [aParseConfig objectForKey:@"matchesAsDict"];
    NSNumber     *matchIteration  = [aParseConfig objectForKey:@"matchIteration"];
    
    if ( matchesAsArray ) {
    
        if ( !dataMatches.count ) return [NSArray array];
        
        int startIndex  = [[matchesAsArray objectForKey:@"startIndex"] integerValue];
        int endIndex    = [[matchesAsArray objectForKey:@"endIndex"] integerValue];
        
        NSMutableArray *results = [[NSMutableArray alloc] init];
        for ( int i = 0; i < dataMatches.count; i++ ) {
            if ( i < startIndex ) continue;
            if ( endIndex > 0 && i >= endIndex ) break;

            [results addObject:[self buildDictionaryForMatch:[dataMatches objectAtIndex:i]
                                              withDataString:aDataString
                                          withCapturesConfig:capturesConfig
                                               startWithDict:defaultsDict
                                ]
             ];
        }
    
        return results;

    } else if ( matchesAsDict ) {

        if ( !dataMatches.count ) return [NSArray array];
        
        int startIndex  = [[matchesAsDict objectForKey:@"startIndex"] integerValue];
        int endIndex    = [[matchesAsDict objectForKey:@"endIndex"] integerValue];
        
        NSDictionary *appendingStrings = [matchesAsDict objectForKey:@"appendingStrings"];
        
        NSMutableDictionary *combinedDict = [[NSMutableDictionary alloc] init];
        for ( int i = 0; i < dataMatches.count; i++ ) {
            if ( i < startIndex ) continue;
            if ( endIndex > 0 && i >= endIndex ) break;

            NSDictionary *appendDict = [self buildDictionaryForMatch:[dataMatches objectAtIndex:i]
                                                      withDataString:aDataString
                                                  withCapturesConfig:capturesConfig
                                                       startWithDict:defaultsDict
                                        ];
            
            for ( NSString *key in appendDict.allKeys ) {
                
                NSString *val = [appendDict objectForKey:key];
                
                if ( [appendingStrings objectForKey:key] ) {
                    
                    NSString *existingStr = [combinedDict objectForKey:key];
                    if ( existingStr ) {
                        [combinedDict setObject:[existingStr stringByAppendingString:val] forKey:key];
                    } else {
                        [combinedDict setObject:val forKey:key];
                    }
                    
                } else {
                    
                    [combinedDict setObject:val forKey:key];
                }
            }
        }
    
        return combinedDict;
        
    } else {
        
        // matchIteration
        if ( !dataMatches.count ) return defaultsDict;
        
        int matchIndex = [matchIteration integerValue];
        
        if ( matchIndex >= dataMatches.count ) return defaultsDict;

        return [self buildDictionaryForMatch:[dataMatches objectAtIndex:matchIndex]
                              withDataString:aDataString
                          withCapturesConfig:capturesConfig
                               startWithDict:onMatchDict
                ];
    }
}


-(NSDictionary *)buildDictionaryForMatch:(NSTextCheckingResult *)aMatch
                          withDataString:(NSString *)aDataString
                      withCapturesConfig:(NSDictionary *)aCapturesConfig
                           startWithDict:(NSDictionary *)aDict
{
    if ( !aCapturesConfig ) return aDict;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:aDict];
    NSArray *sortedKeys = [aCapturesConfig.allKeys sortedArrayUsingComparator:^(id obj1, id obj2) {
        return [[aCapturesConfig objectForKey:obj1] compare:[aCapturesConfig objectForKey:obj2]];
    }];
    
    for ( NSString *key in sortedKeys ) {
    
        int captureIndex = [[aCapturesConfig objectForKey:key] integerValue];
        
        if ( captureIndex > aMatch.numberOfRanges )
            [NSException raise:kExceptionDataScraperRuntime
                        format:@"parse pattern speciifies capture %d but only captures %d expressions", captureIndex, aMatch.numberOfRanges
             ];

        NSRange captureRange = [aMatch rangeAtIndex:captureIndex];

        NSString *captureStr;
        if ( captureRange.length > 0 ) {
            captureStr = [aDataString substringWithRange:captureRange];
        } else {
            captureStr = [NSString string];
        }
        
        [dict setObject:captureStr forKey:key];
    }
    
    return dict;
}

@end
