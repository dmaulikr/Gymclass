//
//  CSWMembership.m
//  Gymclass
//
//  Created by Eric Colton on 11/25/12.
//  Copyright (c) 2012 Cindy Software. All rights reserved.
//

#import "CSWMembership.h"
#import "KeychainItemWrapper.h"
#import "CSWAppDelegate.h"

#define kMemberships @"memberships"
#define kActiveGymId @"activeGymId"

@interface CSWMembership()

-(void)persistLoad;

@end

@implementation CSWMembership

////
#pragma mark class methods
////
+(CSWMembership *)sharedMembership
{
    static CSWMembership *singleton;
    
    if ( !singleton ) {
        singleton = [[super allocWithZone:NULL] init];
        
        NSString *activeGymId = [[NSUserDefaults standardUserDefaults] objectForKey:kActiveGymId];

        if ( activeGymId ) {
            [singleton setContextToGymId:activeGymId];
        }
    }
    return singleton;
}

+(id)allocWithZone:(NSZone *)zone
{
    return [CSWMembership sharedMembership];
}

////
#pragma mark instance methods (public)
////
-(void)setContextToGymId:(NSString *)aGymId
{
    if ( ![self.gymId isEqualToString:aGymId] ) {
        
        @synchronized( self ) {
            [self persistSave];
            _gymId = aGymId;
            [self persistLoad];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:aGymId
                                              forKey:kActiveGymId
    ];
}

-(void)setCredentialsWithUsername:(NSString *)aUsername withPassword:(NSString *)aPassword
{
    NSString *identifier = [NSString stringWithFormat:@"%@.servicerCredentials", self.gymId];
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:identifier accessGroup:nil];
    
    [keychainItem setObject:aUsername forKey:(__bridge id)(kSecAttrAccount)];
    [keychainItem setObject:aPassword forKey:(__bridge id)(kSecValueData)];

    _username = aUsername;
    _password = aPassword;
    
    [self persistSave];
}

-(void)reset
{
    NSDictionary *oldMemberships = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kMemberships];
    if ( oldMemberships ) {
        NSMutableDictionary *newMemberships = [NSMutableDictionary dictionaryWithDictionary:oldMemberships];
        [newMemberships removeObjectForKey:self.gymId];
        [[NSUserDefaults standardUserDefaults] setObject:newMemberships forKey:kMemberships];
    }

    NSString *identifier = [NSString stringWithFormat:@"%@.servicerCredentials", self.gymId];
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:identifier accessGroup:nil];
    [keychainItem resetKeychainItem];
}

-(void)unloadAllConfigurations
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:kMemberships];
    [userDefaults removeObjectForKey:kActiveGymId];
}

-(void)populateWithDict:(NSDictionary *)aDict
{
    for ( NSString *key in aDict.allKeys ) {
        
        NSString *val = aDict[key];
        if ( ![val isKindOfClass:[NSString class]] || [val isEqualToString:@""] )
            continue;

        if ( [key isEqualToString:@"personId"] ) {
            self.personId = val;
        } else if ( [key isEqualToString:@"type"] ) {
            self.type = val;
        } else if ( [key isEqualToString:@"realName"] ) {
            self.realName = val;
        } else if ( [key isEqualToString:@"membershipNo"] ) {
            self.membershipNo = val;
        }
    }

    [self persistSave];
}

////
#pragma mark accessors (private)
////
-(void)persistSave
{
    if ( !self.gymId ) return;
    
    NSMutableDictionary *membershipDict = [[NSMutableDictionary alloc] init];
    if ( self.personId ) [membershipDict setObject:self.personId forKey:@"personId"];
    if ( self.realName ) [membershipDict setObject:self.realName forKey:@"realName"];
    if ( self.type ) [membershipDict setObject:self.type forKey:@"type"];
    if ( self.membershipId ) [membershipDict setObject:self.membershipId forKey:@"membershipId"];
    if ( self.membershipNo ) [membershipDict setObject:self.membershipNo forKey:@"membershipNo"];
    if ( self.loginDesired ) [membershipDict setObject:[NSNumber numberWithBool:self.loginDesired] forKey:@"loginDesired"];

    NSDictionary *oldMemberships = [[NSUserDefaults standardUserDefaults] objectForKey:kMemberships];
    
    NSMutableDictionary *newMemberships;
    if ( oldMemberships ) {
        newMemberships = [NSMutableDictionary dictionaryWithDictionary:oldMemberships];
    } else {
        newMemberships = [[NSMutableDictionary alloc] init];
    }
    
    [newMemberships setObject:membershipDict forKey:self.gymId];
    
    [[NSUserDefaults standardUserDefaults] setObject:newMemberships forKey:kMemberships];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)persistLoad
{
    NSDictionary *membershipDict = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kMemberships]
                                                                            objectForKey:self.gymId
                                    ];
    
    if ( membershipDict ) {
        self.personId = [membershipDict objectForKey:@"personId"];
        self.realName = [membershipDict objectForKey:@"realName"];
        self.type = [membershipDict objectForKey:@"type"];
        self.membershipId = [membershipDict objectForKey:@"membershipId"];
        self.membershipNo = [membershipDict objectForKey:@"membershipNo"];
        self.loginDesired = [[membershipDict objectForKey:@"loginDesired"] boolValue];
    }
    
    NSString *identifier = [NSString stringWithFormat:@"%@.servicerCredentials", self.gymId];
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:identifier accessGroup:nil];
    
    _username = [keychainItem objectForKey:(__bridge id)kSecAttrAccount];
    _password = [keychainItem objectForKey:(__bridge id)kSecValueData];
}

@end
