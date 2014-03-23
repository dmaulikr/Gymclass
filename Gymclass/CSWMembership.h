//
//  CSWMembership.h
//  Gymclass
//
//  Created by Eric Colton on 11/25/12.
//  Copyright (c) 2012 Cindy Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSWMembership :NSObject

+(CSWMembership *)sharedMembership;

-(void)setContextToGymId:(NSString *)aGymId;

-(void)setCredentialsWithUsername:(NSString *)aUsername withPassword:(NSString *)aPassword;

-(void)populateWithDict:(NSDictionary *)aDict;
-(void)persistSave;
-(void)unloadAllConfigurations;
-(void)reset;

@property (atomic, readonly) NSString *gymId;
@property (atomic, strong) NSString *membershipId;

@property (nonatomic, readonly) NSString *username;
@property (nonatomic, readonly) NSString *password;
@property (nonatomic, strong) NSString *personId;
@property (nonatomic, strong) NSString *membershipNo;
@property (nonatomic, strong) NSString *realName;
@property (nonatomic, strong) NSString *type;
@property (nonatomic) bool loginDesired;


@end
