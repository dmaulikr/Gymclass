//
//  CSWAppDelegate.m
//  Gymclass
//
//  Created by Eric Colton on 11/21/12.
//  Copyright (c) 2012 Cindy Software. All rights reserved.
//

#import "CSWAppDelegate.h"
#import "CSWWorkout.h"
#import "CSWScheduleStore.h"
#import "KeychainItemWrapper.h"
#import "CSWPrimaryViewController.h"
#import "CSWLoginViewController.h"

@interface CSWAppDelegate()
{
    CSWPrimaryViewController *_primaryViewController;
    CSWLoginViewController *_loginViewController;
    CSWMembership *_membership;
    CSWScheduleStore *_store;
    UIActivityIndicatorView *_indicator;
    UINavigationController *_nav;
}

@end

@implementation CSWAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSSet *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    _membership = [CSWMembership sharedMembership];
    _store = [CSWScheduleStore sharedStore];

    bool gymIdIsSet = !!_membership.gymId;

    _loginViewController = [[CSWLoginViewController alloc] initForcingGymSelection:!gymIdIsSet];
    
    _nav = [[UINavigationController alloc] initWithRootViewController:_loginViewController];
    [_nav.toolbar setBarStyle:UIBarStyleBlackOpaque];
    [_nav.navigationBar setBarStyle:UIBarStyleBlackOpaque];

    if ( gymIdIsSet ) {
        
        UIViewController *blackVC = [[UIViewController alloc] init];
        blackVC.navigationItem.hidesBackButton = YES;
        
        blackVC.view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"loginBackground"]];
        
        _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _indicator.hidesWhenStopped = YES;
        _indicator.frame = CGRectMake( CGRectGetMidX(blackVC.view.frame) - _indicator.frame.size.width/2.0
                                     ,CGRectGetMidY(blackVC.view.frame) - _indicator.frame.size.height * 2.0 // set indicator above center
                                     ,_indicator.frame.size.width
                                     ,_indicator.frame.size.height
                                    );
        
        [_indicator startAnimating];
        [blackVC.view addSubview:_indicator];
            
        [_nav pushViewController:blackVC animated:NO];
        
        NSError *error;
        
        @try {
            
            [_store setupForGymId:_membership.gymId error:&error];
            [self didSetupGymId];
            
        } @catch ( NSException *e ) {
            
            // Gym seems to have been removed!
            [[[UIAlertView alloc] initWithTitle:@"Bad Gym Setup"
                                        message:e.reason
                                       delegate:nil
                              cancelButtonTitle:@"ok"
                              otherButtonTitles:nil
              ] show];
            
            [_membership setContextToGymId:nil];
            [_nav popViewControllerAnimated:YES];
        }
    }
    
    self.window.rootViewController = _nav;
    [self.window makeKeyAndVisible];
    
    return YES;
}

-(void)didSetupGymId
{
    if ( _membership.loginDesired && _membership.username && _membership.password ) {
            
        [_store loginUserForcefully:NO withCompletion:^(NSError *error) {
                
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    
                [_indicator stopAnimating];
                [_nav popViewControllerAnimated:NO]; // pop blackVC
                
                if ( error ) {
                        
                    NSString *msg = [NSString stringWithFormat:@"Unable to login. %@", [error localizedDescription]];
                    
                    [[[UIAlertView alloc] initWithTitle:@"Login Error"
                                                message:msg
                                               delegate:nil
                                      cancelButtonTitle:@"ok"
                                      otherButtonTitles:nil
                      ] show];
                    
                } else {
                    
                    if ( _store.isLoggedIn ) {
                        
                        _primaryViewController = [CSWPrimaryViewController new];
                        [_nav pushViewController:_primaryViewController animated:NO];
                        
                    } else {
                        
                        [[[UIAlertView alloc] initWithTitle:@"Credentials Error"
                                                    message:@"Unable to login with specified credentials."
                                                   delegate:nil
                                          cancelButtonTitle:@"ok"
                                          otherButtonTitles:nil]
                         show];
                    }
                }
            }];
        }];

    } else {
         
        [_indicator stopAnimating];
        [_nav popViewControllerAnimated:NO]; // pop blackVC
            
        _primaryViewController = [CSWPrimaryViewController new];
        [_nav pushViewController:_primaryViewController animated:FALSE];
    }
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    static bool appIsLaunching = true;
    if ( appIsLaunching ) {
        
        appIsLaunching = false;
        
    } else if ( _primaryViewController.isViewLoaded && _primaryViewController.view.window ) {
        
        void (^completionBlock)(NSError *) = ^(NSError *error) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                if ( error ) {
                    
                    [[[UIAlertView alloc] initWithTitle:@"Could not contact Gym"
                                                message:error.localizedDescription
                                               delegate:nil
                                      cancelButtonTitle:@"ok"
                                      otherButtonTitles:nil
                      ] show];

                } else {
                    
                    [_primaryViewController setSelectedTimeToNow];
                    [_primaryViewController focusOnSelectedDateAndTime:true];
                }
            }];
        };
        
        if ( [CSWMembership sharedMembership].loginDesired ) {
            
            [[CSWScheduleStore sharedStore] loginUserForcefully:YES withCompletion:completionBlock];
            
        } else {
            
            completionBlock(nil);
        }
    }
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Gymclass" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Gymclass.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption : @YES
                              ,NSInferMappingModelAutomaticallyOption       : @YES
                             };
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:options
                                                           error:&error
          ]
       ) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory
// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end