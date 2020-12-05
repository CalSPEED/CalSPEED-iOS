/*
Copyright (c) 2020, California State University Monterey Bay (CSUMB).
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    1. Redistributions of source code must retain the above copyright notice,
       this list of conditions and the following disclaimer.
    2. Redistributions in binary form must reproduce the above
           copyright notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
    3. Neither the name of the CPUC, CSU Monterey Bay, nor the names of
       its contributors may be used to endorse or promote products derived from
       this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
#import "ViewController.h"
#import "AddresslistViewController.h"
#import "AboutViewController.h"
#import "HUD.h"
#import "predictedMobileViewController.h"
#import "advertisedMobileViewController.h"
#import "advertisedSatelliteViewController.h"
#import "advertisedFixedViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "Reachability.h"
#import "CalSPEEDLocationManager.h"
#import "AboutViewController.h"


//CLLocationManager *locationManager;

@implementation ViewController

@synthesize mapView,navItem;

/*
    viewDidLoad sets boundries and initializes all views. Also formats
 */

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [self.navigationItem setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Map" style:UIBarButtonItemStylePlain target:nil action:nil]];
    //back chevron color
    self.navigationItem.backBarButtonItem.tintColor = [UIColor colorWithRed:10/255.0 green:134/255.0 blue:191/255.0 alpha:1.0];

    //[tab.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -10)];
	// Do any additional setup after loading the view, typically from a nib.
    
    // setup this class as delegate for mapview
    [self.mapView setDelegate:self];
    // initialze gesture recognizer to hangle touching map events
    lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)]; //long tap recognizer
    lpgr.minimumPressDuration = 0.5; //set duration of touch
    lpgr.numberOfTouchesRequired = 1;//one touch
    [mapView addGestureRecognizer:lpgr];//adds the gesture to mapView
    mapView.userTrackingMode = MKUserTrackingModeNone; //?
    check = false;
    searchBar = false;
    zipCode = false;
    //setup location manag9089er to track current position
    firsttime = true;
    usersLocation = [[CLLocation alloc] init];
    _locationManager = [CalSPEEDLocationManager getSharedLocationManager];
    [_locationManager setDelegate:self];
    [_locationManager startUpdatingLocation];
    
    //mapView.showsUserLocation = YES;
    
    locationAddress = [[NSString alloc] init];
    
    tabBarController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"tabController"];//[[UITabBarController alloc]init];
    //storyboard tabs
    //advMobileMeasurementsVC = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"advertisedMobileViewController"];
    predMobileMeasurementsVC = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"predictedMobileViewController"];
    //advSatelliteMeasurementVC = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"advertisedSatelliteViewController"];
    advFixedMeasurementVC = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil]instantiateViewControllerWithIdentifier:@"advertisedFixedViewController"];
    tabBarController.viewControllers = [NSArray arrayWithObjects: predMobileMeasurementsVC, nil];//[NSArray arrayWithObjects:advMobileMeasurementsVC, predMobileMeasurementsVC, advSatelliteMeasurementVC, nil];
    
    //Searchbar and About Button GUI elements
    UIView *remainingSearchSpace = [[UIView alloc]initWithFrame:CGRectMake(265, 0, (self.view.frame.size.width-260), 44.0)];
    infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *img =[UIImage imageNamed:@"info"];
    [infoButton setImage:img forState:UIControlStateNormal];
    [infoButton addTarget:self action:@selector(infoPushed:) forControlEvents:UIControlEventTouchUpInside];
    
    infoButton.frame = CGRectMake(5, 5, 23, 23);
    [infoButton setShowsTouchWhenHighlighted:YES];
    infoButton.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Top_Bar_Color.png"]];
    UIBarButtonItem *infroButtonItem  = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    
    //add the gradient specified by Micah
    //UIColor *topColor = [UIColor colorWithRed:1.0/255.0 green:149.0/255.0 blue:201.0/255.0 alpha:1.0];
    //UIColor *bottomColor = [UIColor colorWithRed:32.0/255.0 green:65.0/255.0 blue:155.0/255.0 alpha:1.0];
    UIColor *color = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Top_Bar_Color.png"]];
    //CAGradientLayer *gradient = [CAGradientLayer layer];
    //gradient.frame = remainingSearchSpace.bounds;
    //gradient.colors = [NSArray arrayWithObjects:(id)[topColor CGColor], (id)[bottomColor CGColor], nil];
    
    //CAGradientLayer *gradientTwo = [CAGradientLayer layer];
    //CAGradientLayer *gradientThree = [CAGradientLayer layer];
    //CAGradientLayer *gradientFour = [CAGradientLayer layer];
    //[remainingSearchSpace.layer insertSublayer:gradientTwo atIndex:0];
    remainingSearchSpace.backgroundColor = color;
   /* gradientTwo.colors = [NSArray arrayWithObjects:(id)[topColor CGColor], (id)[bottomColor CGColor], nil];
    gradientThree.colors = [NSArray arrayWithObjects:(id)[topColor CGColor], (id)[bottomColor CGColor], nil];
    gradientFour.colors = [NSArray arrayWithObjects:(id)[topColor CGColor], (id)[bottomColor CGColor], nil];*/
    
    if (@available(iOS 11, *)) //check to see if newer version of iOS
        searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(-3, 0, 260, 44)];
    else
        searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(-3, 22, 260, 44)];
    searchBar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Top_Bar_Color.png"]];
   // gradient.frame = searchBar.bounds;
    
    //End Searchbar and About Button GUI elements
    
    if([[[UIDevice currentDevice] systemVersion]floatValue] >= 7)
    {
        searchBar.searchBarStyle =UISearchBarStyleMinimal;
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Top_Bar_Color.png"]];
        self.navigationController.navigationBar.tintColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"gradientNavBarImage.png"]];
        searchBar.barTintColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"gradientNavBarImage.png"]];
        searchBar.translucent = NO;
        searchBar.tintColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"gradientNavBarImage.png"]];
        
        [[UITextField  appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor blackColor]];
        //This is to fix the problem of the text being black while editing is in progress, for better color contrast with the dark blue. -Alex
    }
    for( UIView *subview in searchBar.subviews )
    {
        if( [subview isKindOfClass:NSClassFromString( @"UISearchBarBackground" )] )
        {
            [subview setAlpha:0.0];
            break;
        }
    }
    //[searchBar.layer insertSublayer:gradientTwo atIndex:0];
    searchBar.delegate = self;
    self.navigationController.navigationBarHidden = NO;
    UIView *searchBarEverything = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, searchBar.frame.size.width+remainingSearchSpace.frame.size.width, searchBar.frame.size.height+remainingSearchSpace.frame.size.height)];
    [searchBarEverything addSubview:searchBar];
    //searchBarEverything.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    self.navigationItem.titleView = searchBarEverything;
    self.navigationItem.rightBarButtonItem = infroButtonItem;
    arrayOfAddresses = [[NSMutableArray alloc] init];
    arrayOfCoordinates = [[NSMutableArray alloc] init];
    arrayOfAttributes = [[NSMutableArray alloc] init];
    returnData = nil;
    jsonObject  = nil;
    
    pa = [[MKPointAnnotation alloc] init];
    
    predictedMeasurements = [[NSMutableArray alloc] init];
    advertisedMeasurements = [[NSArray alloc] init];
    fPredictMeasurments = [[NSArray alloc] init];
    advertisedMobileMeasurements = [[NSMutableArray alloc]init];
    advertisedSatelliteMeasurements = [[NSMutableArray alloc]init];
    advertisedFixedMeasurements = [[NSMutableArray alloc]init];
    showInfo = true;
    searchBar.placeholder = @"Search Address";
    if([[[UIDevice currentDevice] systemVersion]floatValue] >= 7)
    {
        [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil]setTextColor:[UIColor blackColor]];
        [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil]setTintColor:[UIColor blackColor]];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"ShowAgain"] == Nil)
    {
        [self showInstructions];
    }
    else{
        showInfo = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowAgain"];
        if (showInfo) {
            [self showInstructions];
        }
    }
}

- (void)didReceiveMemoryWarning
{

    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Is called to show initial instructions
-(void) showInstructions
{
    if([[[UIDevice currentDevice] systemVersion]floatValue] >= 7)
    {
        UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:@"Welcome to CalBroadband" message:@"1. Press and hold a location on the map or type an address at the search bar. \n 2. Tap the \"i\" button next to address selected.  \n 3. View upstream and downstream speeds of carriers. \n" delegate:self cancelButtonTitle:@"Don't Show Again" otherButtonTitles:@"OK",nil];
        [successAlert show];
    }
    else{
        UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:@"Welcome to CalBroadband" message:@" \n \n \n \n \n \n \n \n \n" delegate:self cancelButtonTitle:@"Don't Show Again" otherButtonTitles:@"OK",nil];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 50, 250, 250)];
        
        NSString *path = [[NSString alloc] initWithString:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"UIAlertInfo1.png"]];
        //Add a comment to this line
        UIImage *bkgImg = [[UIImage alloc] initWithContentsOfFile:path];
        [imageView setImage:bkgImg];
        
        [successAlert addSubview:imageView];
        [successAlert show];
    }
}

//checks to see if there is an internet connection, otherwise display alert
- (BOOL) connectedToNetwork
{
    
	Reachability *r = [Reachability reachabilityWithHostName:@"www.google.com"];
	NetworkStatus internetStatus = [r currentReachabilityStatus];
	BOOL internet;
	if ((internetStatus != ReachableViaWiFi) && (internetStatus != ReachableViaWWAN)) {
		internet = NO;
	} else {
		internet = YES;
	}
	return internet;
}

//handles buttons pressed in alert. if user does not want it to be shown again then it will store that info
-(void) alertView: (UIAlertView *) alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if([title isEqualToString:@"Ok"])
    {
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"ShowAgain"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else if([title isEqualToString:@"Don't Show Again"])
    {
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"ShowAgain"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark - mapview delegate methods

// sets initial region when map is loaded
- (void)mapView:(MKMapView *)mView didUpdateUserLocation:(MKUserLocation *)userLocation
{
   // if ([[NSUserDefaults standardUserDefaults] objectForKey:@"FirstRun"] == true)
   // {
        
    //}
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        if(previousAddress != locationAddress) //If this is the same location we already have loaded, there is no need to reload it.
        {
                
            
            MKAnnotationView *annotationView = [mapView viewForAnnotation:userLocation];
            UIButton *resultUButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            [resultUButton addTarget:self action:@selector(resultUButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            annotationView.rightCalloutAccessoryView = resultUButton;
            //annotationView.leftCalloutAccessoryView = resultUButton;
            [userLocation setTitle: @"Ipad"];
            //[userLocation setTitle: @"Subsequent time running: "];
            
            //[locationManager stopUpdatingLocation];
            
            previousAddress = locationAddress;
        }
    }
    else
    {
        if(previousAddress == NULL)
        {
            MKAnnotationView *annotationView = [mapView viewForAnnotation:userLocation];
            UIButton *resultUButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            [resultUButton addTarget:self action:@selector(resultUButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            annotationView.rightCalloutAccessoryView = resultUButton;
            annotationView.canShowCallout = true;
        
            //annotationView.leftCalloutAccessoryView = resultUButton;
        
            [userLocation setTitle: @"Loading data..."];
            //[userLocation setTitle: @"Current Location: "];

        
            // annotationView.selected = true;
            //[annotationView setSelected:true];
            //[annotationView setDragState:true];
            //[annotationView setSelected:false];
            annotationView.highlighted = true;
            // annotationView.selected = true;
            //[annotationView setSelected:true];
            [annotationView setDragState:true];
            //annotationView.selected = true;
            //[annotationView setSelected:false];

            //[locationManager stopUpdatingLocation];

        
            previousAddress = @"First run";
        
        
            [annotationView setDragState:false];
            annotationView.highlighted = false;
            //self.mapView.showsUserLocation;
        
    
        }
        else
        {
            if(previousAddress != locationAddress) //If this is the same location we already have loaded, there is no need to reload it.
            {
        
                MKAnnotationView *annotationView = [mapView viewForAnnotation:userLocation];
                UIButton *resultUButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
                [resultUButton addTarget:self action:@selector(resultUButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                annotationView.rightCalloutAccessoryView = resultUButton;
                //annotationView.leftCalloutAccessoryView = resultUButton;
                [userLocation setTitle: @"Current Location: "];
                //[userLocation setTitle: @"Subsequent time running: "];

                //[locationManager stopUpdatingLocation];
        
                previousAddress = locationAddress;
            }
            else
            {
                MKAnnotationView *annotationView = [mapView viewForAnnotation:userLocation];
                UIButton *resultUButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
                [resultUButton addTarget:self action:@selector(resultUButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                annotationView.rightCalloutAccessoryView = resultUButton;
                //annotationView.leftCalloutAccessoryView = resultUButton;
                [userLocation setTitle: @"Current Location: "];
                //[userLocation setTitle: @"Subsequent time running: "];
                
                //[locationManager stopUpdatingLocation];
                
                previousAddress = locationAddress;
                
                
            }
        }
    }
}




- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id<MKAnnotation>)annotation
{
    //Code for placing the red pin annotations
    
  
    // This method is ran after annotation is created to link with annotationView
    if (![annotation isKindOfClass:[MKUserLocation class]]){
        // for placed annotation
        MKPinAnnotationView *pav = nil;
        pav = (MKPinAnnotationView *)[mv dequeueReusableAnnotationViewWithIdentifier:@"Pin"];
        if (!pav) {
           pav = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Pin"]; 
        }
        pav.animatesDrop = TRUE;
        UIButton *resultButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [resultButton addTarget:self action:@selector(resultButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        pav.rightCalloutAccessoryView = resultButton;
        //pav.leftCalloutAccessoryView = resultButton;
        [pav setEnabled:YES];
        [pav setCanShowCallout:YES];
        return pav;
    }
    else {        
        // for current location
        return nil;
    }
    
}

//called when user presses the i button or arrow for User Location Blue Pin
-(void) resultUButtonPressed: (UIButton *)sender
{
    locationAddress = UlocationAddress;
    [self removeAllPinsButUserLocation];
    [HUD showUIBlockingIndicatorWithText:@"DOWNLOADING DATA"];
    [self queryRESTforCoordConverstion:usersLocation.coordinate.longitude otherCoord:usersLocation.coordinate.latitude];
}

//called when user presses the i button or arrow for dropped location Red Pin
-(void) resultButtonPressed: (UIButton *)sender
{
  
    if (check == true) {
        [HUD showUIBlockingIndicatorWithText:@"DOWNLOADING DATA"];
        [self queryRESTforCoordConverstion:pa.coordinate.longitude otherCoord:pa.coordinate.latitude];
       // [mapView setShowsUserLocation:NO];
        [mapView deselectAnnotation:pa animated:NO];
        [mapView removeGestureRecognizer:lpgr];
    }
    else{
        [mapView deselectAnnotation:pa animated:NO];

    }
}

//called when about button is selected
-(void) infoPushed: (UIButton *) sender
{
    AboutViewController *aboutViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AboutViewController"];
    aboutViewController.willDisplayMapViewText = true;
    [self.navigationController pushViewController:aboutViewController animated:true];
}

//gets formatted address at pin location to display on the pin
-(NSString *) getFormattedAddress:(NSMutableDictionary *) address
{
    int i =0;
 
        NSMutableString *streetAddress = [[NSMutableString alloc] init];
        NSMutableArray *AAddress = [[NSMutableArray alloc] initWithArray:[address valueForKey:@"FormattedAddressLines"]];
        for(i=0;i<([AAddress count]-1);i++)
        {
            [streetAddress appendString:[AAddress objectAtIndex:i]];
            [streetAddress appendString:@" "];
        }
        
        return streetAddress;
    
}

//checks to make sure that location is within bounds of california
-(BOOL)checkSelectedLocation: (CLLocation *) location
{
 
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Location" message:@"This location is not in California" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    UIAlertView *eror = [[UIAlertView alloc] initWithTitle:@"Location Unavailable" message:@"Unable to find this location. \n There could be a connection error." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init]; //to find address to pin
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        bool shown = false;
        if (error){
            NSLog(@"Geocode failed with error: %@", error);
            [eror show];
            shown = true;
            return;
        }
        if([placemarks count] > 0)
        {
            CLPlacemark *nPlace = [placemarks objectAtIndex:0];
            NSMutableDictionary  *address = [[NSMutableDictionary alloc] initWithDictionary:nPlace.addressDictionary];
            
            //catch-all check for california
            if ([[address valueForKey:@"State"] characterAtIndex:0] == 'c' || [[address valueForKey:@"State"] characterAtIndex:0] == 'C') //this check should hopefully be a catch-all for california, including 'California', 'CA','ca', and other variations Apple might change it to -Alex
            {
                if ([[address valueForKey:@"State"] characterAtIndex:1] == 'a' || [[address valueForKey:@"State"] characterAtIndex:1] == 'A')
                {
                    self->locationAddress = [self getFormattedAddress:address];
                    if(self->searchbar == false)
                    {
                        [self->pa setSubtitle:self->locationAddress];
                    }
                    self->check = true;
                }
            }
            //if ([[address valueForKey:@"State"] isEqualToString:@"CA"])//ios 7
            //{
                
            //    locationAddress = [self getFormattedAddress:address];
            //    if(searchbar == false)
            //    {
            //        [pa setSubtitle:locationAddress];
            //    }
            //    check = true;
            //}
           // else if ([[address valueForKey:@"State"] isEqualToString:@"California"])//ios 6
            //{
            //    locationAddress = [self getFormattedAddress:address];
            //    if(searchbar == false)
            //    {
            //        [pa setSubtitle:locationAddress];
            //    }
            //    check = true;
           // }
            else
            {
                if(shown == false)
                {
                    [alert show];
                }
                [self->mapView removeAnnotation:self->pa];
            }
        }
        
    }];    
    return check;

}

//checks to see if user location is within bounds of california
-(BOOL)checkUserLocation: (CLLocation *) location
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Location" message:@"This location is not in California" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    UIAlertView *eror = [[UIAlertView alloc] initWithTitle:@"Location Unavailable" message:@"Unable to find this location. This could be a result of no data connection." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init]; //to find address to pin
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        bool shown = false;
        if (error){
            NSLog(@"Geocode failed with error: %@", error);
            [eror show];
            shown = true;
            return;
        }
        if([placemarks count] > 0)
        {
            CLPlacemark *nPlace = [placemarks objectAtIndex:0];
            NSMutableDictionary  *address = [[NSMutableDictionary alloc] initWithDictionary:nPlace.addressDictionary];
            NSLog(@"%@", [address valueForKey:@"State"]);
            
            if ([[address valueForKey:@"State"] characterAtIndex:0] == 'c' || [[address valueForKey:@"State"] characterAtIndex:0] == 'C') //this check should hopefully be a catch-all for california, including 'California', 'CA','ca', and other variations Apple might change it to -Alex
            {
                if ([[address valueForKey:@"State"] characterAtIndex:1] == 'a' || [[address valueForKey:@"State"] characterAtIndex:1] == 'A')
                {
                    self->UlocationAddress = [self getFormattedAddress:address]; //shows in alert when selecting blue dot
                    [self->mapView.userLocation setSubtitle: self->UlocationAddress];
                    self->check = true;
                    
                    // This block added to take care of a GPS signal that doesn't move
                    self->usersLocation = location;
                    self->pa.coordinate = location.coordinate;
                    self->locationAddress = self->UlocationAddress;
                    NSLog(@"Location addres: %@", self->locationAddress);
                    NSLog(@"Location coords: %f %f", self->usersLocation.coordinate.longitude,self->usersLocation.coordinate.latitude);
                    MKAnnotationView *annotationView = [self->mapView viewForAnnotation:self->mapView.userLocation];
                    UIButton *resultButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
                    [resultButton addTarget:self action:@selector(resultButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                    annotationView.rightCalloutAccessoryView = resultButton;
                    [annotationView setEnabled:YES];
                    [annotationView setCanShowCallout:YES];
                    annotationView.canShowCallout = true;
                    annotationView.highlighted = true;
                    [annotationView setDragState:true];
                    [self->mapView.userLocation setTitle: @"Current Location: "];
                    // This block added to take care of a GPS signal that doesn't move
                    
                }
            }
            
            
         //   if ([[address valueForKey:@"State"] isEqualToString:@"CA"])
         //   {
         //      UlocationAddress = [self getFormattedAddress:address];
          //      [mapView.userLocation setSubtitle: UlocationAddress];
          //      check = true;
          //  }
          ///  else if ([[address valueForKey:@"State"] isEqualToString:@"California"])
          //  {
          //      UlocationAddress = [self getFormattedAddress:address];
          //      [mapView.userLocation setSubtitle: UlocationAddress];
          //      check = true;
          //  }

            else
            {
                if(shown == false)
                {
                    [alert show];
                }
            }
        }
        
    }];
    return check;
    
}

- (void)mapView:(MKMapView *)mv didSelectAnnotationView:(MKAnnotationView *)view
{
    [predictedMeasurements removeAllObjects];
    advertisedMeasurements=nil;
    advertisedMeasurements = [NSArray alloc];
    fPredictMeasurments = nil;
    fPredictMeasurments = [NSArray alloc];
    [advertisedMobileMeasurements removeAllObjects];
    [advertisedSatelliteMeasurements removeAllObjects];
    [advertisedFixedMeasurements removeAllObjects];
    if (![self connectedToNetwork]) {
        [mapView removeAnnotation:pa];
    }else{
        if (![view.annotation isKindOfClass:[MKUserLocation class]]) {
            
        }
        else if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
            CLLocation *location = [[CLLocation alloc] initWithLatitude:(usersLocation.coordinate.latitude) longitude:(usersLocation.coordinate.longitude)];
            if ([self checkUserLocation:location]) {
                //[self queryRESTforCoordConverstion:usersLocation.coordinate.longitude otherCoord:usersLocation.coordinate.latitude];
            }
        }
    }

}

#pragma mark - locationManager delegate methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {

    
    if (firsttime) {
        usersLocation = [locations lastObject];
        [self checkSelectedLocation:usersLocation];
        MKCoordinateRegion region;
        MKCoordinateSpan span;
        span.latitudeDelta = 0.05;
        span.longitudeDelta = 0.05;
        region.span = span;
        region.center = [usersLocation coordinate];
        [mapView setRegion:region animated:NO];
        firsttime = false;
        //[locationManager stopUpdatingLocation];
        //[locationManager stopMonitoringSignificantLocationChanges];
   }
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {

    NSLog(@"%@",error);
    //if (firsttime) {
        UIAlertView *error2 = [[UIAlertView alloc]initWithTitle:@"Location Unavailable" message:@"Could Not Accurately Find Location. Please make sure Location is enabled for the CalSPEED app in the settings." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        MKCoordinateRegion region;
        MKCoordinateSpan span;
        span.latitudeDelta = 0.005;
        span.longitudeDelta = 0.005;
        region.span = span;
        CLLocation *seaside = [[CLLocation alloc] initWithLatitude:[@"36.622141" floatValue] longitude:[@"-121.820011" floatValue]];
        region.center = seaside.coordinate;
        [mapView setRegion:region animated:YES];
        firsttime = false;
        //[locationManager stopUpdatingLocation];
        //[locationManager stopMonitoringSignificantLocationChanges];
        [error2 show];
        [HUD hideUIBlockingIndicator];
    //}
}

#pragma mark - selector method for UILongPressGestureRecognizer

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer
{

    searchbar = false;
    CGPoint touchPoint = [gestureRecognizer locationInView:mapView];
    CLLocationCoordinate2D touchMapCoord = [mapView convertPoint:touchPoint toCoordinateFromView:mapView];
    CLLocation *location = [[CLLocation alloc]initWithLatitude:touchMapCoord.latitude longitude:touchMapCoord.longitude];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        locationAddress = @" ";
        if ([self checkSelectedLocation:location])
        {
            //first remove current annotation
            [self removeAllPinsButUserLocation];
            //add new annotation where touched
            pa.coordinate = touchMapCoord;
            [pa setTitle:@"Selected Location"];
            //[pa setSubtitle:locationAddress];
            locationAddress = @" ";
            [mapView addAnnotation:pa];
            [mapView selectAnnotation:pa animated:YES];
        }
    }
}

#pragma mark - search bar delegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)tsearchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
    [[UIBarButtonItem appearanceWhenContainedIn: [UISearchBar class], nil] setTintColor:[UIColor blackColor]];
    [self.mapView setUserInteractionEnabled:NO];
    self.mapView.scrollEnabled = NO;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)tsearchBar {
    searchBar.text = @"";
    
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    [self.mapView setUserInteractionEnabled:YES];
    self.mapView.scrollEnabled = YES;
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)tsearchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    [self searchForEnteredAddress:searchBar.text];
    //Start of search for entered address in the searchbar.
    //
    //
    //
    //
    //
    //
}

#pragma mark - search methods

-(void)searchForEnteredAddress:(NSString*)address {
    jsonObject = nil;
    // Remove previous search
    [arrayOfAddresses removeAllObjects];
    [arrayOfCoordinates removeAllObjects];
    [arrayOfAttributes removeAllObjects];
    [self.mapView setUserInteractionEnabled:NO];
    
    //start testing being done by Freddy
    
//    CLGeocoder *geocoder = [[CLGeocoder alloc]init];
//    [geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error)
//     {
//         if (error) {
//             UIAlertView *error = [[UIAlertView alloc]initWithTitle:@"Location Error" message:@"Unable to find location." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
//             [error show];
//         }else{
//             NSString *state;
//             CLPlacemark *temp;
//             if ([placemarks count] <= 0) {
//                 UIAlertView *noResults = [[UIAlertView alloc]initWithTitle:@"No Results" message:@"No results found that matched this location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
//                 [noResults show];
//             }
//             for(int i=0;i<[placemarks count];i++)
//             {
//                 temp = [placemarks objectAtIndex:i];
//                 state =[temp administrativeArea];
//                 if ([state isEqualToString:@"CA"]) {
//                     NSLog(@"%@",temp);
//                 }
//             }
//         }
//     }];
    
    
    //end testing
    
    //start testing by Alex (for Google API)
    //[self queryRESTForCoordinates:address];
    [self queryGoogleForCoordinates:address];
    
    [HUD showUIBlockingIndicatorWithText:@"DOWNLOADING DATA"];
}

#pragma mark - server connection methods

//New Google API Method
-(void)queryGoogleForCoordinates:(NSString*)address {
    
    NSString *addressFormattedForGETREQ = [[address stringByReplacingOccurrencesOfString:@" " withString:@"+"] stringByReplacingOccurrencesOfString:@"," withString:@"%2C"];

    NSMutableString *mutableString = [[NSMutableString alloc] init];
    [mutableString insertString:@"https://maps.googleapis.com/maps/api/geocode/json?address=&sensor=false&key=KEYGOESHEREFORYOURGOOGLEMAPAPI" atIndex:0];
    [mutableString insertString:addressFormattedForGETREQ atIndex:58];
    
  //  NSLog([NSString stringWithString:mutableString]);

    
    NSString *urlString2 = [NSString stringWithString:mutableString];
    NSLog(@"%@", urlString2);
    
    [self pullFromServer:urlString2];
}
-(void)reverseGeocodeFromGoogle:(double)x otherCoord:(double)y
{
        //https://maps.googleapis.com/maps/api/geocode/json?latlng=40.714224,-73.961452&sensor=false
    

}
-(void)queryRESTForCoordinates:(NSString*)address {
    
    NSString *addressFormattedForGETREQ = [[address stringByReplacingOccurrencesOfString:@" " withString:@"+"] stringByReplacingOccurrencesOfString:@"," withString:@"%2C"];
    NSString *urlString = [NSString stringWithFormat:@"URLFORGEOCODESERVER",addressFormattedForGETREQ];
    [self pullFromServer:urlString];
}
                                 

-(void)queryRESTforCoordConverstion:(float)lattitude otherCoord:(float)longitude {
    NSLog(@"Querying Rest for Coord Conversion");
    
    
    NSString *formattedCoords = [[[NSString stringWithFormat:@"%f, %f", lattitude,longitude] stringByReplacingOccurrencesOfString:@"," withString:@"%2C"] stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    NSString *urlString = [NSString stringWithFormat:@"URLFORGEOMETRYSERVER",formattedCoords];
    NSLog(@"%@",urlString);
    
    [self pullFromServer:urlString];
}

-(void)queryRESTforPREDICTED:(double)x otherCoord:(double)y {
    NSString *formattedCoords = [NSString stringWithFormat:@"{'x':%f,'y':%f,'spatialReference':{'wkid':102113}}",x,y];
    
    //NSString *formattedFields = @"DBANAME%2CMDOWN%2CMUP%2CCONTACT%2CServiceTyp";
    NSString *formattedFields = @"DBA%2CMinAdDn%2CMinAdUp%2CCONTACT%2CServiceTyp%2CTechCode";
    
    formattedCoords = [[[[[formattedCoords stringByReplacingOccurrencesOfString:@"{" withString:@"%7B"] stringByReplacingOccurrencesOfString:@"'" withString:@"%22"] stringByReplacingOccurrencesOfString:@":" withString:@"%3A"] stringByReplacingOccurrencesOfString:@"," withString:@"%2C"] stringByReplacingOccurrencesOfString:@"}" withString:@"%7D"];
    
    NSString *urlString = [NSString stringWithFormat:@"SERVERURLFORPREDICTEDRESULTS", formattedCoords, formattedFields];
    
    NSLog(@"I should output the urlString right after this...");
    NSLog(@"%@", urlString);
    
    NSLog(@"Querying Rest for Predicted");
    NSLog(@"Querying Rest output should be right before this");
    
    [self pullFromServer:urlString];
}
-(void)queryRESTforADVERTISEDALL:(double)x otherCoord:(double)y {
    NSString *formattedCoords = [NSString stringWithFormat:@"{'x':%f,'y':%f,'spatialReference':{'wkid':102113}}",x,y];
    
    //NSString *formattedFields = @"DBANAME%2CMAXADDOWN%2CMAXADUP%2CCONTACT%2CServiceTyp";
    NSString *formattedFields = @"DBA%2CMaxAdDn%2CMaxAdUp%2CCONTACT%2CServiceTyp%2CTechCode";
    
    formattedCoords = [[[[[formattedCoords stringByReplacingOccurrencesOfString:@"{" withString:@"%7B"] stringByReplacingOccurrencesOfString:@"'" withString:@"%22"] stringByReplacingOccurrencesOfString:@":" withString:@"%3A"] stringByReplacingOccurrencesOfString:@"," withString:@"%2C"] stringByReplacingOccurrencesOfString:@"}" withString:@"%7D"];
    
     NSString *urlString = [NSString stringWithFormat:@"SERVERURLFORADVERTISEDRESULTS", formattedCoords, formattedFields];
    
    NSLog(@"Advertised All:%@", urlString);
    
    [self pullFromServer:urlString];
}

-(void)pullFromServer:(NSString*)urlString {
    NSLog(@"pullFromServer");
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]init];
    [request setURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"GET"];
    [request setValue:0 forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:nil];
    
    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if (theConnection) {
        returnData = [NSMutableData data];
    }
    else {
        NSLog(@"Error connection to REST API");
    }
}

#pragma mark - helper methods

- (void)removeAllPinsButUserLocation
{
    NSLog(@"removeAllPinButUserLocation");
    id userLocation = [mapView userLocation];
    NSMutableArray *pins = [[NSMutableArray alloc] initWithArray:[mapView annotations]];
    if (userLocation != nil)
    {
        [pins removeObject:userLocation];
    }
    [mapView removeAnnotations:pins];
}

#pragma mark - nsurlconnection delegate methods

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"didReceiveResponse");
    [returnData setLength:0];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSLog(@"DidRecieveData");
    [returnData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError");
    //unlock map after search
    [self.mapView setUserInteractionEnabled:YES];
    self.mapView.scrollEnabled = YES;
    UIAlertView *NoInternet = [[UIAlertView alloc]initWithTitle:@"Internet Connection" message:@"No Internet Connection Found" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [NoInternet show];
    [HUD hideUIBlockingIndicator];
    [self.mapView setUserInteractionEnabled:YES];
    self.mapView.scrollEnabled = YES;
}

int featuresDownloadStageIdentifier=0;
double wkidXCoord,wkidYCoord;


//Note to Self From Alex: Next method to convert to Google API. Be careful to save original functionality by just commenting out the old code
//Remember, this method uses an array of candidates but Dr. Byun instructed that to save time the first
//one on the list should just be chosen.

//handles all completed requests to server
-(void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    NSLog(@"connectionDidFinishLoading");
    [HUD hideUIBlockingIndicator];
    bool addresslistUsed = false;

    //unlock map after search
    [self.mapView setUserInteractionEnabled:YES];
    self.mapView.scrollEnabled = YES;
    
    if (returnData)
    {
        jsonObject = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:returnData options:kNilOptions error:nil];

    }
    if (jsonObject)
    {
        NSLog(@"Is a valid jsonObject");
       // if([jsonObject objectForKey:@"administrative_area_level_1"] == )
        
        NSArray *features = [jsonObject objectForKey:@"features"];
        NSArray *geometries = [jsonObject objectForKey:@"geometries"];
        NSArray *results = [jsonObject objectForKey:@"results"];
       // [jsonObject ]
        NSLog(@"Got here 1");
        
        
        
        if(features && features.count > 0)
        {
            NSLog(@"Feature Section");
            NSDictionary *attributes = [features valueForKey:@"attributes"];
            //NSMutableDictionary *predictedMeasurement = [[NSMutableDictionary alloc]initWithCapacity:3];
            NSNumber *none = [[NSNumber alloc]initWithInt:-1];
            
            switch (featuresDownloadStageIdentifier)
            {
                case 0:
                {
                    //sort out predicted results
                    //add to own details view controller
                    fPredictMeasurments = (NSArray*)attributes;
                    if (searchbar)
                    {
                        [predictedMeasurements addObject:searchBarAddress];
                    }
                    else
                    {
                        [predictedMeasurements addObject:locationAddress];
                    }
                    for(int i=0; i<[fPredictMeasurments count];i++)
                    {

                        NSDictionary *tmp = fPredictMeasurments[i];
                        //NSLog(@" %@", tmp);
                        if([[tmp valueForKey:@"ServiceTyp"] isEqualToString:@"Mobile"])
                        {
                            
                            NSMutableDictionary *tmpdict = [[NSMutableDictionary alloc]init];
                        
                            if ([[tmp valueForKey:@"MinAdUp"] isKindOfClass:[NSNumber class]])
                            {
                                [tmpdict setObject:[tmp valueForKey:@"MinAdUp"] forKey:@"MinAdUp"];
                                //printf("Im in MinAdUp if\n");
                            }
                            else
                            {
                                [tmpdict setObject:none forKey:@"MinAdUp"];
                                //printf("Im in MinAdUp else\n");
                            }
                            if ([[tmp valueForKey:@"MinAdDn"] isKindOfClass:[NSNumber class]])
                            {
                                [tmpdict setObject:[tmp valueForKey:@"MinAdDn"] forKey:@"MinAdDn"];
                                //printf("Im in MinAdDn if\n");
                            }
                            else
                            {
                                [tmpdict setObject:none forKey:@"MinAdDn"];
                                //printf("Im in MinAdDn else\n");
                            }
                            [tmpdict setObject:[tmp valueForKey:@"DBA"] forKey:@"PROVIDER"];
                            [predictedMeasurements addObject:tmpdict];
                        }
                    }
                    [HUD showUIBlockingIndicatorWithText:@"DOWNLOADING DATA"];
                    [self queryRESTforADVERTISEDALL:wkidXCoord otherCoord:wkidYCoord];
                    featuresDownloadStageIdentifier++;
                    //NSLog(@" %@", predictedMeasurements);
                    
                    break;
                }
                    
                case 1:
                {
                    //sort out advertised results, so they can be sent separately to their
                    //own detail view controller
                    advertisedMeasurements = (NSArray*)attributes;
                    featuresDownloadStageIdentifier = 0;
                    if (searchbar)
                    {
                        [advertisedFixedMeasurements addObject:searchBarAddress];
                        [advertisedMobileMeasurements addObject:searchBarAddress];
                        [advertisedSatelliteMeasurements addObject:searchBarAddress];
                    }
                    else
                    {
                        [advertisedFixedMeasurements addObject:locationAddress];
                        [advertisedMobileMeasurements addObject:locationAddress];
                        [advertisedSatelliteMeasurements addObject:locationAddress];
                    }
                    searchbar = false;
                    for (int i=0 ; i<[advertisedMeasurements count] ; i++)
                    {
                        NSDictionary *tmp = advertisedMeasurements[i];
                        NSString *serviceType = [tmp valueForKey:@"ServiceTyp"];
                        if ([serviceType isEqualToString:@"Mobile"])
                        {
                            NSMutableDictionary *tmpdict = [[NSMutableDictionary alloc]init];
                            [tmpdict setObject:[tmp valueForKey:@"MaxAdUp"] forKey:@"MaxAdUp"];
                            [tmpdict setObject:[tmp valueForKey:@"MaxAdDn"] forKey:@"MaxAdDn"];
                            //Right now contact is unused, may add in future
                            [tmpdict setObject:[tmp valueForKey:@"CONTACT"] forKey:@"CONTACT"];
                            [tmpdict setObject:[tmp valueForKey:@"DBA"] forKey:@"PROVIDER"];
                            [advertisedMobileMeasurements addObject:tmpdict];
                        }
                        
                        if ([serviceType isEqualToString:@"Satellite"])
                        {
                            NSMutableDictionary *tmpdict = [[NSMutableDictionary alloc]init];
                            [tmpdict setObject:[tmp valueForKey:@"MaxAdUp"] forKey:@"MacAdUp"];
                            [tmpdict setObject:[tmp valueForKey:@"MaxAdDn"] forKey:@"MaxAdDn"];
                            //Right now contact is unused, may add in future
                            [tmpdict setObject:[tmp valueForKey:@"CONTACT"] forKey:@"CONTACT"];
                            [tmpdict setObject:[tmp valueForKey:@"DBA"] forKey:@"PROVIDER"];
                            
                            [advertisedSatelliteMeasurements addObject:tmpdict];
                        }
                        if ([serviceType isEqualToString:@"Wireline"] || [serviceType isEqualToString:@"Fixed Wireless"]) 
                        {
                            NSMutableDictionary *tmpdict = [[NSMutableDictionary alloc]init];
                            [tmpdict setObject:[tmp valueForKey:@"MaxAdUp"] forKey:@"MaxAdUp"];
                            [tmpdict setObject:[tmp valueForKey:@"MaxAdDn"] forKey:@"MaxAdDn"];
                            //Right now contact is unused, may add in future
                            [tmpdict setObject:[tmp valueForKey:@"CONTACT"] forKey:@"CONTACT"];
                            [tmpdict setObject:[tmp valueForKey:@"DBA"] forKey:@"PROVIDER"];
                            [tmpdict setObject:[tmp valueForKey:@"TechCode"] forKey:@"TechCode"];
                            [advertisedFixedMeasurements addObject:tmpdict];
                        }
                    }
                    [mapView addGestureRecognizer:lpgr];
                    
                    //reload views once data is all downloaded
                    for (UIViewController *v in detailsViewController.viewControllers)
                    {
                        [v viewDidLoad];
                    }
                    [self performSegueWithIdentifier:@"annotationDetails" sender:self];
                    
                    break;
                }
                default:
                {
                    break;
                }
            }
            
            //NSLog(@" %@", advertisedMobileMeasurements);
            if (arrayOfAddresses.count > 1)
            {
                [self performSegueWithIdentifier:@"addresslist" sender:searchBar];
            }
            else if (arrayOfAddresses.count == 1)
            {
                [self removeAllPinsButUserLocation];
            
                //create new annotation where address is
                NSDictionary *selectedAttributes = arrayOfAttributes[0];
                CLLocationCoordinate2D coord;
                coord.latitude = [[[selectedAttributes valueForKey:@"Y"]description]doubleValue];
                coord.longitude = [[[selectedAttributes valueForKey:@"X"]description]doubleValue];
                CLLocation *location = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
                if(zipCode)
                {
                    searchbar = true;
                }
                if ([self checkSelectedLocation:location])
                {
                    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coord, 12800, 12800);
                    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
                    //add annotation
                    locationAddress = @" ";
                    pa.coordinate = coord;
                    [pa setTitle:@"Selected Location"];
                    if (zipCode)
                    {
                        [pa setSubtitle:ZipCode];
                        searchBarAddress = ZipCode;
                    }
                    else
                    {
                        [pa setSubtitle:locationAddress];
                    }
                        [mapView addAnnotation:pa];
                        [mapView selectAnnotation:pa animated:YES];
                }
            
                [arrayOfAddresses removeAllObjects];
            }
            else if (arrayOfAttributes.count < 1)
            {
                if (addresslistUsed)
                {
                    UIAlertView *noResults = [[UIAlertView alloc]initWithTitle:@"No Results" message:@"No results found that matched this location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    [noResults show];
                    addresslistUsed = false;
                }
            }
        }
        else if (geometries)
        {
            NSLog(@"Got to geometries");
                NSDictionary *coords = geometries[0];
    
                wkidXCoord = [[coords valueForKey:@"x"]doubleValue];
                wkidYCoord = [[coords valueForKey:@"y"]doubleValue];
    
                if (wkidXCoord && wkidYCoord)
                {
                    [HUD showUIBlockingIndicatorWithText:@"DOWNLOADING DATA"];
                    [self queryRESTforPREDICTED:wkidXCoord otherCoord:wkidYCoord];
                    featuresDownloadStageIdentifier = 0;
                }
        }
        else if (results)
        {
            NSLog(@"Results");
            
            if(results.count < 1)
            {
                NSLog(@"Error HERE");
                
                UIAlertView *noResults = [[UIAlertView alloc]initWithTitle:@"No Results" message:@"No results found that matched this location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [noResults show];

                
            }
            else
            if(results)
            {
                NSString *formattedAddress = [results[0] valueForKey:@"formatted_address"];
                NSLog(@"%@",formattedAddress);
                
                NSArray *addressComponents = [results[0] valueForKey:@"address_components"];
                
                NSArray *types;
                NSString *title;
                NSString *state = @"State";
                for(int i = 0; i < addressComponents.count; i++)
                {
                    types = [addressComponents[i] valueForKey:@"types"];
                    if(types.count > 0)
                    {
                        NSLog(@"accessing title");
                        title = types[0];
                        NSLog(@"%@",title);
                        
                        if([title isEqualToString:@"administrative_area_level_1"])
                        {
                            state = [addressComponents[i] valueForKey:@"short_name"];
                            NSLog(@"%@",state);
                    
                        }
                    }
                }
                
                if(![state isEqualToString:@"CA"])
                {
                    UIAlertView *noResults = [[UIAlertView alloc]initWithTitle:@"No Results" message:@"No results found that matched this location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    [noResults show];
                }
                else
                {
                    NSLog(@"HERE Found at least one result");
                    //Google API JSON format for this particular section of relevant data
                    //        "geometry" :
                    //        {
                    //            "bounds" :
                    //            {
                    //                "northeast" :
                    //                {
                    //                    "lat" : 36.6578328,
                    //                    "lng" : -121.7869631
                    //                },
                    //                "southwest" :
                    //                {
                    //                    "lat" : 36.6462359,
                    //                    "lng" : -121.8096391
                    //                }
                    //            },
                    //            "location" :
                    //            {
                    //                "lat" : 36.65300060000001,
                    //                "lng" : -121.8002501
                    //            },
                    //            "location_type" : "APPROXIMATE",
                    //            "viewport" :
                    //            {
                    //                "northeast" :
                    //                {
                    //                    "lat" : 36.6578328,
                    //                    "lng" : -121.7869631
                    //                },
                    //                "southwest" :
                    //                {
                    //                    "lat" : 36.6462359,
                    //                    "lng" : -121.8096391
                    //                }
                    //            }
                    //        }
                    
                    NSDictionary *geometry = [results[0] valueForKey:@"geometry"];
                    NSDictionary *coords = [geometry valueForKey:@"location"];
                    
                 //   NSDictionary *viewport = [geometry valueForKey:@"viewport"];
                  //  NSDictionary *coords = [viewport valueForKey:@"southwest"];
                    
                    
                    double lat = [[coords valueForKey:@"lat"] doubleValue];
                    double lng = [[coords valueForKey:@"lng"] doubleValue];
                    
                    NSLog(@"Latitude: %f",lat);
                    NSLog(@"Longitude: %f",lng);
                   // NSString *lng = [coords valueForKey:@"lng"];
                    
                    NSString *latString = [NSString stringWithFormat:@"Latitude: %g", lat];
                    NSString *lngString = [NSString stringWithFormat:@"Longitude: %g", lng];
                    
                    
                    NSLog(@"%@",latString);
                    NSLog(@"%@",lngString);
                    
                    
                    wkidXCoord = lat;
                    wkidYCoord = lng;
                    
                    if (lat && lng)
                    {
                        CLLocationCoordinate2D coord;
                        coord.latitude = lat;
                        coord.longitude = lng;
                        CLLocation *location = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];

                        if ([self checkSelectedLocation:location])
                        {
                            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coord, 12800, 12800);
                            [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
                            //add annotation
                            locationAddress = @" ";
                            pa.coordinate = coord;
                            [pa setTitle:@"Selected Location"];

                            [pa setSubtitle:locationAddress];
                            
                            [mapView addAnnotation:pa];
                            [mapView selectAnnotation:pa animated:YES];
                        }
                        
                        
                      //  [HUD showUIBlockingIndicatorWithText:@"DOWNLOADING DATA"];
                        //[self queryRESTforPREDICTED:lat otherCoord:lng];
                      //  [self queryRESTforCoordConverstion:lng otherCoord:lat];
                        featuresDownloadStageIdentifier = 0;
                    }
                }
            }
        }
        else
        {
            NSLog(@"Not features, geometries, or results");
                
            UIAlertView *noResults = [[UIAlertView alloc]initWithTitle:@"No Data" message:@"No data found for this location." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [noResults show];
                
            [self.mapView setUserInteractionEnabled:YES];
            self.mapView.scrollEnabled = YES;
            [mapView addGestureRecognizer:lpgr];
            
        }
        
       // NSLog(lng);
      //  NSLog([coords valueForKey:@"lat"]);
        //NSLog([coords valueForKey:@"lng"]);
        
        //[arrayOfCoordinates addObject:coords];
        
        
      //  NSDictionary *addressComponents = [results[0] valueForKey:@"address_components"];
        
       // NSString *state = [[addressComponents valueForKey:@"administrative_area_level_1"] description];
        
        
        
//        NSArray *candidatesDictionary = [jsonObject objectForKey:@"candidates"];
//        NSArray *geometries = [jsonObject objectForKey:@"geometries"];
//        NSArray *features = [jsonObject objectForKey:@"features"];
//        bool usRoof = false; //to find strongest match
//        zipCode = false;
//        if (candidatesDictionary)
//        {
//            addresslistUsed = true;
//            NSLog(@"%@",candidatesDictionary);
//            for (NSArray *array in candidatesDictionary) {
//                //first make sure we can only select address in CA
//                NSDictionary *atts = [array valueForKey:@"attributes"];
//                NSString *state = [[atts valueForKey:@"State"]description];
//                NSString *loc_name = [[atts valueForKey:@"Loc_name"] description];
//                
//                if ([loc_name isEqualToString:@"US_Zipcode"]) {
//                    zipCode = true;
//                    ZipCode = [searchBar text];
//                    NSLog(@"found zipcode");
//                }
//                if ([loc_name isEqualToString:@"US_RoofTop"]) {
//                    usRoof = true;
//                    zipCode = true;
//                    ZipCode = [[atts valueForKey:@"Match_addr"] description];
//                    
//                    NSLog(@"found rooftop");
//                }
//                
//                if (usRoof) {
//                    [arrayOfAddresses removeAllObjects];
//                    [arrayOfAttributes addObject:atts];
//                    
//                    NSObject *address = [array valueForKey:@"address"];
//                    [arrayOfAddresses addObject:address.description];
//                    
//                    NSDictionary *coords = [array valueForKey:@"location"];
//                    [arrayOfCoordinates addObject:coords];
//                    break;
//                    
//                }
//                if ((state != nil) && ([state length]!=0) && ([state isEqualToString:@"CA"])){
//                    //add the lookup results to local objects
//                    [arrayOfAttributes addObject:atts];
//            
//                    NSObject *address = [array valueForKey:@"address"];
//                    [arrayOfAddresses addObject:address.description];
//            
//                    NSDictionary *coords = [array valueForKey:@"location"];
//                    [arrayOfCoordinates addObject:coords];
//                }
//            
//            }
//        }
        
        
        
        
        
//        else if (geometries)
//        {
//            NSDictionary *coords = geometries[0];
//            
//            wkidXCoord = [[coords valueForKey:@"x"]doubleValue];
//            wkidYCoord = [[coords valueForKey:@"y"]doubleValue];
//            
//            if (wkidXCoord && wkidYCoord) {
//                [HUD showUIBlockingIndicatorWithText:@"DOWNLOADING DATA"];
//                [self queryRESTforPREDICTED:wkidXCoord otherCoord:wkidYCoord];
//                featuresDownloadStageIdentifier = 0;
//            }
//        }
//        else if (features)
//        {
//            NSDictionary *attributes = [features valueForKey:@"attributes"];
//            //NSMutableDictionary *predictedMeasurement = [[NSMutableDictionary alloc]initWithCapacity:3];
//            NSNumber *none = [[NSNumber alloc]initWithInt:-1];
//            
//            switch (featuresDownloadStageIdentifier) {
//                case 0:{
//                    //sort out predicted results
//                    //add to own details view controller
//                    fPredictMeasurments = (NSArray*)attributes;
//                    if (searchbar) {
//                        [predictedMeasurements addObject:searchBarAddress];
//                    }
//                    else{
//                        [predictedMeasurements addObject:locationAddress];
//
//                    }                    
//                    for(int i=0; i<[fPredictMeasurments count];i++)
//                    {
//                        NSDictionary *tmp = fPredictMeasurments[i];
//                        //NSString *serviceType = [tmp valueForKey:@"ServiceTyp"];
//                        NSMutableDictionary *tmpdict = [[NSMutableDictionary alloc]init];
//                        if ([[tmp valueForKey:@"MUP"] isEqualToString:@" "]) {
//                            [tmpdict setObject:none forKey:@"MAXADUP"];
//                        }
//                        else{
//                            [tmpdict setObject:[tmp valueForKey:@"MUP"] forKey:@"MAXADUP"];
//                        }
//                        if ([[tmp valueForKey:@"MDOWN"] isEqualToString:@" "]) {
//                            [tmpdict setObject:none forKey:@"MAXADDOWN"];
//                        }
//                        else{
//                            [tmpdict setObject:[tmp valueForKey:@"MDOWN"] forKey:@"MAXADDOWN"];
//                        }
//                        [tmpdict setObject:[tmp valueForKey:@"DBANAME"] forKey:@"PROVIDER"];
//                        [predictedMeasurements addObject:tmpdict];
//                    }
//                    [HUD showUIBlockingIndicatorWithText:@"DOWNLOADING DATA"];
//                    [self queryRESTforADVERTISEDALL:wkidXCoord otherCoord:wkidYCoord];
//                    featuresDownloadStageIdentifier++;
//                    break;
//                }
//                    
//               case 1:
//                {
//                    //sort out advertised results, so they can be sent separately to their
//                    //own detail view controller
//                    advertisedMeasurements = (NSArray*)attributes;
//                    featuresDownloadStageIdentifier = 0;
//                   if (searchbar)
//                    {
//                       [advertisedFixedMeasurements addObject:searchBarAddress];
//                       [advertisedMobileMeasurements addObject:searchBarAddress];
//                       [advertisedSatelliteMeasurements addObject:searchBarAddress];
//                   }
//                   else
//                   {
//                    [advertisedFixedMeasurements addObject:locationAddress];
//                    [advertisedMobileMeasurements addObject:locationAddress];
//                    [advertisedSatelliteMeasurements addObject:locationAddress];
//                   }
//                   searchbar = false;
//                    for (int i=0 ; i<[advertisedMeasurements count] ; i++)
//                    {
//                        
//                        NSDictionary *tmp = advertisedMeasurements[i];
//                        NSString *serviceType = [tmp valueForKey:@"ServiceTyp"];
//                        
//                        if ([serviceType isEqualToString:@"Mobile"])
//                        {
//                            NSMutableDictionary *tmpdict = [[NSMutableDictionary alloc]init];
//                            [tmpdict setObject:[tmp valueForKey:@"MAXADUP"] forKey:@"MAXADUP"];
//                            [tmpdict setObject:[tmp valueForKey:@"MAXADDOWN"] forKey:@"MAXADDOWN"];
//                            //Right now contact is unused, may add in future
//                            [tmpdict setObject:[tmp valueForKey:@"CONTACT"] forKey:@"CONTACT"];
//                            [tmpdict setObject:[tmp valueForKey:@"DBANAME"] forKey:@"PROVIDER"];
//                            
//                            [advertisedMobileMeasurements addObject:tmpdict];
//                        }
//                        if ([serviceType isEqualToString:@"Satellite"])
//                        {
//                            NSMutableDictionary *tmpdict = [[NSMutableDictionary alloc]init];
//                            [tmpdict setObject:[tmp valueForKey:@"MAXADUP"] forKey:@"MAXADUP"];
//                            [tmpdict setObject:[tmp valueForKey:@"MAXADDOWN"] forKey:@"MAXADDOWN"];
//                            //Right now contact is unused, may add in future 
//                            [tmpdict setObject:[tmp valueForKey:@"CONTACT"] forKey:@"CONTACT"];
//                            [tmpdict setObject:[tmp valueForKey:@"DBANAME"] forKey:@"PROVIDER"];
//                            
//                            [advertisedSatelliteMeasurements addObject:tmpdict];
//                        }
//                        if ([serviceType isEqualToString:@"Fixed"])
//                        {
//                            NSMutableDictionary *tmpdict = [[NSMutableDictionary alloc]init];
//                            [tmpdict setObject:[tmp valueForKey:@"MAXADUP"] forKey:@"MAXADUP"];
//                            [tmpdict setObject:[tmp valueForKey:@"MAXADDOWN"] forKey:@"MAXADDOWN"];
//                            //Right now contact is unused, may add in future
//                            [tmpdict setObject:[tmp valueForKey:@"CONTACT"] forKey:@"CONTACT"];
//                            [tmpdict setObject:[tmp valueForKey:@"DBANAME"] forKey:@"PROVIDER"];
//                            
//                            [advertisedFixedMeasurements addObject:tmpdict];
//                        }
//                    }
//                   [mapView addGestureRecognizer:lpgr];
//                    //reload views once data is all downloaded
//                    for (UIViewController *v in detailsViewController.viewControllers)
//                    {
//                        [v viewDidLoad];
//                    }
//                    [self performSegueWithIdentifier:@"annotationDetails" sender:self];
//                    break;
//                }
//                default:
//                {
//                    
//                    break;
//                }
//            }
//        }
        
    } //FYI, this is th 'if valid json object' closing bracket
    
    //NSLog(@" %@", advertisedMobileMeasurements);
//    if (arrayOfAddresses.count > 1) {
//        [self performSegueWithIdentifier:@"addresslist" sender:searchBar];
//    }
//    else if (arrayOfAddresses.count == 1) {
//        [self removeAllPinsButUserLocation];
//        
//        //create new annotation where address is
//         
//        
//        NSDictionary *selectedAttributes = arrayOfAttributes[0];
//        CLLocationCoordinate2D coord; 
//        coord.latitude = [[[selectedAttributes valueForKey:@"Y"]description]doubleValue];
//        coord.longitude = [[[selectedAttributes valueForKey:@"X"]description]doubleValue];
//        CLLocation *location = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
//        if(zipCode)
//        {
//            searchbar = true;
//        }
//        if ([self checkSelectedLocation:location]) {
//            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coord, 12800, 12800);
//            [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
//            //add annotation
//            locationAddress = @" ";
//            pa.coordinate = coord;
//            [pa setTitle:@"Selected Location"];
//            if (zipCode) {
//                [pa setSubtitle:ZipCode];
//                searchBarAddress = ZipCode;
//            }
//            else{
//            [pa setSubtitle:locationAddress];
//            }
//            [mapView addAnnotation:pa];
//            [mapView selectAnnotation:pa animated:YES];
//        }
//        
//        [arrayOfAddresses removeAllObjects];
//    }
//    else if (arrayOfAttributes.count < 1) {
//        if (addresslistUsed) {
//            UIAlertView *noResults = [[UIAlertView alloc]initWithTitle:@"No Results" message:@"No results found that matched this location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
//            [noResults show];
//            addresslistUsed = false;
//        }
//    }
}

#pragma mark - misc


#pragma mark - segue delegate method
//where objects are passed to new views
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"addresslist"]) {
        AddresslistViewController *destViewController = segue.destinationViewController;
        destViewController.arrayOfAddresses = arrayOfAddresses;
        destViewController.delegate = self;
        //[arrayOfAddresses removeAllObjects];
    }
    else if ([segue.identifier isEqualToString:@"annotationDetails"]) {
        detailsViewController = segue.destinationViewController;
        for (int i=0;i<detailsViewController.viewControllers.count;i++) {
            if ([detailsViewController.viewControllers[i] isKindOfClass:[advertisedFixedViewController class]]) {
                advertisedFixedViewController *afvc = (advertisedFixedViewController*)detailsViewController.viewControllers[i];
                afvc.advFixVCMeasurements = advertisedFixedMeasurements;
            }
            else if ([detailsViewController.viewControllers[i] isKindOfClass:[advertisedMobileViewController class]]) {
                advertisedMobileViewController *amvc = (advertisedMobileViewController*)detailsViewController.viewControllers[i];
                amvc.advMobVCMeasurements = advertisedMobileMeasurements;
            }
            else if ([detailsViewController.viewControllers[i] isKindOfClass:[advertisedSatelliteViewController class]]) {
                advertisedSatelliteViewController *asvc = (advertisedSatelliteViewController*)detailsViewController.viewControllers[i];
                asvc.advSatVCMeasurements = advertisedSatelliteMeasurements;
            }
            else if ([detailsViewController.viewControllers[i] isKindOfClass:[predictedMobileViewController class]]) {
                predictedMobileViewController *pmvc = (predictedMobileViewController*)detailsViewController.viewControllers[i];
                pmvc.predictedMeasurements = predictedMeasurements;
            }
        }
    }

}

#pragma mark - viewDelegate method

-(void)childViewControllerDidFinish:(AddresslistViewController *)viewController {
    NSLog(@"childViewControllerDidFinish");
    [self.navigationController popViewControllerAnimated:YES];
    
    int addressIndex = viewController.selectedAddressIndex;
    searchBar.text = arrayOfAddresses[addressIndex];
    NSDictionary *selectedAttribute = arrayOfAttributes[addressIndex];
    
    CLLocationCoordinate2D touchMapCoord;
    touchMapCoord.latitude = [[selectedAttribute objectForKey:@"Y"]doubleValue];
    touchMapCoord.longitude = [[selectedAttribute objectForKey:@"X"]doubleValue];
    
    //first remove current annotation
    [self removeAllPinsButUserLocation];
    
    //move map to new annotation
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(touchMapCoord, 5000, 5000);
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
    CLLocation *temploc = [[CLLocation alloc ]initWithLatitude:touchMapCoord.latitude longitude:touchMapCoord.longitude];
    //add new annotation where touched
    //MKPointAnnotation *pa = [[MKPointAnnotation alloc] init];
    pa.coordinate = touchMapCoord;
    searchbar = true;
    [self checkSelectedLocation:temploc];
    locationAddress = [selectedAttribute objectForKey:@"Match_addr"];
    searchBarAddress = locationAddress;
    pa.coordinate = touchMapCoord;
    [pa setTitle:@"Selected Location"];
    [mapView addAnnotation:pa];
    if (check == true) {
        [pa setSubtitle:searchBarAddress];
    }
    [mapView selectAnnotation:pa animated:YES];
    [arrayOfAddresses removeAllObjects];
    searchBar.placeholder = @"Search Address";
}

- (void) dealloc
{
    NSLog(@"dealloc");
    //[locationManager setDelegate:nil];
}

@end
