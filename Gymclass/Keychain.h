//
// Keychain.h
//
// Based on code by Michael Mayo at http://overhrd.com/?p=208
//
// Created by Frank Kim on 1/3/11.
//

#import <Foundation/Foundation.h>

@interface Keychain : NSObject {
}

+ (void)saveString:(NSString *)inputString forKey:(NSString	*)account;
+ (NSString *)getStringForKey:(NSString *)account;
+ (void)deleteStringForKey:(NSString *)account;
@end


//File: KeychainWrapper.h
#import <UIKit/UIKit.h>

@interface KeychainWrapper : NSObject {}

+ (NSString *) getPasswordForUsername: (NSString *) username andServiceName: (NSString *) serviceName error: (NSError **) error;
+ (BOOL) storeUsername: (NSString *) username andPassword: (NSString *) password forServiceName: (NSString *) serviceName updateExisting: (BOOL) updateExisting error: (NSError **) error;
+ (BOOL) deleteItemForUsername: (NSString *) username andServiceName: (NSString *) serviceName error: (NSError **) error;

@end

