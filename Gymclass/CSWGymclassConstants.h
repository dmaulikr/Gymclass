//
//  GymclassConstants
//  Gymclass
//
//  Created by Eric Colton on 12/29/12.
//  Copyright (c) 2012 Cindy Software. All rights reserved.
//

#ifndef CSWGymclassConstants_h
#define CSWGymclassConstants_h

#define LOG_DEBUG 0

#define BACKEND_SERVICER_DOMAIN @"sites.zenplanner.com"

#define CONFIGURATION_DOMAIN @"cindysoftware.com"

#define BACKEND_CONFIGURATION_DOMAIN CONFIGURATION_DOMAIN

#define USE_BUNDLED_APP_CONFIG 0
#define USE_BUNDLED_SERVICER_CONFIG 0
#define USE_BUNDLED_SIGNUP_CONFIG 0

#define WEB_TIMEOUT_SECS 35

#define APP_CONFIG_URL [NSString stringWithFormat:@"http://%@/config/gymclassConfig.plist", CONFIGURATION_DOMAIN]

#define GYM_CONFIG_URL_PREFIX [NSString stringWithFormat:@"http://%@/config/gyms", CONFIGURATION_DOMAIN]

#define IPHONE_USER_AGENT_STRING @"Mozilla/5.0 (iPhone; CPU iPhone OS 5_1 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9B179 Safari/7534.48.3"

#define kExceptionCoreDataError      @"CORE DATA ERROR"
#define kExceptionInvalidCredentials @"INVALID CREDENTIALS"
#define kExceptionNetworkError       @"NETWORK ERROR"
#define kExceptionAppConfigError     @"APP CONFIG ERROR"
#define kExceptionGymConfigError     @"GYM CONFIG ERROR"
#define kExceptionNoGymId            @"NO GYM ID"
#define kExceptionNoValueAvail       @"NO VALUE AVAILABLE"

#endif
