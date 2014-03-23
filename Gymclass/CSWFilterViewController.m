//
//  CSWFilterViewController.m
//  Gymclass
//
//  Created by Eric Colton on 9/11/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "CSWAppDelegate.h"
#import "CSWPrimaryViewController.h"
#import "CSWFilterViewController.h"
#import "CSWInstructor.h"
#import "CSWLocation.h"

@interface CSWFilterViewController ()
{
    NSArray *_instructors;
    NSArray *_locations;
    NSInteger _selectedSegment;
}

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation CSWFilterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _selectedSegment = 0;
        _activeFilterType = CSWFilterTypeNoFilter;
        _filterInstructor = nil;
        _filterLocation = nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.managedObjectContext = [(CSWAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    
    self.picker.hidden = ( _activeFilterType == CSWFilterTypeNoFilter ) ? TRUE : FALSE;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    self.managedObjectContext = nil;
}

//
#pragma mark instance methods (public)
//

// I couldn't get viewWillAppear to fire, so created this method
-(void)prepareView
{
    self.segControl.selectedSegmentIndex = _selectedSegment;

    _instructors = [CSWInstructor fetchAllInstructorsWithMoc:self.managedObjectContext];
    _locations   = [CSWLocation fetchAllLocationsWithMoc:self.managedObjectContext];
}

-(IBAction)segControlChanged:(id)sender
{
    NSInteger newIndex = [sender selectedSegmentIndex];

    _selectedSegment = newIndex;

    NSInteger goToIndex = -1;
    if ( newIndex == 0 ) {

        if ( _activeFilterType == CSWFilterTypeInstructor || _activeFilterType == CSWFilterTypeLocation ) {
            CATransition *transision = [CATransition animation];
            transision.duration = 0.25;
            transision.type = kCATransitionFade;
            [self.picker.layer addAnimation:transision forKey:nil];
        }

        self.picker.hidden = TRUE;
        self.noFilterSpecifiedLabel.hidden = FALSE;
        
        _activeFilterType = CSWFilterTypeNoFilter;
        
    } else {
        
        if ( _activeFilterType == CSWFilterTypeNoFilter ) {
            CATransition *transision = [CATransition animation];
            transision.duration = 0.25;
            transision.type = kCATransitionFade;
            [self.picker.layer addAnimation:transision forKey:nil];
        }
        
        self.picker.hidden = FALSE;
        self.noFilterSpecifiedLabel.hidden = TRUE;
        
        if ( newIndex == 1 ) {
            
            _activeFilterType = CSWFilterTypeInstructor;

            if ( self.filterInstructor ) {
                goToIndex = [_instructors indexOfObject:self.filterInstructor];
            } else {
                goToIndex = floor( _instructors.count/2 );
                self.filterInstructor = _instructors[goToIndex];
            }
            
        } else if ( newIndex == 2 ) {
            
            _activeFilterType = CSWFilterTypeLocation;

            if ( self.filterLocation ) {
                goToIndex = [_locations indexOfObject:self.filterLocation];
            } else {
                goToIndex = floor( _locations.count/2 );
                self.filterLocation = _locations[goToIndex];
            }
        }
    }
    
    [self.picker reloadComponent:0];

    [self.picker selectRow:goToIndex inComponent:0 animated:YES];
    
    [self pickerView:self.picker didSelectRow:[self.picker selectedRowInComponent:0] inComponent:0];
}

-(IBAction)donePressed:(id)sender
{
    if ( [self.delegate respondsToSelector:@selector(dismissFilterViewController:)] ) {
        [self.delegate dismissFilterViewController:sender];
    }
}

//
#pragma mark UIPickerViewDataSource protocol methods
//
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    NSInteger count;
    if ( _activeFilterType == CSWFilterTypeInstructor ) {
        count = _instructors.count;
    } else if ( _activeFilterType == CSWFilterTypeLocation ) {
        count = _locations.count;
    } else {
        count = 0;
    }
    
    return count;
}

//
#pragma mark UIPickerViewDelegate protocol methods
//
-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 40;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *name;
    if ( _activeFilterType == CSWFilterTypeInstructor ) {
        name = [_instructors[row] displayName];
    } else if ( _activeFilterType == CSWFilterTypeLocation ) {
        name = [_locations[row] displayName];
    }

    return name;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSInteger selectedRow = [self.picker selectedRowInComponent:0];
    
    if ( _activeFilterType == CSWFilterTypeInstructor ) {
        _filterInstructor = _instructors[selectedRow];
    } else if ( _activeFilterType == CSWFilterTypeLocation ) {
        _filterLocation = _locations[selectedRow];
    }
    
    if ( [self.delegate respondsToSelector:@selector(didSpecifyFilterItem)] ) {
        [self.delegate didSpecifyFilterItem];
    }
}



@end
