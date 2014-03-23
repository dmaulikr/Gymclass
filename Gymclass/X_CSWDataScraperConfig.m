//
//  CSWDataScraperConfig.m
//  Gymclass
//
//  Created by Eric Colton on 2/9/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import "CSWDataScraperConfig.h"

@interface CSWDataScraperConfig()
{
    NSURL *_url;
}

+(void)validateStruct:(id)aStruct;
+(void)validateSourceStruct:(NSDictionary *)aStruct forPathDesc:(NSString *)aPathDesc;
+(void)validateOutputStruct:(NSDictionary *)aStruct forPathDesc:(NSString *)aPathDesc;
+(void)validateParseStruct:(NSDictionary *)aParseStruct forPathDesc:(NSString *)aPathDesc;

@end

@implementation CSWDataScraperConfig

@synthesize configStruct = _configStruct;

////
#pragma mark init methods (public)
////
-(id)initWithStruct:(NSDictionary *)aStruct
{
    self = [super init];
    if ( self ) {
        self.configStruct = aStruct;
    }
    
    return self;
}

-(id)initWithURL:(NSURL *)aUrl
{
    self = [super init];
    if ( self ) {
        self.url = aUrl;
    }
    
    return self;
}

-(id)initWithBundledPlist:(NSString *)aPlistName
{
    NSString *configPath = [[NSBundle mainBundle] pathForResource:aPlistName ofType:@"plist"];
    
    NSError *error;
    NSData *configData = [NSData dataWithContentsOfFile:configPath
                                                options:0
                                                  error:&error
                          ];
    if ( error )
        [NSException raise:kExceptionDataScraperConfigBundle
                    format:@"Could not read bundled plist for dataScraperConfig at path '%@'.  Error: %@", configPath, [error localizedDescription]
         ];

    NSDictionary *configStruct = [NSPropertyListSerialization propertyListWithData:configData
                                                                           options:NSPropertyListImmutable
                                                                            format:nil
                                                                             error:&error
                                  ];
    
    if ( error )
        [NSException raise:kExceptionDataScraperConfigBundle
                    format:@"Could not parse plist config for dataScraperConfig from path: '%@'.  Error: %@", configPath, [error localizedDescription]
         ];
    
    return [self initWithStruct:configStruct];
}

////
#pragma mark accessor methods (public)
////
-(void)setConfigStruct:(NSDictionary *)aConfigStruct
{
    if ( aConfigStruct != _configStruct ) {
        [CSWDataScraperConfig validateStruct:aConfigStruct];
        _configStruct = aConfigStruct;
    }
}

////
#pragma mark instance methods (public)
////
-(void)refreshFromWeb:(NSError **)aError
{
    if ( !_url )
        [NSException raise:kExceptionDataScraperConfigIllegalOp
                    format:@"Can only call fetchConfigFromWeb: on a DataScrapeConfig object initalized with a URL"
         ];

    NSURLRequest *req = [[NSURLRequest alloc] initWithURL:_url];
    
    NSURLResponse *response;
    NSError *error;
    NSData *webData = [NSURLConnection sendSynchronousRequest:req
                                            returningResponse:&response
                                                        error:&error
                       ];
    
    if ( error ) {
        _configStruct = nil;
        if ( aError ) *aError = error;
        return;
    }

    NSDictionary *configStruct = [NSPropertyListSerialization propertyListWithData:webData
                                                                           options:NSPropertyListImmutable
                                                                            format:NULL
                                                                             error:&error
                                  ];
    
    if ( error )
        [NSException raise:kExceptionDataScraperConfigValidate
                    format:@"Could not parse plist config for dataScraperConfig from URL: '%@'.  Error: %@", _url, [error localizedDescription]
         ];
    
    [CSWDataScraperConfig validateStruct:configStruct];
    _configStruct = configStruct;
}

-(NSDictionary *)fetchConfigForOperation:(NSString *)aOperation forSourceTag:(NSString *)aSourceTag
{
    return [[[self.configStruct objectForKey:aOperation] objectForKey:@"source"] objectForKey:aSourceTag];
}

-(NSDictionary *)fetchConfigForOperation:(NSString *)aOperation forOutputTag:(NSString *)aOutputTag
{
    return [[[self.configStruct objectForKey:aOperation] objectForKey:@"output"] objectForKey:aOutputTag];
}

////
#pragma mark class methods (private)
////
+(void)validateStruct:(id)aStruct
{
    if ( ![aStruct isKindOfClass:[NSDictionary class]] )
        [NSException raise:kExceptionDataScraperConfigValidate
                    format:@"root structure is not a an NSDictionary"
         ];
    
    for ( id operationKey in [aStruct allKeys] ) {
        
        if ( ![operationKey isKindOfClass:[NSString class]] )
            [NSException raise:kExceptionDataScraperConfigValidate
                        format:@"operation '%@' of root structure is not an NSString", operationKey
             ];
        
        id operationVal = [aStruct objectForKey:operationKey];
        
        if ( ![operationVal isKindOfClass:[NSDictionary class]] )
            [NSException raise:kExceptionDataScraperConfigValidate
                        format:@"value for operation '%@' must be an NSDictionary", operationVal
             ];
        
        id source = [operationVal objectForKey:@"source"];
        if ( source ) {
                
            if ( ![source isKindOfClass:[NSDictionary class]] )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"value for key 'source' for operation '%@' must be an NSDictionary", operationKey
                 ];
                
            for ( id sourceTag in [source allKeys] ) {
                
                if ( ![sourceTag isKindOfClass:[NSString class]] )
                    [NSException raise:kExceptionDataScraperConfigValidate
                                format:@"sourceTag '%@' for opeation '%@' is not an NSString", sourceTag, operationKey
                     ];

                id sourceVal = [source objectForKey:sourceTag];
                
                if ( ![sourceVal isKindOfClass:[NSDictionary class]] )
                    [NSException raise:kExceptionDataScraperConfigValidate
                                format:@"value for sourceTag '%@' for operation '%@' is not an NSDictionary", sourceTag, operationKey
                     ];
        
                [self validateSourceStruct:sourceVal
                               forPathDesc:[NSString stringWithFormat:@"%@.source.%@", operationKey, sourceTag]
                 ];
            }
        }
                    
        id output = [operationVal objectForKey:@"output"];
        if ( output ) {
                
            if ( ![output isKindOfClass:[NSDictionary class]] )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"value for key 'output' for operation '%@' must be an NSDictionary", operationKey
                 ];
            
            for ( id outputTag in [source allKeys] ) {
                        
                if ( ![outputTag isKindOfClass:[NSString class]] )
                    [NSException raise:kExceptionDataScraperConfigValidate
                                format:@"value for outputTag '%@' for operation '%@' is not an NSString", outputTag, operationKey
                     ];
                        
                id outputVal = [output objectForKey:outputTag];
                
                if ( ![outputVal isKindOfClass:[NSDictionary class]] )
                    [NSException raise:kExceptionDataScraperConfigValidate
                                format:@"outputTag '%@' for '%@' must be an NSDictionary", outputTag, operationKey
                     ];
                
                [self validateOutputStruct:outputVal
                               forPathDesc:[NSString stringWithFormat:@"%@.output.%@", operationKey, outputTag]
                 ];
            }
        }
    }
}

+(void)validateSourceStruct:(NSDictionary *)aStruct forPathDesc:(NSString *)aPathDesc
{
    id url = [aStruct objectForKey:@"url"];
    if ( url ) {
        
        if ( ![url isKindOfClass:[NSDictionary class]] )
            [NSException raise:kExceptionDataScraperConfigValidate
                        format:@"'url' in '%@' must be an NSDictionary", aPathDesc
             ];
        
        NSString *pathDesc = [NSString stringWithFormat:@"%@.url", aPathDesc];
        
        id format = [url objectForKey:@"format"];
        if ( format ) {
                
            if ( ![format isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"'format' in '%@' must be an NSString", pathDesc
                 ];

        } else {

            [NSException raise:kExceptionDataScraperConfigValidate
                        format:@"'%@' must contain a 'format' string ", pathDesc
             ];
        }
            
        id variables = [url objectForKey:@"variables"];
        if ( variables ) {
                
            if ( ![variables isKindOfClass:[NSArray class]] )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"if specified, value for key 'variables' in '%@' must be an NSArray", pathDesc
                 ];
            
            for ( int i = 0; i < [variables count]; i++ ) {

                NSString *pathDesc = [NSString stringWithFormat:@"%@.variables[%d]", pathDesc, i];
                
                id variableVal = [variables objectAtIndex:i];
                
                if ( [variableVal isKindOfClass:[NSDictionary class]] ) {

                    id type = [variableVal objectForKey:@"type"];
                    if ( type ) {
                        
                        if ( ![type isKindOfClass:[NSString class]] )
                            [NSException raise:kExceptionDataScraperConfigValidate
                                        format:@"value for key 'type' in '%@' must be an NSString", pathDesc
                             ];

                        if ( [type isEqualToString:@"date"] ) {
                            
                            id useDate = [variableVal objectForKey:@"useDate"];
                            if ( useDate ) {
                                if ( ![useDate isKindOfClass:[NSString class]] ) {
                                    [NSException raise:kExceptionDataScraperConfigValidate
                                                format:@"if specified, value for key 'useDate' in date-dictionary '%@' must be an NSString", pathDesc
                                     ];
                                }
                            }

                            id dayOffset = [variableVal objectForKey:@"dayOffset"];
                            if ( dayOffset ) {
                                if ( ![dayOffset isKindOfClass:[NSNumber class]] ) {
                                    [NSException raise:kExceptionDataScraperConfigValidate
                                                format:@"if specified, value for key 'dayOffset' in date-dictionary '%@' must be an NSNumber", pathDesc
                                     ];
                                }
                            }

                            id secondOffset = [variableVal objectForKey:@"secondOffset"];
                            if ( secondOffset ) {
                                if ( ![secondOffset isKindOfClass:[NSNumber class]] ) {
                                    [NSException raise:kExceptionDataScraperConfigValidate
                                                format:@"if specified, value for key 'secondOffset' in date-dictionary in '%@' must be an NSNumber", pathDesc
                                     ];
                                }
                            }
                            
                            id format = [variableVal objectForKey:@"format"];
                            if ( format ) {
                                if ( ![format isKindOfClass:[NSString class]] ) {
                                    [NSException raise:kExceptionDataScraperConfigValidate
                                                format:@"value for key 'format' of date-dictionary in '%@' must be an NSString", pathDesc
                                     ];
                                }
                                
                            } else {
                            
                                [NSException raise:kExceptionDataScraperConfigValidate
                                            format:@"date-dictionary in '%@' must contain a 'format' entry", pathDesc
                                 ];
                            }
                            
                            id dateVariables = [variableVal objectForKey:@"dateVariables"];
                            if ( dateVariables ) {
                                
                            if ( ![dateVariables isKindOfClass:[NSArray class]] ) {
                                [NSException raise:kExceptionDataScraperConfigValidate
                                            format:@"value for key 'dateVariables' in date-variable dictionary in '%@' must be an NSArray", pathDesc
                                 ];
                            }
                                
                            for ( int j = 0; j < [dateVariables count]; j++ ) {
                                
                                NSString *pathDesc = [NSString stringWithFormat:@"%@.dateVariables[%d]", pathDesc, j];
                                
                                id dateVar = [dateVariables objectAtIndex:j];
                                
                                if ( ![dateVar isKindOfClass:[NSString class]] )
                                    [NSException raise:kExceptionDataScraperConfigValidate
                                                format:@"'%@' must be an NSString", pathDesc
                                     ];
                                
                                if ( [dateVar isEqualToString:@"era"] ) {
                                } else if ( [dateVar isEqualToString:@"year"] ) {
                                } else if ( [dateVar isEqualToString:@"twoDigitYear"] ) {
                                } else if ( [dateVar isEqualToString:@"month"] ) {
                                } else if ( [dateVar isEqualToString:@"day"] ) {
                                } else if ( [dateVar isEqualToString:@"hour"] ) {
                                } else if ( [dateVar isEqualToString:@"minute"] ) {
                                } else if ( [dateVar isEqualToString:@"second"] ) {
                                } else if ( [dateVar isEqualToString:@"week"] ) {
                                } else if ( [dateVar isEqualToString:@"weekday"] ) {
                                } else if ( [dateVar isEqualToString:@"weekdayOrdinal"] ) {
                                } else if ( [dateVar isEqualToString:@"quarter"] ) {
                                } else if ( [dateVar isEqualToString:@"weekOfMonth"] ) {
                                } else if ( [dateVar isEqualToString:@"weekOfYear"] ) {
                                } else if ( [dateVar isEqualToString:@"yearForWeekOfYear"] ) {
                                } else {
                                    [NSException raise:kExceptionDataScraperConfigValidate
                                                format:@"'%@' is not a valid date component string", pathDesc
                                     ];
                                }
                            }

                        } else {

                                [NSException raise:kExceptionDataScraperConfigValidate
                                            format:@"'%@' must contain a 'dateVariables' entry", pathDesc
                                 ];
                            }

                        } else {
                            
                            [NSException raise:kExceptionDataScraperConfigValidate
                                        format:@"value '%@' for key 'type' in '%@' is invalid", type, pathDesc
                             ];
                        }
                    
                    } else if ( [variableVal isKindOfClass:[NSString class]] ) {
                        
                        // no op
                        
                    } else {
                        
                        [NSException raise:kExceptionDataScraperConfigValidate
                                    format:@"'%@' must be either an NSString or an NSDictionary", pathDesc
                         ];
                    }
                }
            }
        }
        
    } else {
        
        [NSException raise:kExceptionDataScraperConfigValidate
                    format:@"'%@' must contain a 'url' dictionary", aPathDesc
        ];
    }
}


+(void)validateOutputStruct:(NSDictionary *)aStruct forPathDesc:(NSString *)aPathDesc
{
    NSString *arrayTag;
    int parseCyclesSpecified = 0;
    if ( [aStruct objectForKey:@"parseCycles"] ) {
        parseCyclesSpecified = 1;
        arrayTag = @"parseCycles";
    }

    int parseCyclesUntilSuccessSpecified = 0;
    if ( [aStruct objectForKey:@"parseCyclesUntilSuccess"] ) {
        parseCyclesUntilSuccessSpecified = 1;
        arrayTag = @"parseCyclesUntilSuccess";
    }
    
    int combineParseCyclesSpecified = 0;
    if ( [aStruct objectForKey:@"combineParseCycles"] ) {
        combineParseCyclesSpecified = 1;
        arrayTag = @"combineParseCycles";
    }

    if ( arrayTag ) {
        
        id arrayVal = [aStruct objectForKey:arrayTag];

        if ( ![arrayVal isKindOfClass:[NSArray class]] )
            [NSException raise:kExceptionDataScraperConfigValidate
                        format:@"value for key '%@' in '%@' must be an NSArray", arrayTag, aPathDesc
             ];
        
        for ( int i = 0; i < [arrayVal count]; i++ ) {
            id parseEntry = [arrayVal objectAtIndex:i];
            [self validateParseStruct:parseEntry forPathDesc:[NSString stringWithFormat:@"%@.%@[%d]", aPathDesc, arrayTag, i]];
        }
    }
    
    id dictVal;
    int parseSpecified = 0;
    if ( ( dictVal = [aStruct objectForKey:@"parse"] ) ) {

        parseSpecified = 1;
        [self validateParseStruct:dictVal forPathDesc:[NSString stringWithFormat:@"%@.parse", aPathDesc]];
    }

    int eachGroupSpecified = 0;
    if ( ( dictVal = [aStruct objectForKey:@"eachGroup"] ) ) {

        eachGroupSpecified = 1;
        id groupByPattern;
        if ( ( groupByPattern = [aStruct objectForKey:@"groupByPattern"] ) ) {

            if ( ![groupByPattern isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"value for key 'groupByPattern' in '%@' must be an NSString", aPathDesc
                 ];
            
            NSError *error;
            NSRegularExpression *groupByRegEx = [NSRegularExpression regularExpressionWithPattern:groupByPattern
                                                                                          options:NSRegularExpressionDotMatchesLineSeparators
                                                                                            error:&error
                                                 ];
            
            if ( error )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"groupByPattern '%@' in '%@' could not be compiled. Error: %@", groupByPattern, aPathDesc, [error localizedDescription]
                 ];
                
            if ( groupByRegEx.numberOfCaptureGroups < 1) {
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"groupByPattern '%@' must capture at least one substring in '%@'", groupByPattern, aPathDesc
                 ];
            }
            
        } else {
            
            [NSException raise:kExceptionDataScraperConfigValidate
                        format:@"cannot specify an 'eachGroup' entry without an 'groupByPattern' entry in '%@'", aPathDesc
             ];
        }
        
        if ( ![dictVal isKindOfClass:[NSDictionary class]] )
            [NSException raise:kExceptionDataScraperConfigValidate
                        format:@"if specified, value for key 'eachGroup' in '%@' must be an NSDictionary", aPathDesc
             ];

        [self validateParseStruct:dictVal forPathDesc:[NSString stringWithFormat:@"%@.eachGroup", aPathDesc]];
    }
    
    if ( !eachGroupSpecified && [aStruct objectForKey:@"groupByPattern"] ) {
        
        [NSException raise:kExceptionDataScraperConfigValidate
                    format:@"cannot specify 'groupByPattern' without an 'eachGroup' entry in '%@'", aPathDesc
         ];
    }
    
    int instructionsSpecified = parseCyclesSpecified + parseCyclesUntilSuccessSpecified + combineParseCyclesSpecified + parseSpecified + eachGroupSpecified;

    if ( instructionsSpecified == 0 )
        [NSException raise:kExceptionDataScraperConfigValidate
                    format:@"no valid parse instruction entry found in '%@'", aPathDesc
         ];
    
    if ( instructionsSpecified > 1 )
        [NSException raise:kExceptionDataScraperConfigValidate
                    format:@"only one parse instruction can be specified in '%@'", aPathDesc
         ];
}

+(void)validateParseStruct:(NSDictionary *)aParseStruct forPathDesc:(NSString *)aPathDesc
{
    if ( ![aParseStruct isKindOfClass:[NSDictionary class]] )
        [NSException raise:kExceptionDataScraperConfigValidate
                    format:@"'%@' must be an NSDictionary", aPathDesc
         ];
    
    id captures;
    int highestCaptureSpecified = 0;
    if ( ( captures = [aParseStruct objectForKey:@"captures"] ) ) {
        
        if ( ![captures isKindOfClass:[NSDictionary class]] )
            [NSException raise:kExceptionDataScraperConfigValidate
                        format:@"if specified, value for key 'captures' in '%@' must be an NSDictionary", aPathDesc
             ];

        NSString *pathDesc = [NSString stringWithFormat:@"%@.captures", aPathDesc];
        
        for ( id captureKey in [captures allKeys] ) {
            
            if ( ![captureKey isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"capture key '%@' in '%@' must be an NSString", captureKey, pathDesc
                 ];
            
            id captureVal = [captures objectForKey:captureKey];
            
            if ( ![captureVal isKindOfClass:[NSNumber class]] )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"if specified, value for '%@' in '%@' must be an NSNumber", captureKey, pathDesc
                 ];
            
            int captureValInt = [captureVal intValue];
            
            if ( captureValInt < 0 )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"value for capture key '%@' in '%@' must be a positive integer", captureKey, pathDesc
                 ];
            
            if ( captureValInt > highestCaptureSpecified )
                highestCaptureSpecified = captureValInt;
        }
    }

    id pattern = [aParseStruct objectForKey:@"pattern"];
    if ( pattern ) {
        
        if ( ![pattern isKindOfClass:[NSString class]] )
            [NSException raise:kExceptionDataScraperConfigValidate
                        format:@"value for key 'pattern' in '%@' must be an NSString", aPathDesc
             ];
        
        NSString *pathDesc = [NSString stringWithFormat:@"%@.pattern", aPathDesc];
        
        NSError *error;
        NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:NSRegularExpressionDotMatchesLineSeparators
                                                                                 error:&error
                                      ];
        
        if ( error )
            [NSException raise:kExceptionDataScraperConfigValidate
                        format:@"regular expression pattern '%@' in '%@' could not be compiled. Error: %@", pattern, pathDesc, [error localizedDescription]
             ];
        
        if ( highestCaptureSpecified > regEx.numberOfCaptureGroups )
            [NSException raise:kExceptionDataScraperConfigValidate
                        format:@"pattern '%@' does not capture as many substrings (%d) as the highest capture specified (%d) in the 'captures' dictionary in '%@'", pattern, regEx.numberOfCaptureGroups, highestCaptureSpecified, pathDesc
             ];
             
    } else {
        
        [NSException raise:kExceptionDataScraperConfigValidate
                    format:@"parse instruction must specify a 'pattern' entry in '%@'", aPathDesc
         ];
    }

    int matchIterationSpecified = 0;
    id matchIteration = [aParseStruct objectForKey:@"matchIteration"];
    if ( matchIteration ) {
        
        matchIterationSpecified = 1;
        
        if ( ![matchIteration isKindOfClass:[NSNumber class]] )
            [NSException raise:kExceptionDataScraperConfigValidate
                        format:@"if specified, value for key 'matchIteration' in '%@' must be an NSNumber", aPathDesc
             ];
    }

    id matchAsArray = [aParseStruct objectForKey:@"matchAsArray"];

    int matchAsArraySpecified = 0;
    if ( matchAsArray ) {
        
        matchAsArraySpecified = 1;
        
        if ( ![matchAsArray isKindOfClass:[NSDictionary class]] )
            [NSException raise:kExceptionDataScraperConfigValidate
                        format:@"if specified, value for 'matchAsArray' in '%@' must be an NSDictionary", aPathDesc
             ];
        
        NSString *pathDesc = [NSString stringWithFormat:@"%@.matchesAsArray", aPathDesc];
        
        id startIndex = [matchAsArray objectForKey:@"startIndex"];
        if ( startIndex ) {
            
            if ( ![startIndex isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"value for key 'startIndex' in '%@' must be an NSString", pathDesc
                 ];
        }

        id endIndex = [matchAsArray objectForKey:@"endIndex"];
        if ( endIndex ) {
            
            if ( ![endIndex isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"value for key 'endIndex' in '%@' must be an NSString", pathDesc
                 ];
        }
        
        id all = [matchAsArray objectForKey:@"all"];
        if ( all ) {
            
            if ( ![all isKindOfClass:[NSNumber class]] || ![all boolValue] )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"if specified, value for key 'all' in '%@' must be a true value", pathDesc
                 ];
            
            if ( startIndex )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"key 'all' cannot be specified if key 'startIndex' is specified in '%@'", pathDesc
                 ];
                
            if ( endIndex )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"key 'all' cannot be specified if key 'endIndex' is specified in '%@'", pathDesc
                 ];
            
        } else if ( !startIndex && !endIndex ) {

            [NSException raise:kExceptionDataScraperConfigValidate
                        format:@"key 'all' must be specified if 'startIndex' and/or 'endIndex' are not specified in '%@'", pathDesc
             ];
        }
    }

    id matchAsDict = [aParseStruct objectForKey:@"matchAsDict"];

    int matchAsDictSpecified = 0;
    if ( matchAsDict ) {

        matchAsDictSpecified = 1;
        
        if ( ![matchAsDict isKindOfClass:[NSDictionary class]] )
            [NSException raise:kExceptionDataScraperConfigValidate
                        format:@"if specified, value for key 'matchAsDict' in '%@' must be an NSDictionary", aPathDesc
             ];
        
        NSString *pathDesc = [NSString stringWithFormat:@"%@.matchesAsDict", aPathDesc];
        
        id startIndex = [matchAsDict objectForKey:@"startIndex"];
        if ( startIndex ) {
            
            if ( ![startIndex isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"value for key 'startIndex' in '%@' must be an NSString", pathDesc
                 ];
        }
        
        id endIndex = [matchAsDict objectForKey:@"endIndex"];
        if ( endIndex ) {
            
            if ( ![endIndex isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"value for key 'endIndex' in '%@' must be an NSString", pathDesc
                 ];
        }
        
        id appendingStrings = [matchAsDict objectForKey:@"appendingStrings"];
        if ( appendingStrings ) {
            
            if ( ![appendingStrings isKindOfClass:[NSDictionary class]] )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"value for key 'appendingStrings' in '%@' must be an NSDictionary", pathDesc
                 ];
            
            if ( [appendingStrings count] == 0 )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"dictionary for key 'appendingStrings' in '%@' must have at least one entry", pathDesc
                 ];

            for ( id key in [appendingStrings allKeys] ) {
                
                if ( ![key isKindOfClass:[NSString class]] )
                    [NSException raise:kExceptionDataScraperConfigValidate
                                format:@"value for key '%@' in 'appendingStrings' dictionary in '%@' is not an NSString", key, pathDesc
                     ];
                
                id val = [appendingStrings objectForKey:key];
                if ( ![val isKindOfClass:[NSNumber class]] ) {
                    [NSException raise:kExceptionDataScraperConfigValidate
                                format:@"value for key '%@' in 'appendingStrings' dictionary in '%@' is not a true NSNumber", key, pathDesc
                     ];
                }
            }
        }
    }
    
    int instructionsSpecified = matchIterationSpecified + matchAsArraySpecified + matchAsDictSpecified;
    if ( instructionsSpecified > 1 )
        [NSException raise:kExceptionDataScraperConfigValidate
                    format:@"only one parse instruction can be specified in '%@'", aPathDesc
         ];

    id matchWithinRange = [aParseStruct objectForKey:@"matchWithinRange"];
    if ( matchWithinRange ) {
        
        if ( ![matchWithinRange isKindOfClass:[NSDictionary class]] )
            [NSException raise:kExceptionDataScraperConfigValidate
                        format:@"if specified, value for 'matchWithinRange' must be an NSDictionary in '%@'", aPathDesc
             ];
        
        NSString *pathDesc = [NSString stringWithFormat:@"%@.matchWithinRange", aPathDesc];
        
        id startAtPattern = [matchAsArray objectForKey:@"startAtPattern"];
        if ( startAtPattern ) {
            
            if ( ![startAtPattern isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"value for 'startAtPattern' in '%@' is not an NSString", pathDesc
                 ];
            
            NSError *error;
            [NSRegularExpression regularExpressionWithPattern:startAtPattern
                                                      options:NSRegularExpressionDotMatchesLineSeparators
                                                        error:&error
            ];
            
            if ( error )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"Could not compile regular expression '%@' in 'startAtPattern' in '%@'. Error: %@", startAtPattern, pathDesc, [error localizedDescription]
                 ];
        }
        
        id endAtPattern = [matchAsArray objectForKey:@"endAtPattern"];
        if ( endAtPattern ) {
            
            if ( ![endAtPattern isKindOfClass:[NSString class]] )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"value for key 'endAtPattern' in '%@' is not an NSString", pathDesc
                 ];
            
            NSError *error;
            [NSRegularExpression regularExpressionWithPattern:endAtPattern
                                                      options:NSRegularExpressionDotMatchesLineSeparators
                                                        error:&error
            ];
            
            if ( error )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"Could not compile regular expression '%@' in 'endAtPattern' in '%@'. Error: %@", endAtPattern, pathDesc, [error localizedDescription]
                 ];
        }
        
        id startIndexMatchNo = [matchAsArray objectForKey:@"startIndexMatchNo"];
        if ( startIndexMatchNo ) {
            
            if ( ![startIndexMatchNo isKindOfClass:[NSNumber class]] )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"if specified, value for key 'startIndexMatchNo' in '%@' must be an integer NSNumber", pathDesc
                 ];
        }
    }

    for ( NSString *type in @[ @"defaultValues", @"matchValues" ] ) {
        
        id entry;
        if ( ( entry = [aParseStruct objectForKey:type] ) ) {
        
            if ( ![entry isKindOfClass:[NSDictionary class]] )
                [NSException raise:kExceptionDataScraperConfigValidate
                            format:@"if specified, value for key '%@' must be an NSDictionary in '%@'", type, aPathDesc
                 ];
            
            NSString *pathDesc = [NSString stringWithFormat:@"%@.%@", aPathDesc, type];

            for ( id key in [entry allKeys] ) {
            
                if ( ![key isKindOfClass:[NSString class]] )
                    [NSException raise:kExceptionDataScraperConfigValidate
                                format:@"key '%@' in '%@' must be an NSString", key, pathDesc
                     ];
            
                id val = [entry objectForKey:key];
            
                if ( ![val isKindOfClass:[NSString class]] )
                    [NSException raise:kExceptionDataScraperConfigValidate
                                format:@"value for key '%@' must be an NSString in '%@'", key, pathDesc
                     ];
            }
        }
    }
}

@end

