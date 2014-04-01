//
//  CSWGymSelector.m
//  Gymclass
//
//  Created by ERIC COLTON on 9/22/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import "CSWGymSelector.h"
#import "CSWScheduleStore.h"
#import <QuartzCore/QuartzCore.h>
#import "Flurry.h"

#define kSelectionFormat @"Touch here to pick %@"

@interface CSWGymSelector ()
{
    NSDictionary *_gymConfigs;
    NSArray *_gymKeys;
    NSString *_selectedGymId;
}

@property (strong, nonatomic) CSWScheduleStore *store;

@end

@implementation CSWGymSelector

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _shouldAddNewGym = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

//
#pragma mark accessor methods (private)
//
-(CSWScheduleStore *)store
{
    if ( !_store ) {
        _store = [CSWScheduleStore sharedStore];
    }
    return _store;
}

//
#pragma mark instance methods (public)
//
-(void)prepareView
{
    self.doneButton.enabled = YES;
    
    bool isRefreshing = [self.store fetchConfigForAllGymsWithCompletion:^(bool refreshed, NSDictionary *gymConfigs, NSError *error ) {
        
        if ( error ) {
            
            self.selectedGymId = nil;
            
            NSString *msg = [NSString stringWithFormat:@"Please try again later. %@", error.localizedDescription];

            [Flurry logError:@"Gym Listing Unavailable" message:msg error:error];
            
            [[[UIAlertView alloc] initWithTitle:@"Gym Listing Unavailable"
                                        message:msg
                                       delegate:nil
                              cancelButtonTitle:@"ok"
                              otherButtonTitles:nil] show];
            
            if ( [self.delegate respondsToSelector:@selector(dismissGymSelector:)] ) {
                [self.delegate dismissGymSelector:nil];
            }
            
            return;
        }
        
        if ( gymConfigs ) {
            _gymConfigs = gymConfigs;
            _gymKeys = [_gymConfigs.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        }
        
        if ( refreshed ) {
            [self.picker reloadComponent:0];
            [self.networkIndicator stopAnimating];
        }

        NSInteger index = NSNotFound;
        if ( self.selectedGymId ) {
            index = [_gymKeys indexOfObject:self.selectedGymId]; // may be NSNotFound
        }
        
        if ( !self.selectedGymId || index == NSNotFound ) {
            index = 0;
            self.selectedGymId = _gymKeys[0];
        }
        
        [self.picker selectRow:index inComponent:0 animated:YES];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.doneButton.title = [NSString stringWithFormat:kSelectionFormat, _gymConfigs[self.selectedGymId][@"displayShortName"]];
        }];
    }];
    
    if ( isRefreshing ) {
        [self.networkIndicator startAnimating];
    }
}


-(void)donePressed:(id)sender
{
    self.doneButton.enabled = NO;
    if ( [self.delegate respondsToSelector:@selector(dismissGymSelector:)] ) {
        [self.delegate dismissGymSelector:sender];
    }
}

//
#pragma mark UIPickerViewDataSource
//
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return ( _gymConfigs.allKeys.count == 0 ) ? 0 : _gymConfigs.allKeys.count + 1;
}

//
#pragma mark UIPickerViewDelegate
//
-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 40;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    
    if ( row < _gymConfigs.count ) {
        
        NSString *key = _gymKeys[row];
        return _gymConfigs[key][@"displayShortName"];
        
    } else {
        
        return @"<Add my local gym>";
    }
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if ( row < _gymConfigs.allKeys.count ) {
        
        _shouldAddNewGym = NO;
        
        NSString *gymId = _gymKeys[row];
        self.selectedGymId = gymId;
        self.configForSelectedGymId = _gymConfigs[gymId];
        self.doneButton.title = [NSString stringWithFormat:kSelectionFormat, _gymConfigs[gymId][@"displayShortName"]];
        if ( [self.delegate respondsToSelector:@selector(longNameWasSet:)] ) {
            [self.delegate longNameWasSet:_gymConfigs[gymId][@"displayLongName"]];
        }
        
    } else {
        
        _shouldAddNewGym = YES;

        self.doneButton.title = @"Touch here to add your gym";
        if ( [self.delegate respondsToSelector:@selector(longNameWasSet:)] ) {
            [self.delegate longNameWasSet:@"Add new gym..."];
        }
    }
}

@end
