//
//  GymclassConstants
//  Gymclass
//
//  Created by Eric Colton on 12/29/12.
//  Copyright (c) 2012 Cindy Software. All rights reserved.
//

#ifndef CSWGymclassConstants_h
#define CSWGymclassConstants_h

// comment out this line to use production web-service
//#define USE_DEV_BACKEND

#ifdef USE_DEV_BACKEND
#define CONFIGURATION_DOMAIN @"dev.cindysoftware.com"
#define DEV_BACKEND_MODE YES
#else
#define CONFIGURATION_DOMAIN @"cindysoftware.com"
#define DEV_BACKEND_MODE NO
#endif

#define APP_VERSION_FOR_CONFIG @"1.1"
#define APP_VERSION_FOR_ANALYTICS @"1.1.11"

#define LOG_DEBUG 0

//
// production Flurry API key
// WARNING: ONLY ENABLE FOR *TRUE* production!!
//#define FLURRY_API_KEY @"4JT87NRRH9JWJNNKPJPJ"

//dev API key
#define FLURRY_API_KEY @"CZ68D4PWS9Q5BK2BBDM7"

#define BACKEND_SERVICER_DOMAIN @"sites.zenplanner.com"

#define BACKEND_CONFIGURATION_DOMAIN CONFIGURATION_DOMAIN

#define USE_BUNDLED_APP_CONFIG 0
#define USE_BUNDLED_SERVICER_CONFIG 0
#define USE_BUNDLED_SIGNUP_CONFIG 0

#define WEB_TIMEOUT_SECS 35

#define APP_CONFIG_URL [NSString stringWithFormat:@"http://%@/config/by_version/%@/gymclassConfig.plist", CONFIGURATION_DOMAIN, APP_VERSION_FOR_CONFIG]

#define GYM_CONFIG_URL_PREFIX [NSString stringWithFormat:@"http://%@/config/gyms/by_version/%@/", CONFIGURATION_DOMAIN, APP_VERSION_FOR_CONFIG]

#define IPHONE_USER_AGENT_STRING @"Mozilla/5.0 (iPhone; CPU iPhone OS 5_1 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9B179 Safari/7534.48.3"

#define kExceptionCoreDataError      @"CORE DATA ERROR"
#define kExceptionInvalidCredentials @"INVALID CREDENTIALS"
#define kExceptionNetworkError       @"NETWORK ERROR"
#define kExceptionAppConfigError     @"APP CONFIG ERROR"
#define kExceptionGymConfigError     @"GYM CONFIG ERROR"
#define kExceptionNoGymId            @"NO GYM ID"
#define kExceptionNoValueAvail       @"NO VALUE AVAILABLE"

// Ananlytics
#define kLogoutPressed       @"logoutPressed"
#define kLoginSkipped        @"loginSkipped"
#define kLoginSuccess        @"loginSuccess"
#define kRefreshPressed      @"refreshPressed"
#define kLoginBadCredentials @"loginBadCredentials"

#define kDidVisitAddGymPage  @"didVisitAddGymPage"
#define kDidFollowAddGymLink @"didFollowAddGymLink"

#define kDidPressContactButton @"didPressContactButton"
#define kDidStartContactEmail  @"didStartContactEmail"

#define kGotoPrevDay    @"gotoPrevDay"
#define kGotoNextDay    @"gotoNextDay"
#define kGotoLoginPage  @"gotoLoginPage"
#define kGotoNowPressed @"gotoNowPressed"
#define kWodViewed      @"wodViewed"
#define kFilterPressed  @"filterPressed"

#define kFetchingMembershipId @"fetchingMembershipId"

#define kRefreshedReservationsForDay @"refreshedReservationsForDay"
#define kUserLoggingIn @"userLoggingIn"

#define kCacheNeverCached @"cacheNeverCached"
#define kfreshData @"freshData"
#define kStaleData @"staleData"

#define kCouldNotUndoSignup         @"couldNotUndoSignup"
#define kUnexpectedServicerResponse @"unexpectedServicerResponse"
#define kLoginError                 @"loginError"
#define kCredentialsError           @"credentialsError"

#define kCouldNotContactGym         @"couldNotContactGym"

#define kWeekScheduleUnavailable    @"weekScheduleUnavailable"
#define kSpotsRemainingUnavailable  @"spotsRemainingUnavailable"
#define kReservationsUnavailable    @"reservationsUnavailable"

#define kAttemptToSignUpNotLoggedIn @"attemptToSignUpNotLoggedIn"
#define kAttemptToSignUpTooFarForward @"attemptToSignUpTooFarForward"

#define kRequestedLateSignup @"requestedLateSignup"
#define kCantCancelLateSignup @"cantCancelLateSignup"

#define kWaitlistFull @"Waitlist Full"


#endif
