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

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "AddresslistViewController.h"
#import "AboutViewController.h"
#import "advertisedFixedViewController.h"
#import "advertisedMobileViewController.h"
#import "advertisedSatelliteViewController.h"
#import "predictedMobileViewController.h"


@interface ViewController : UIViewController <MKMapViewDelegate,UISearchBarDelegate,NSURLConnectionDelegate,viewDelegate,CLLocationManagerDelegate>
{
    //main storyboard
    UIStoryboard *sb;
    
    //search bar object used to get address text input
    UISearchBar *searchBar;
    UIButton *infoButton;
    
    //detail view tabs objects - used to store measurement data in order to view
    UITabBarController *tabBarController;
    //advertisedMobileViewController *advMobileMeasurementsVC; //holds data for advertised mobile
    predictedMobileViewController *predMobileMeasurementsVC; //holds data for predicted mobile
    //advertisedSatelliteViewController *advSatelliteMeasurementVC; //holds data for satelite
    advertisedFixedViewController *advFixedMeasurementVC;//data for fixed
    UITabBarController *detailsViewController;
    
    //measurement data objects gathered from objects holding data pulled from REST
    NSMutableArray *predictedMeasurements;
    NSArray *advertisedMeasurements, *fPredictMeasurments;
    NSMutableArray *advertisedFixedMeasurements,*advertisedMobileMeasurements,*advertisedSatelliteMeasurements;
    
    //objects to hold address related data pulled from REST
    NSDictionary *jsonObject;
    NSMutableArray *arrayOfAddresses, *arrayOfCoordinates, *arrayOfAttributes;
    NSMutableData *returnData;
    MKPointAnnotation *pa;
    UILongPressGestureRecognizer *lpgr;
    //current location
    CLLocation *usersLocation;
    bool firsttime;
    bool searchbar;
    bool check ;
    bool showInfo;
    bool zipCode;
    //Address for chosen place
    NSString *locationAddress;
    NSString *UlocationAddress;
    NSString *searchBarAddress;
    NSString *ZipCode;
    
    NSString *previousAddress;
    
    
}
@property (nonatomic,strong) IBOutlet MKMapView *mapView;
@property (nonatomic,strong) IBOutlet UINavigationItem *navItem;
@property (strong, nonatomic) CLLocationManager *locationManager;

@end
