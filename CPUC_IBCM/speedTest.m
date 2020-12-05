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
#import <Foundation/Foundation.h>
#import "speedTest.h"
#import <QuartzCore/QuartzCore.h>
#import "LoggingWrapper.h"
#import "DeviceInformation.h"
#import "CoreDataManager.h"
#import "AppDelegate.h"
#import "MOSCalculation.h"
#import "VMScore.h"
#import "VMContainer.h"
#import "ResultPopupView.h"
#import "ResultPopupViewController.h"
#import <SystemConfiguration/CaptiveNetwork.h>

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_RETINA ([[UIScreen mainScreen] scale] >= 2.0)

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

#define IS_IPHONE_4_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5 (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)

@implementation speedTestViewController

speedTestViewController *shared;

iPerfEngine *iperfEngine;

NSString *networkType;
NSDate *startDate;

int currentTestSegment;
int doTheProbeTest = 0;
int probeTestCount = 0;
double phase1FinalUploadSpeed;
double phase1FinalDownloadSpeed;
double phase1FinalDelay;
double phase1FinalDelayVariation;

UILabel *currentTestLabelToUpdate;

//bool firstResultReceived;

double currentDelayResult;


double uploadSpeed;
double downloadSpeed;
double delay;
double delayVariation;
UIButton *startTestButton;
char grade;

UIImageView *needleImageView;
float speedometerCurrentValue;
float prevAngleFactor;
float angle;
UILabel *speedometerReading;
NSString *maxVal;
NSString *maxVal1;
NSString *maxVal2;
NSString *maxVal3;
NSString *maxVal4;
NSString *maxVal5;

NSTimer *randomize;

bool indoor, startButtonMaximized = true;

extern int iperf_timeout, cnx_error;
extern struct video_metric VIDM;
extern int probe_ary[10];
extern int reported_probe_speed;
- (void)viewDidLoad
{
    shared = self;
    [super viewDidLoad];
    
    [self.navigationItem setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Speed Test" style:UIBarButtonItemStylePlain target:nil action:nil]];
    
    //back chevron color
    self.navigationItem.backBarButtonItem.tintColor = [UIColor colorWithRed:10/255.0 green:134/255.0 blue:191/255.0 alpha:1.0];
    
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:86/255.0 green:178/255.0 blue:227/255.0 alpha:1.0];
    
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:86/255.0 green:178/255.0 blue:227/255.0 alpha:1.0]];
    
    iperfEngine = [[iPerfEngine alloc] initWithDelegate:self];
    [iperfEngine setLogTestToConsole:true];
    
    [self resizeConstraints];
    
    [self viewDidLayoutSubviews];
    [self changeStart];
    
    [self viewDidLayoutSubviews];
    
    
    [self loadMeterView];
    
    //Change color of UISwitch in “off” state
    inOutSwitch.tintColor = [UIColor lightGrayColor];
    inOutSwitch.onTintColor = [UIColor lightGrayColor];
    inOutSwitch.layer.cornerRadius = 16;
    inOutSwitch.backgroundColor = [UIColor lightGrayColor];
    
    downloadLabel.hidden=YES;
    uploadLabel.hidden=YES;
    delayLabel.hidden=YES;
    delayVariationLabel.hidden=YES;
    ul.hidden=YES;
    dl.hidden=YES;
    d.hidden=YES;
    dv.hidden=YES;
    welcome.layer.borderColor = (__bridge CGColorRef)([UIColor lightGrayColor]);
    welcome.layer.borderWidth = 3;
    welcome.layer.cornerRadius = 8;
    welcome.clipsToBounds = YES;
    
    startButton.layer.borderColor = (__bridge CGColorRef)([UIColor grayColor]);
    startButton.layer.borderWidth = 1;
    startButton.layer.cornerRadius = 5;
    startButton.clipsToBounds = YES;
    uploadSpeed = 0;
    downloadSpeed = 0;
    delay = 0;
    delayVariation = 0;
    [indoorButton addTarget:self action:@selector(indoorAction) forControlEvents:UIControlEventTouchUpInside];
    uploadLabel.text = [[NSString alloc] initWithFormat:@"%.02f Mbps", uploadSpeed];
    downloadLabel.text = [[NSString alloc] initWithFormat:@"%.02f Mbps", downloadSpeed];
    delayLabel.text = [[NSString alloc] initWithFormat:@"%.02f ms", delay];
    delayVariationLabel.text = [[NSString alloc] initWithFormat:@"%.02f ms", delayVariation];
    maxSpeedometerLabel.frame = CGRectMake(maxSpeedometerLabel.frame.origin.x, maxSpeedometerLabel.frame.origin.y, 50, 12);
    maxSpeedometerLabel.layer.zPosition = 1;
    
    indoor = YES;
    [MOSCalculation init];
    [MOSCalculation setDebugMode:false];
    
    aTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                              target:self
                                            selector:@selector(timerFired:)
                                            userInfo:aTimer
                                             repeats:true];
    [aTimer fire];
    
    if(IS_IPHONE_4_OR_LESS)
        [startButton setFrame:CGRectMake(40, 400, 240, 30)];
    else if([self isIphoneX])
    {
        startButton.frame = CGRectMake(60, 390, 200, 30);
        startButton.backgroundColor = [UIColor colorWithRed:86/255.0 green:178/255.0 blue:227/255.0 alpha:1.0];
        readyToBegin.text =[NSString stringWithFormat:@""];
    }
    else
        startButton.frame = CGRectMake(36, 482, 245, 30);

    // check to see if Location is enabled
    /*if([CLLocationManager locationServicesEnabled] &&
       [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied)
    {
        NSUInteger countOfRecords = [CoreDataManager getNumberOfRecord];
        NSLog(@"\nDon't have Location Permissions enabled. Count: %tu\n", countOfRecords);
        if(countOfRecords != 0)
        {
            UIAlertView *error = [[UIAlertView alloc]initWithTitle:@"Location Unavailable" message:@"Please make sure Location is enabled for the CalSPEED app in the settings." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [error show];
        }
    }
    */
}

-(bool)isIphoneX
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [[NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding] isEqualToString:@"iPhone10,3"] ||
            [[NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding] isEqualToString:@"iPhone10,6"];
}

NSTimer *aTimer;

-(void)timerFired:(NSTimer *) theTimer{
    if (!iperfEngine.testActive){
        Reachability *reach = [Reachability reachabilityForLocalWiFi];
        if ([reach currentReachabilityStatus] == ReachableViaWiFi){
            //if(wifiNameLabel.hidden && [reach.])
            //connectedToWifiLabel.hidden = false;
            connectedToWifiLabel.text = @"Connected to Wi-FI";
        }
        else
            connectedToWifiLabel.text = @"Connected to Mobile";
    }
}

-(void)viewDidLayoutSubviews{
    if(IS_IPHONE_4_OR_LESS)
    {
        //UIView *ImageView = [[UIImageView alloc]initWithFrame:CGRectMake(20, 75, 280, 175)];//16 80
        //meterSpot = ImageView;
        
        //[self.view addSubview:meterSpot];
        
        //UIButton *inside = [[UIButton alloc]initWithFrame:CGRectMake(150, 165, , )]
        [meterSpot setFrame:CGRectMake(20, 70, 280, 175)];
        //[meterSpot setFrame:CGRectMake(660, 160, 285, 175)];
        //[indoorButton setFrame:CGRectMake(110, 125, 80, 25)];
        [indoorButton setFrame: CGRectMake(110, 255, 80, 25)];
        indoorButton.hidden = YES;
        [welcome setFrame:CGRectMake(40, 270, 240, 125)];
        //[startButton setFrame:CGRectMake(40, 270, 240, 160)];
        
        [uploadLabel setFrame:CGRectMake(40, 275 , 240,80 )];
        [downloadLabel setFrame:CGRectMake(40, 275 , 240,80 )];
        [delayLabel setFrame:CGRectMake(40, 275 , 240,80 )];
        [delayVariationLabel setFrame:CGRectMake(40, 275 , 240,80 )];
        
        [ul setFrame:CGRectMake(45, 340, 230, 40)];
        [dl setFrame:CGRectMake(45, 340, 230, 40)];
        [d setFrame:CGRectMake(45, 340, 230, 40)];
        [dv setFrame:CGRectMake(45, 340, 230, 40)];
        
        [maxSpeedometerLabel setFrame:CGRectMake(187, 147.6, 45, 20)];
        maxSpeedometerLabel.font = [maxSpeedometerLabel.font fontWithSize:8.5];
        if([[[UIDevice currentDevice] systemVersion]floatValue] < 9){
            [uploadFinal setFrame:CGRectMake(uploadFinal.frame.origin.x, 283, uploadFinal.frame.size.width, uploadFinal.frame.size.height)];
            [downloadFinal setFrame:CGRectMake(downloadFinal.frame.origin.x, 283, downloadFinal.frame.size.width, downloadFinal.frame.size.height)];
            [delayFinal setFrame:CGRectMake(delayFinal.frame.origin.x, 343, delayFinal.frame.size.width, delayFinal.frame.size.height)];
            [delayVariationFinal setFrame:CGRectMake(delayVariationFinal.frame.origin.x, 343, delayVariationFinal.frame.size.width, delayVariationFinal.frame.size.height)];
            
            [ulFinal setFrame:CGRectMake(uploadFinal.frame.origin.x, uploadFinal.frame.origin.y + 25, uploadFinal.frame.size.width, 25)];
            [dlFinal setFrame:CGRectMake(downloadFinal.frame.origin.x + 20, downloadFinal.frame.origin.y + 25, downloadFinal.frame.size.width, 25)];
            [dFinal setFrame:CGRectMake(delayFinal.frame.origin.x, delayFinal.frame.origin.y + 25, delayFinal.frame.size.width, 25)];
            [dvFinal setFrame:CGRectMake(delayVariationFinal.frame.origin.x, delayVariationFinal.frame.origin.y + 25, delayVariationFinal.frame.size.width, 25)];
            [mosDescriptionLabel setFrame:CGRectMake(107, 270, mosDescriptionLabel.frame.size.width, mosDescriptionLabel.frame.size.height)];
            [satisfyLabel setFrame:CGRectMake(90, 245, satisfyLabel.frame.size.width, satisfyLabel.frame.size.height)];
        }
        else{
            [uploadFinal setFrame:CGRectMake(uploadFinal.frame.origin.x, 280, uploadFinal.frame.size.width, uploadFinal.frame.size.height)];
            [downloadFinal setFrame:CGRectMake(downloadFinal.frame.origin.x, 280, downloadFinal.frame.size.width, downloadFinal.frame.size.height)];
            [delayFinal setFrame:CGRectMake(delayFinal.frame.origin.x, 340, delayFinal.frame.size.width, delayFinal.frame.size.height)];
            [delayVariationFinal setFrame:CGRectMake(delayVariationFinal.frame.origin.x, 340, delayVariationFinal.frame.size.width, delayVariationFinal.frame.size.height)];
            
            [ulFinal setFrame:CGRectMake(uploadFinal.frame.origin.x, uploadFinal.frame.origin.y + 25, uploadFinal.frame.size.width, 25)];
            [dlFinal setFrame:CGRectMake(downloadFinal.frame.origin.x + 20, downloadFinal.frame.origin.y + 25, downloadFinal.frame.size.width, 25)];
            [dFinal setFrame:CGRectMake(delayFinal.frame.origin.x, delayFinal.frame.origin.y + 25, delayFinal.frame.size.width, 25)];
            [dvFinal setFrame:CGRectMake(delayVariationFinal.frame.origin.x, delayVariationFinal.frame.origin.y + 25, delayVariationFinal.frame.size.width, 25)];
            [mosDescriptionLabel setFrame:CGRectMake(107, 270, mosDescriptionLabel.frame.size.width, mosDescriptionLabel.frame.size.height)];
            [satisfyLabel setFrame:CGRectMake(90, 245, satisfyLabel.frame.size.width, satisfyLabel.frame.size.height)];
        }
        
    }
    else{
        [d setFrame:CGRectMake(40, 420, 230, 40)];
    }
    //[self.tabBarController invalidateIntrinsicContentSize];
}
-(void)changeStart{
    if(IS_IPHONE_4_OR_LESS)
    {
        [startButton setFrame:CGRectMake(40, 270, 240, 160)];
    }
    
}
-(IBAction)infoButtonPressed:(id)sender{
    //[[self.navigationController navigationBar] setTintColor:[UIColor blueColor]]; // BAD
    //[[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil] setTintColor:[AppDelegate getContainedTintColor]]; // BAD
    //[[UINavigationBar appearance] setBackgroundColor:[AppDelegate getContainedTintColor]]; // BAD
    
    [self.navigationController pushViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"AboutViewController"] animated:true];
}

// Updates the label for the current portion of the test with the associated latest result
-(void)updateCurrentTestLabelFromResult:(double) finalSpeedValue{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(currentTestLabelToUpdate == self->uploadLabel||currentTestLabelToUpdate == self->downloadLabel){
            currentTestLabelToUpdate.text = [NSString stringWithFormat:@"%.02f Mbps", finalSpeedValue];
        }
        else{
            currentTestLabelToUpdate.text = [NSString stringWithFormat:@"%.02f ms", currentDelayResult];
        }
    });
        
}

// Called when a new segment of the test starts, relegates appropriate values to specific variables that are used during each portion of the test
-(void)newTestSegmentStarted{
    printf("\n^^DEBUG: NEW TEST SEGMENT\n\n");
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = true;
    });

    currentTestSegment++;
    if(doTheProbeTest)
        currentTestSegment = 0;
    switch (currentTestSegment) {
        case 0:{
            if(doTheProbeTest)
            {
                probeTestCount++;
                [vmScore setPhase:-2];
                //UI Updates for probe test
                dispatch_async(dispatch_get_main_queue(), ^{

                    self->welcome.text =[NSString stringWithFormat:@"Preliminary Test"];
                    if(probeTestCount == 2)
                        self->progress.text = @"Running Download Phase...";
                    else
                        self->progress.text = @"Running Upload Phase...";
                    self->pulse.image = [UIImage animatedImageNamed:@"pulse" duration:2];
                    self->pulse.hidden = NO;
                    speedometerReading.hidden = true;
                    self->meterSpot.hidden = YES;
                    self->progressBar.hidden = false;
                });
            }
            else
            {
                //reset VMScore
                vmScore = [VMScore beginNewScore];
                
                // Connectivity test
                connectedToWifiLabel.hidden = true;
                readyToBegin.hidden = true;
                [self.tabBarController.tabBar setHidden:YES];
                satisfyLabel.hidden=YES;
                mosDescriptionLabel.hidden = true;
                [progressBar setProgress: (CGFloat) (0) animated:NO];
                CGAffineTransform transform = CGAffineTransformMakeScale(1.0f, 5.0f);
                progressBar.transform = transform;
                welcome.text =[NSString stringWithFormat:@"Network Status Check"];
                welcome.hidden = false;
                [welcome setFont:[UIFont systemFontOfSize:22]];
                
                //firstResultReceived = false;
                
                speedometerReading.hidden=NO;
                downloadLabel.hidden=YES;
                uploadLabel.hidden=YES;
                delayLabel.hidden=YES;
                delayVariationLabel.hidden=YES;
                ul.hidden=YES;
                dl.hidden=YES;
                d.hidden=YES;
                dv.hidden=YES;
                downloadFinal.hidden = YES;
                uploadFinal.hidden = YES;
                delayFinal.hidden = YES;
                delayVariationFinal.hidden = YES;
                dFinal.hidden = YES;
                dlFinal.hidden = YES;
                ulFinal.hidden = YES;
                dvFinal.hidden = YES;
                
                uploadLabel.text = [NSString stringWithFormat:@"%.2f Mbps",0.00];
                downloadLabel.text = [NSString stringWithFormat:@"%.2f Mbps",0.00];
                delayLabel.text = [NSString stringWithFormat:@"%.2f ms",0.00];
                delayVariationLabel.text = [NSString stringWithFormat:@"%.2f ms",0.00];
                uploadLabel.textColor = [UIColor lightGrayColor];
                downloadLabel.textColor= [UIColor lightGrayColor];
                delayLabel.textColor= [UIColor lightGrayColor];
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Need to call this update on the main thread, as the Iperf thread seems to sometimes block this last label from updating -- usually after starting a test after another one has just finished
                    self->delayVariationLabel.textColor= [UIColor lightGrayColor];
                });
                startButton.hidden=YES;
                //gradeImage.hidden=YES;
                progress.hidden=NO;
                
                progress.text = @"Connectivity test...";
            }
            break;
        }
        case 1:{
            dispatch_async(dispatch_get_main_queue(), ^{
                speedometerReading.hidden = false;
                self->pulse.hidden = YES;
                self->meterSpot.hidden = NO;
                self->progressBar.hidden = false;
                self->indoorButton.hidden = true;
            //welcome.hidden = YES;
                self->welcome.text =[NSString stringWithFormat:@""];
            // Upload West
                currentTestLabelToUpdate = self->uploadLabel;
                self->progress.text = @"Testing with California server...";
            randomize = [NSTimer scheduledTimerWithTimeInterval:.1
                                                         target:self
                                                       selector:@selector(getRandomSpeedometerValues)
                                                       userInfo:nil
                                                        repeats:YES];
            [randomize fire];
                self->downloadLabel.hidden = YES;
                self->dl.hidden = YES;
                self->delayLabel.hidden = YES;
                self->d.hidden = YES;
                self->delayVariationLabel.hidden = YES;
                self->dv.hidden = YES;
                self->uploadLabel.hidden = NO;
                self->uploadLabel.text = [NSString stringWithFormat:@"%.2f Mbps",0.00];
                self->ul.hidden = NO;
            });
            break;
        }
        case 2:{
            // Download West
            currentTestLabelToUpdate = downloadLabel;
            dispatch_async(dispatch_get_main_queue(), ^{
                self->pulse.hidden = YES;
                self->uploadLabel.hidden = YES;
                self->ul.hidden = YES;
                self->delayLabel.hidden = YES;
                self->d.hidden = YES;
                self->delayVariationLabel.hidden = YES;
                self->dv.hidden = YES;
                self->downloadLabel.hidden = NO;
                self->downloadLabel.text = [NSString stringWithFormat:@"%.2f Mbps",0.00];
                self->dl.hidden = NO;
            });
            break;
        }
        case 3:{
            // Ping West
            currentTestLabelToUpdate = delayLabel;
            dispatch_async(dispatch_get_main_queue(), ^{
                self->pulse.image = [UIImage animatedImageNamed:@"delaygif" duration:2];
                self->pulse.hidden = NO;
                self->meterSpot.hidden = YES;
                self->downloadLabel.hidden = YES;
                self->dl.hidden = YES;
                self->uploadLabel.hidden = YES;
                self->ul.hidden = YES;
                self->delayVariationLabel.hidden = YES;
                self->dv.hidden = YES;
                self->delayLabel.hidden = NO;
                self->delayLabel.text = [NSString stringWithFormat:@"%.2f ms",0.00];
                self->d.hidden = NO;
            });
            break;
        }
        case 4:{
            // UDP West
            currentTestLabelToUpdate = delayVariationLabel;
            dispatch_async(dispatch_get_main_queue(), ^{
                self->pulse.image = [UIImage animatedImageNamed:@"pulse" duration:2];
                self->pulse.hidden = NO;
                self->meterSpot.hidden = YES;
                self->uploadLabel.hidden = YES;
                self->ul.hidden = YES;
                self->downloadLabel.hidden = YES;
                self->dl.hidden = YES;
                self->delayLabel.hidden = YES;
                self->d.hidden = YES;
                self->delayVariationLabel.hidden = NO;
                self->delayVariationLabel.text = [NSString stringWithFormat:@"%.2f ms",0.00];
                self->dv.hidden = NO;
            });
            break;
        }
        case 5:{
            // Upload East
            currentTestLabelToUpdate = uploadLabel;
            dispatch_async(dispatch_get_main_queue(), ^{
                speedometerReading.hidden = false;
                self->pulse.hidden = YES;
                self->meterSpot.hidden = NO;
                self->progress.text = @"Testing with Virginia server...";
                self->downloadLabel.hidden = YES;
                self->dl.hidden = YES;
                self->delayLabel.hidden = YES;
                self->d.hidden = YES;
                self->delayVariationLabel.hidden = YES;
                self->dv.hidden = YES;
                self->uploadLabel.hidden = NO;
                self->uploadLabel.text = [NSString stringWithFormat:@"%.2f Mbps",0.00];
                self->ul.hidden = NO;
            });
            break;
        }
        case 6:{
            // Download East
            currentTestLabelToUpdate = downloadLabel;
            dispatch_async(dispatch_get_main_queue(), ^{
                self->pulse.hidden = YES;
                self->uploadLabel.hidden = YES;
                self->ul.hidden = YES;
                self->delayLabel.hidden = YES;
                self->d.hidden = YES;
                self->delayVariationLabel.hidden = YES;
                self->dv.hidden = YES;
                self->downloadLabel.hidden = NO;
                self->downloadLabel.text= [NSString stringWithFormat:@"%.2f Mbps",0.00];
                self->dl.hidden = NO;
            });
            break;
        }
        case 7:{
            // Ping East
            currentTestLabelToUpdate = delayLabel;
            dispatch_async(dispatch_get_main_queue(), ^{
                if(self->readyToBegin.hidden == true)
                {
                self->pulse.hidden = NO;
                self->meterSpot.hidden = YES;
                self->pulse.image = [UIImage animatedImageNamed:@"delaygif" duration:2];
                self-> downloadLabel.hidden = YES;
                self->dl.hidden = YES;
                self->uploadLabel.hidden = YES;
                self->ul.hidden = YES;
                self->delayVariationLabel.hidden = YES;
                self->dv.hidden = YES;
                self->delayLabel.text= [NSString stringWithFormat:@"%.2f ms",0.00];
                self->delayLabel.hidden = NO;
                self->d.hidden = NO;
                }
            });
            break;
        }
        case 8:{
            // UDP East
            currentTestLabelToUpdate = delayVariationLabel;
            dispatch_async(dispatch_get_main_queue(), ^{
                if(self->readyToBegin.hidden == true)
                {
                self->meterSpot.hidden = YES;
                self->pulse.image = [UIImage animatedImageNamed:@"pulse" duration:2];
                self->delayLabel.hidden = YES;
                self->d.hidden = YES;
                self->uploadLabel.hidden = YES;
                self->ul.hidden = YES;
                self->downloadLabel.hidden = YES;
                self->dl.hidden = YES;
                self->delayVariationLabel.hidden = NO;
                self->delayVariationLabel.text= [NSString stringWithFormat:@"%.2f ms",0.00];
                self->dv.hidden = NO;
                }
            });
            break;
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        currentTestLabelToUpdate.textColor = [UIColor blackColor];
    });
}

// Called when a test segment has finished, handles
-(void)testSegmentFinished{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = false;
        currentTestLabelToUpdate.textColor = [UIColor lightGrayColor];
    
        // The progress bar often refuses to update unless it's called this way, no matter what
        [self->progressBar setProgress: [self->progressBar progress]+0.1 animated:YES]; // 10 segments now, so 1/10 = .1
    });
    switch (currentTestSegment) {
            
        case 0:{
            if(doTheProbeTest && probeTestCount == 2)
            {
                doTheProbeTest = 0;
                [vmScore setPhase:0];
            }
            break;
        }
            
        case 1:{
            
            // Upload West
            // Explicit call from main thread required due to the iPerf thread blocking calls while it's still being run
            //[randomize invalidate];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self resetSpeedometer];
                self->uploadLabel.textColor = [UIColor lightGrayColor];
                self->maxSpeedometerLabel.text =[[NSString alloc] initWithFormat:@"100"];
            });
            [vmScore setWestUpCount];
            break;
        }
        case 2:{
            // Download West
            //[randomize1 invalidate];
            [vmScore setWestDownCount];
            [vmScore setPhase:-1]; //so it doesn't store any UDP data
            [self resetSpeedometer];
            speedometerReading.hidden = true;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self->maxSpeedometerLabel.text =[[NSString alloc] initWithFormat:@"100"];
            });
            break;
        }
        case 5:{
            // Upload East
            // Explicit call from main thread required due to the iPerf thread blocking calls while it's still being run
            //[randomize2 invalidate];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self resetSpeedometer];
                self->uploadLabel.textColor = [UIColor lightGrayColor];
                self->maxSpeedometerLabel.text =[[NSString alloc] initWithFormat:@"100"];
            });
            
            [vmScore setEastUpCount];
            break;
        }
        case 6:{
            // Download East
            [randomize invalidate];
            [self resetSpeedometer];
            speedometerReading.hidden = true;
            dispatch_async(dispatch_get_main_queue(), ^{
                self->maxSpeedometerLabel.text =[[NSString alloc] initWithFormat:@"100"];
            });
            [vmScore setEastDownCount];
            break;
            
            // Each ping and UDP test case only needs to stop the spinner when each has completed,
            // so the case switches are able to be stacked for simplicity's sake
            // TO-DO: should probably just change this to the default case-- with updated animations for udp and ping, (at least some) these are needed actually
        }
        case 8:{ // UDP East
            pulse.hidden = YES;
            meterSpot.hidden = NO;
            [LoggingWrapper newReportAndPrint:[vmScore getStringRepresentation]];
            break;
        }
        case 3:{ // Ping West
            break;
        }
        case 4:{ // UDP West
            [vmScore setPhase:1];
            break;
        }
        case 7:{ // Ping East
            break;
        }
    }
    //firstResultReceived = false;
    [self newTestSegmentStarted];
}

// Resets the speedometer and its associated speed label to 0
-(void)resetSpeedometer{
    speedometerCurrentValue = 0;
    [self calculateDeviationAngle];
    speedometerReading.text = [NSString stringWithFormat:@"%.2f",0.00];
}

// Attempt at bringing focus to a new field being updated only when a result
// is about to be displayed. Doesn't function well, commenting out to get back to later
/*-(void)checkIfIsFirstResult{
 if(!firstResultReceived){
 firstResultReceived = true;
 [self newTestSegmentStarted];
 }
 }*/

// iPerfEngine delegate method
// Called when the preliminary connectivity test either succeeds or fails completely
-(void)connectivityTestDidFinishWithSuccess:(bool)didSucceed{
    if(didSucceed){
        //firstResultReceived = true;
        doTheProbeTest = 1;
        [self newTestSegmentStarted];
    }
    else{ //if connectivity failed
        //[self testDoneWithLat:0 withLong:0];
        welcome.text =[NSString stringWithFormat:@""];
        uploadSpeed = downloadSpeed = delay = delayVariation = phase1FinalUploadSpeed = phase1FinalDownloadSpeed = 0.0;
        
    }
}

// iPerfEngine delegate method
// Returns individual ping query results during a ping test
-(void)pingTestDidPingWithResult:(double)result{
    //[self checkIfIsFirstResult];
    [self updateDelayResult:result];
}

// iPerfEngine delegate method
// Called when a ping test is finished, returns the average ping result
-(void)pingTestDidFinishWithAverage:(double)average{
    delay = average;
    [MOSCalculation addPing:average];
    if(currentTestSegment == 3) //if it's the ping west test, store it
    {
        phase1FinalDelay = average;
    }
    else
    {
        [MOSCalculation addEastPing:average];
        average = (phase1FinalDelay + average) / 2.0;
        delay = average;
    }
        
    [self updateDelayResult:average];
    [self testSegmentFinished];
}

int resultUpCount = 5, resultDownCount = 5;
VMScore *vmScore;

// iPerfEngine delegate method
// Called when the last 4 iPerf server test queries are added together and a sum is found
-(void)serverTestDidReportDataSum:(int)resultSum{
    
    float resultToDisplay;
    if(resultSum > 99999998) resultSum = 0;//99999998
    if(currentTestSegment == 1) //reset for phase 2
        resultUpCount = resultDownCount = 5;
    if(currentTestSegment == 5) //if you're showing east upload results, use west final upload value
    {
        if(resultUpCount > 1) resultUpCount--;
        resultToDisplay = (((float)(resultSum + (phase1FinalUploadSpeed/resultUpCount))/2.0)/1024);
        
    }
    else if(currentTestSegment == 6) //if you're showing east download results, use west final download value
    {
        if(resultDownCount > 1) resultDownCount--;
        resultToDisplay = (((float)(resultSum + (phase1FinalDownloadSpeed/resultDownCount))/2.0)/1024);
    }
    else
    {
        resultToDisplay = (float)resultSum/1024;
    }
    /*if(resultCount == 1){
        //vmScore = [VMScore beginNewScore];
        //printf("NEW VMSCORE\n");
    }*/
    
    //else if(resultCount < 11)
    //    [vmScore addSpeed:resultToDisplay];
    //printf("Setting speedometer to: %f\n", resultToDisplay);
    //[self checkIfIsFirstResult];
    [self performSelectorOnMainThread:@selector(valueToSpeedometer:) withObject:@(resultToDisplay) waitUntilDone:false];
}

// iPerfEngine delegate method
// Returns the result of either an upload or download portion of an iPerf test (true for upload, false for download), with the given speed and count
-(void)serverTestDidCompletePortion:(bool)isDownload withSpeed:(int)resultSpeed withCount:(int)resultCount{
    resultCount = 0;
    //printf("%d HD, %d SD, %d LS\n", vmScore.HDcount, vmScore.SDcount, vmScore.LScount);
    double resultSpeedToUse = (float)resultSpeed/1024;
    //printf("Finished portion: %d, average speed: %f, count: %d\n\n", isDownload, resultSpeedToUse, resultCount);
    if(currentTestSegment == 1) //if you've reached end of upload portion, store for phase 2
    {
        phase1FinalUploadSpeed = resultSpeed;
        //printf("Phase1FinalUploadSpeed: %d\n", resultSpeed);
    }
    else if(currentTestSegment == 2) //if you've reached end of download portion, store for phase 2
    {
        printf("Phase1FinalDownloadSpeed: %d\n", resultSpeed);
        phase1FinalDownloadSpeed = resultSpeed;
    }
    if(VIDM.phase != 2)
    {
        if(!isDownload){
            uploadSpeed = resultSpeedToUse;
        }
        else{
            downloadSpeed = resultSpeedToUse;
        }
        [self updateCurrentTestLabelFromResult: resultSpeedToUse];
    }
    
    [self testSegmentFinished];
}

// iPerfEngine delegate method
// Returns the result of a UDP test
-(void)didReceiveUDPResult:(double)result{
    double resultToUse = result*1000;
    [MOSCalculation addJitter:resultToUse];
    delayVariation = resultToUse;
    if(currentTestSegment == 4) //if it's UDP West, store it as Phase 1 result
    {
        phase1FinalDelayVariation = delayVariation;
    }
    else
    {
        delayVariation = (delayVariation + phase1FinalDelayVariation) / 2.0; //during other UDP, average it
        [MOSCalculation addEastJitter:resultToUse];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateDelayResult:delayVariation];
    });
    
    //printf("UDP result: %f\n", result);
    if(currentTestSegment == 8)//if(currentTestSegment != 4)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self->progress.text = @"Finalizing Results..."; //to account for uploading pause in low signal area
        });
    }
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if(cnx_error == 0)
            [self testSegmentFinished];
    });
    //[self testSegmentFinished];
}

-(void)serverTestDidTimeout{
    printf("SERVER TEST TIMED OUT!!!!!!!\n");
}

// iPerfEngine delegate method
// Called when the standard test has completely finished
-(void)standardTestDidFinishWithFinalLocationLatitude:(double)latitude withLongitude:(double)longitude{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self->connectedToWifiLabel.hidden = false;
        self->readyToBegin.hidden = false;
        self->downloadLabel.hidden = YES;
        self->dl.hidden = YES;
        self->uploadLabel.hidden = YES;
        self->ul.hidden = YES;
        self->delayVariationLabel.hidden = YES;
        self->dv.hidden = YES;
        self->delayLabel.hidden = YES;
        self->d.hidden = YES;
    });
    [self testDoneWithLat:latitude withLong:longitude];
}

// "Start Test" button event handler
-(IBAction)startTestButtonPressed:(id)sender{
    if(sender != nil && [[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] == ReachableViaWiFi){
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"You're connected to Wi-Fi!" message:@"Would you like to use Wi-Fi?" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Wi-Fi" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            [self startTestButtonPressed:nil];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alert animated:true completion:nil];
        return;
    }
    
    //hide labels during connectivity test
    inOutSwitch.hidden = true;
    inOutLabel.hidden = true;
    indoorButton.hidden = true;
    
    iperf_timeout = cnx_error = 0; //as soon as a new test is launched, zero errors out.
    for(int i = 0; i < 10; i++) probe_ary[i] = 0;
    reported_probe_speed = 0;
    if(startButtonMaximized){
        startButtonMaximized = false;
        startButton.translatesAutoresizingMaskIntoConstraints = true;
        [UIView animateWithDuration:0.25 animations:^{
            self->startButton.titleLabel.font = [self->startButton.titleLabel.font fontWithSize:15];
            if(IS_IPHONE_4_OR_LESS)
                [self->startButton setFrame:CGRectMake(40, 400, 240, 30)];
            //else if(@available(iOS 11,*))
            else if([self isIphoneX])
            {
                self->startButton.frame = CGRectMake(60, 390, 200, 30);
                self->startButton.backgroundColor = [UIColor colorWithRed:86/255.0 green:178/255.0 blue:227/255.0 alpha:1.0];

                self->readyToBegin.text =[NSString stringWithFormat:@""];
            }
            else
                self->startButton.frame = CGRectMake(36, 482, 245, 30);
        }completion:^(BOOL finished){
            [self startTestButtonPressed:nil];
        }];
        return;
    }
    if([iperfEngine startTest]){
        networkType = [[LoggingWrapper getDeviceInformation] getConnectionType];
        startDate = [NSDate date];
        currentTestSegment = -1;
        doTheProbeTest = 0;
        probeTestCount = 0;
        [self newTestSegmentStarted];
    }
}

// Sets the speedometer and its associated speed label to a given value
-(void)valueToSpeedometer:(id)idFloat{//(float)value{
    float valueToUse = [idFloat floatValue];
    speedometerCurrentValue = valueToUse;
    [self calculateDeviationAngle];
    [self updateCurrentTestLabelFromResult: valueToUse];
    speedometerReading.text = [NSString stringWithFormat:@"%.2f",valueToUse];
}

// Updates and displays the new value of a given delay (ping test) or
// delay variation (UDP test) result. Is used for both types for simplicity
// when interacting with the UI, but does not affect results at all
-(void)updateDelayResult:(float)delayResult{//(id)idDelayResult{
    //float delayToUse = [idDelayResult floatValue];
    currentDelayResult = delayResult;
    [self updateCurrentTestLabelFromResult: 0];
}

//####################################################


-(void) loadMeterView{
    UIImageView *meterImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, meterSpot.frame.size.width, meterSpot.frame.size.height)];//16 80
    meterImageView.image = [UIImage imageNamed:@"meter.png"];
    
    [meterSpot addSubview:meterImageView];
    meterImageView.contentMode = UIViewContentModeScaleToFill;
    
    //  Needle //
    UIImageView *imgNeedle;
    if (IS_IPHONE_4_OR_LESS){
        imgNeedle = [[UIImageView alloc]initWithFrame:CGRectMake(138,meterImageView.frame.size.height*.53, 9, 87)];
    }
    else{
        imgNeedle = [[UIImageView alloc]initWithFrame:CGRectMake(139,meterImageView.frame.size.height*.566, 9, 88)];//150.5, 193
    }
    needleImageView = imgNeedle;
    
    needleImageView.layer.anchorPoint = CGPointMake(needleImageView.layer.anchorPoint.x, needleImageView.layer.anchorPoint.y*2);
    needleImageView.backgroundColor = [UIColor clearColor];
    needleImageView.image = [UIImage imageNamed:@"arrow.png"];
    [meterSpot addSubview:needleImageView];
    
    // Needle Dot //
    UIImageView *meterImageViewDot = [[UIImageView alloc]initWithFrame:CGRectMake(meterImageView.frame.size.width/2 - 12, meterImageView.frame.size.height*.71, 24,24)];//143.5,224
    meterImageViewDot.image = [UIImage imageNamed:@"center_wheel.png"];
    [meterSpot addSubview:meterImageViewDot];
    
    // Speedometer Reading //
    /*UILabel *tempReading = [[UILabel alloc] initWithFrame:CGRectMake(114, meterImageView.frame.size.height*.4, 60, 30)];//130, 185
     speedometerReading = tempReading;
     speedometerReading.textAlignment = NSTextAlignmentCenter;
     speedometerReading.backgroundColor = [UIColor clearColor];
     speedometerReading.text= @"0";
     speedometerReading.textColor = [UIColor darkGrayColor];
     [meterSpot addSubview:speedometerReading ];*/
    
    // Set Max Value //
    maxVal = @"100";
    maxVal1 = @"3";
    maxVal2 = @"15";
    maxVal3 = @"22.5";
    maxVal4 = @"30";
    maxVal5 = @"60";
    /// Set Needle pointer initialy at zero //
    [self rotateNeedleToAngle:-106];//-62
    
    // Set previous angle //
    prevAngleFactor = -106;
}



#pragma mark -
#pragma mark calculateDeviationAngle Method

-(void) calculateDeviationAngle
{
    
    if([maxVal floatValue]>0 && speedometerCurrentValue <= [maxVal1 floatValue])
    {
        angle = ((speedometerCurrentValue *46)/[maxVal1 floatValue])-106;  // 237.4 - Total angle between 0 - 3 //33
    }
    //All of the cases below follow the same equation set-up:
    // ^ the 33 is the angle that 1(upper bound) is located on the speedometer
    // ^ the 93 is the angle from the center to the lower bound, 0 on the speedometer
    else if([maxVal floatValue]>0 && speedometerCurrentValue <= [maxVal2 floatValue])
    {
        angle = ((speedometerCurrentValue *50)/[maxVal2 floatValue])-70;  // 237.4 - Total angle between 3 - 15 //65
    }
    else if([maxVal floatValue]>0 && speedometerCurrentValue <= [maxVal3 floatValue])
    {
        angle = ((speedometerCurrentValue *60)/[maxVal3 floatValue])-60;  // 237.4 - Total angle between 15 -22.5  //
    }
    else if([maxVal floatValue]>0 && speedometerCurrentValue <= [maxVal4 floatValue])
    {
        angle = ((speedometerCurrentValue *80)/[maxVal4 floatValue])-60;  // 237.4 - Total angle between 22.5 - 30  //
    }
    else if([maxVal floatValue]>0 && speedometerCurrentValue <= [maxVal5 floatValue])
    {
        angle = ((speedometerCurrentValue *80)/[maxVal5 floatValue] - 20);  // 237.4 - Total angle between 30 - 60 //65
        // x + y = 62     y = 62 - x
        // .5x - y = 18    80  = 1.5x
    }
    else if([maxVal floatValue]>0)
    {
        angle = ((speedometerCurrentValue *115)/[maxVal floatValue])- 9;  // 237.4 - Total angle between 60 - 100 //65
        //107 = x + y   y = 107 - x
        //y = 62 - 2/3 x     1/3 x = 45
    }
    else
    {
        angle = -106;
    }
    
    if(angle<=-106) angle = -106;
    if(angle>=107) angle = 107;
    
    // If Calculated angle is greater than 180 deg, to avoid the needle to rotate in reverse direction first rotate the needle 1/3 of the calculated angle and then 2/3. //
    if(fabsf(angle-prevAngleFactor) >180)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.5f];
        [self rotateNeedleToAngle:angle/3];
        [UIView commitAnimations];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.5f];
        [self rotateNeedleToAngle:(angle*2)/3];
        [UIView commitAnimations];
    }
    
    prevAngleFactor = angle;
    
    // Rotate Needle //
    [self rotateNeedle];
    
}

-(void) calculateDeviationAngleExtra:(float) fake //this is exactly the same as the calculateDeviationAngle method, but does not use the speedometerCurrentValue variable, because it is just to make it look like the speedometer is changing a lot more than it really is. (fake values)
{
    if([maxVal floatValue]>0 && speedometerCurrentValue <= [maxVal1 floatValue])
    {
        angle = ((speedometerCurrentValue *46)/[maxVal1 floatValue])-106;  // 237.4 - Total angle between 0 - 3 //33
    }
    //All of the cases below follow the same equation set-up:
    // ^ the 33 is the angle that 1(upper bound) is located on the speedometer
    // ^ the 93 is the angle from the center to the lower bound, 0 on the speedometer
    else if([maxVal floatValue]>0 && speedometerCurrentValue <= [maxVal2 floatValue])
    {
        angle = ((speedometerCurrentValue *50)/[maxVal2 floatValue])-70;  // 237.4 - Total angle between 3 - 15 //65
    }
    else if([maxVal floatValue]>0 && speedometerCurrentValue <= [maxVal3 floatValue])
    {
        angle = ((speedometerCurrentValue *60)/[maxVal3 floatValue])-60;  // 237.4 - Total angle between 15 -22.5  //
    }
    else if([maxVal floatValue]>0 && speedometerCurrentValue <= [maxVal4 floatValue])
    {
        angle = ((speedometerCurrentValue *80)/[maxVal4 floatValue])-60;  // 237.4 - Total angle between 22.5 - 30  //
    }
    else if([maxVal floatValue]>0 && speedometerCurrentValue <= [maxVal5 floatValue])
    {
        angle = ((speedometerCurrentValue *80)/[maxVal5 floatValue] - 20);  // 237.4 - Total angle between 30 - 60 //65
        // x + y = 62     y = 62 - x
        // .5x - y = 18    80  = 1.5x
    }
    else if([maxVal floatValue]>0)
    {
        angle = ((speedometerCurrentValue *115)/[maxVal floatValue])- 9;  // 237.4 - Total angle between 60 - 100 //65
        //107 = x + y   y = 107 - x
        //y = 62 - 2/3 x     1/3 x = 45
    }
    else
    {
        angle = -106;
    }
    
    if(angle<=-106) angle = -106;
    if(angle>=107) angle = 107;
    
    // If Calculated angle is greater than 180 deg, to avoid the needle to rotate in reverse direction first rotate the needle 1/3 of the calculated angle and then 2/3. //
    if(fabsf(angle-prevAngleFactor) >180)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.5f];
        [self rotateNeedleToAngle:angle/3];
        [UIView commitAnimations];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.5f];
        [self rotateNeedleToAngle:(angle*2)/3];
        [UIView commitAnimations];
    }
    
    prevAngleFactor = angle;
    
    // Rotate Needle //
    [self rotateNeedle];
    
}

#pragma mark -
#pragma mark rotateNeedle Method
-(void) rotateNeedle
{
    dispatch_async(dispatch_get_main_queue(), ^{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3f];
    [needleImageView setTransform: CGAffineTransformMakeRotation((M_PI / 180) * angle)];
    [UIView commitAnimations];
    });
    
}

#pragma mark -
#pragma mark Speedometer needle Rotation View Methods

-(void) rotateNeedleToAngle:(float)angl
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.1f];
    dispatch_async(dispatch_get_main_queue(), ^{
        [needleImageView setTransform: CGAffineTransformMakeRotation((M_PI / 180) *angl)];
    });
    [UIView commitAnimations];
}


- (IBAction)indoorAction {
    if (indoor == YES) {
        inOutLabel.text = @"Outdoor";
        indoor = NO;
        UIImage *btnImage = [UIImage imageNamed:@"outdoor.png"];
        [indoorButton setImage:btnImage forState:UIControlStateNormal];
        [LoggingWrapper setDoorStatus:@"Outdoors"];
    }
    else {
        inOutLabel.text = @"Indoor";
        indoor = YES;
        UIImage *btnImage = [UIImage imageNamed:@"indoor.png"];
        [indoorButton setImage:btnImage forState:UIControlStateNormal];
        [LoggingWrapper setDoorStatus:@"Indoors"];
    }
    
}
- (void)hideTabBar:(UITabBarController *) tabbarcontroller
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:.5];
    
    for(UIView *view in tabbarcontroller.view.subviews)
    {
        if([view isKindOfClass:[UITabBar class]])
        {
            [view setFrame:CGRectMake(view.frame.origin.x, 480, view.frame.size.width, view.frame.size.height)];
        }
        else
        {
            [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, 480)];
        }
    }
    
    [UIView commitAnimations];
}
- (void)showTabBar:(UITabBarController *) tabbarcontroller
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    for(UIView *view in tabbarcontroller.view.subviews)
    {
        NSLog(@"%@", view);
        
        if([view isKindOfClass:[UITabBar class]])
        {
            [view setFrame:CGRectMake(view.frame.origin.x, 431, view.frame.size.width, view.frame.size.height)];
            
        }
        else
        {
            [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, 431)];
        }
    }
    
    [UIView commitAnimations];
}

- (void) testDoneWithLat:(double)finalLat withLong:(double)finalLong{
    progressBar.hidden = true;
    if(!IS_IPHONE_4_OR_LESS)
        indoorButton.hidden = false;
    inOutLabel.hidden = false;
    inOutSwitch.hidden = false;
    [self.tabBarController.tabBar setHidden:NO];
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = false;
        [self resetSpeedometer];
        self->pulse.hidden = YES;
        speedometerReading.hidden = false;
        self->meterSpot.hidden = NO;
        self->downloadLabel.textColor=[UIColor blackColor];
        self->uploadLabel.textColor=[UIColor blackColor];
        self->delayLabel.textColor=[UIColor blackColor];
        self->delayVariationLabel.textColor=[UIColor blackColor];
        self->satisfyLabel.hidden = true;
        self->mosDescriptionLabel.hidden = false;
        self->startButton.hidden=NO;
        self->progress.hidden=YES;
        self->progressBar.hidden=YES;
        self->downloadLabel.hidden=YES;
        self->uploadLabel.hidden=YES;
        self->delayLabel.hidden=YES;
        self->delayVariationLabel.hidden=YES;
        self->ul.hidden=YES;
        self->dl.hidden=YES;
        self->d.hidden=YES;
        self->dv.hidden=YES;
        self->satisfyLabel.adjustsFontSizeToFitWidth = YES;
    });
    //make sure to incorporate phase1 results for an average reading
    uploadSpeed = (uploadSpeed + phase1FinalUploadSpeed/1024) / 2.0;
    downloadSpeed = (downloadSpeed + phase1FinalDownloadSpeed/1024) / 2.0;
    
    double mosScore = [MOSCalculation getMOS];
    if(mosScore > 4){
        satisfyLabel.text = @"Satisfactory";
    }
    else{
        satisfyLabel.text = @"Unsatisfactory";
    }
    satisfyLabel.layer.zPosition = 1;
    
    if(cnx_error == 1)
    {
        uploadSpeed = downloadSpeed = delay = delayVariation = phase1FinalUploadSpeed = phase1FinalDownloadSpeed = 0.0;
        uploadFinal.text = [NSString stringWithFormat:@"N/A"];
        downloadFinal.text = [NSString stringWithFormat:@"N/A"];
        delayFinal.text = [NSString stringWithFormat:@"N/A"];
        delayVariationFinal.text = [NSString stringWithFormat:@"N/A"];
        satisfyLabel.text = @"Network error. Try again later.";
        mosDescriptionLabel.text = @"";
        
        [pulse setHidden: TRUE];
        [speedometerReading setHidden: FALSE];
        [meterSpot setHidden: FALSE];
        [satisfyLabel setHidden: FALSE];
        [mosDescriptionLabel setHidden: FALSE];
        [startButton setHidden: FALSE];
        [progress setHidden: TRUE];
        [progressBar setHidden: TRUE];
        [downloadLabel setHidden: TRUE];
        [uploadLabel setHidden: TRUE];
        [delayLabel setHidden: TRUE];
        [delayVariationLabel setHidden: TRUE];
        [ul setHidden: TRUE];
        [dl setHidden: TRUE];
        [d setHidden: TRUE];
        [dv setHidden: TRUE];
        
        downloadFinal.hidden=NO;
        uploadFinal.hidden=NO;
        delayFinal.hidden=NO;
        delayVariationFinal.hidden=NO;
        ulFinal.hidden=NO;
        dlFinal.hidden=NO;
        dFinal.hidden=NO;
        dvFinal.hidden=NO;
    
        NSString *videoMetric = @"N/A";
        NSString *videoConference = @"N/A";
        NSString *voip = @"N/A";
        [CoreDataManager createStandardTestResultWithStartDate:startDate
                                                    withUpload:uploadSpeed
                                                  withDownload:downloadSpeed
                                                     withDelay:delay
                                            withDelayVariation:delayVariation
                                               withNetworkType:networkType
                                                  withLatitude:finalLat
                                                 withLongitude:finalLong
                                          withMeanOpinionScore:mosScore
                                               withVideoMetric:videoMetric
                                           withVideoConference:videoConference
                                                      withVoip:voip];
        
        [MOSCalculation clearData];
        networkType = nil;
        return;
    }
    
    //if the test timed out
    if(iperf_timeout == 1)
    {
        uploadSpeed = downloadSpeed = delay = delayVariation = phase1FinalUploadSpeed = phase1FinalDownloadSpeed = 0.0;
        uploadFinal.text = [NSString stringWithFormat:@"N/A"];
        downloadFinal.text = [NSString stringWithFormat:@"N/A"];
        delayFinal.text = [NSString stringWithFormat:@"N/A"];
        delayVariationFinal.text = [NSString stringWithFormat:@"N/A"];
        satisfyLabel.text = @"Test Timeout. Try again later.";
        mosDescriptionLabel.text = @"";
        
        [pulse setHidden: TRUE];
        [speedometerReading setHidden: FALSE];
        [meterSpot setHidden: FALSE];
        [satisfyLabel setHidden: FALSE];
        [mosDescriptionLabel setHidden: FALSE];
        [startButton setHidden: FALSE];
        [progress setHidden: TRUE];
        [progressBar setHidden: TRUE];
        [downloadLabel setHidden: TRUE];
        [uploadLabel setHidden: TRUE];
        [delayLabel setHidden: TRUE];
        [delayVariationLabel setHidden: TRUE];
        [ul setHidden: TRUE];
        [dl setHidden: TRUE];
        [d setHidden: TRUE];
        [dv setHidden: TRUE];
        
        downloadFinal.hidden=NO;
        uploadFinal.hidden=NO;
        delayFinal.hidden=NO;
        delayVariationFinal.hidden=NO;
        ulFinal.hidden=NO;
        dlFinal.hidden=NO;
        dFinal.hidden=NO;
        dvFinal.hidden=NO;
    
        NSString *videoMetric = @"N/A";
        NSString *videoConference = @"N/A";
        NSString *voip = @"N/A";
        [CoreDataManager createStandardTestResultWithStartDate:startDate
                                                    withUpload:uploadSpeed
                                                  withDownload:downloadSpeed
                                                     withDelay:delay
                                            withDelayVariation:delayVariation
                                               withNetworkType:networkType
                                                  withLatitude:finalLat
                                                 withLongitude:finalLong
                                          withMeanOpinionScore:mosScore
                                               withVideoMetric:videoMetric
                                           withVideoConference:videoConference
                                                      withVoip:voip];
        
        [MOSCalculation clearData];
        networkType = nil;
        return;
    }
    
    if(uploadSpeed == 0 && downloadSpeed == 0 && delay == 0 && delayVariation == 0) //Failed conn test
    {
        uploadFinal.text = [NSString stringWithFormat:@"N/A"];
        downloadFinal.text = [NSString stringWithFormat:@"N/A"];
        delayFinal.text = [NSString stringWithFormat:@"N/A"];
        delayVariationFinal.text = [NSString stringWithFormat:@"N/A"];
        satisfyLabel.text = @"No connection. Try again later.";
        mosDescriptionLabel.text = @"";
        
        downloadFinal.hidden=NO;
        uploadFinal.hidden=NO;
        delayFinal.hidden=NO;
        delayVariationFinal.hidden=NO;
        ulFinal.hidden=NO;
        dlFinal.hidden=NO;
        dFinal.hidden=NO;
        dvFinal.hidden=NO;
        
        NSString *videoMetric = @"N/A";
        NSString *videoConference = @"N/A";
        NSString *voip = @"N/A";
        [CoreDataManager createStandardTestResultWithStartDate:startDate
                                                    withUpload:uploadSpeed
                                                  withDownload:downloadSpeed
                                                     withDelay:delay
                                            withDelayVariation:delayVariation
                                               withNetworkType:networkType
                                                  withLatitude:finalLat
                                                 withLongitude:finalLong
                                          withMeanOpinionScore:mosScore
                                               withVideoMetric:videoMetric
                                           withVideoConference:videoConference
                                                      withVoip:voip];

        [MOSCalculation clearData];
        networkType = nil;
        return;
    }
    else
    {
        if(uploadSpeed == 0)
            uploadFinal.text =[[NSString alloc] initWithFormat:@"N/A"];
        else
            uploadFinal.text =[[NSString alloc] initWithFormat:@"%.02f Mbps", uploadSpeed];
        
        if(downloadSpeed == 0)
            downloadFinal.text =[[NSString alloc] initWithFormat:@"N/A"];
        else
            downloadFinal.text =[[NSString alloc] initWithFormat:@"%.02f Mbps", downloadSpeed];
        
        if(delay == 0)
            delayFinal.text =[[NSString alloc] initWithFormat:@"N/A"];
        else
            delayFinal.text =[[NSString alloc] initWithFormat:@"%.02f ms", delay];
        
        if(delayVariation == 0)
            delayVariationFinal.text =[[NSString alloc] initWithFormat:@"N/A"];
        else
            delayVariationFinal.text =[[NSString alloc] initWithFormat:@"%.02f ms", delayVariation];
    }
    downloadFinal.hidden=NO;
    uploadFinal.hidden=NO;
    delayFinal.hidden=NO;
    delayVariationFinal.hidden=NO;
    ulFinal.hidden=NO;
    dlFinal.hidden=NO;
    dFinal.hidden=NO;
    dvFinal.hidden=NO;
    mosDescriptionLabel.text = @"Mean Opinion Score";
    
    NSString *videoMetric = [self calculateVideoMetricForDatabase];
    NSString *voip = [MOSCalculation calcVoip];
    printf("*** VOIP = %s ***\n", [voip UTF8String]);
    NSString *videoConference = [self calculateVideoConferenceForDatabase];
    printf("*** Video Conf = %s ***\n", [videoConference UTF8String]);
    //printf("*** Vid Metric: %s ***\n",[videoMetric UTF8String]);
    [CoreDataManager createStandardTestResultWithStartDate:startDate
                                                withUpload:uploadSpeed
                                              withDownload:downloadSpeed
                                                 withDelay:delay
                                        withDelayVariation:delayVariation
                                           withNetworkType:networkType
                                              withLatitude:finalLat
                                             withLongitude:finalLong
                                      withMeanOpinionScore:mosScore
                                           withVideoMetric:videoMetric
                                       withVideoConference:videoConference
                                                  withVoip:voip];
    [MOSCalculation clearData];
    networkType = nil;
    
}

// we only need to look at the download speeds for this calculation.
-(NSString*)calculateVideoMetricForDatabase{
    int downHD = 0,
        downSD = 0,
        downLS = 0;
    
    int minThread = 100;
    for(int i = 0; i < VIDM.west_number_of_threads; i++) //check all valid threads in columns
    {
        int count = 0; //start count at 0
        int j = VIDM.download_start_ind[i]; //find the start index for download for this column
        while(VIDM.time[j][i] != -1) // j, the time, and i, the column. -1 will be at end.
        {
            count++;
            j++;
        }
        if(count < minThread) //if we found a new minimum
            minThread = count; // store this as the new minimum
    }
    
    int copy_down_start[64];
    memcpy(copy_down_start, VIDM.download_start_ind, sizeof(VIDM.download_start_ind));
    
    for(int i = 0; i < minThread; i++)
    {
        int sum = 0;
        for(int j = 0; j < VIDM.west_number_of_threads; j++)
        {
            sum += VIDM.data[copy_down_start[j]][j]; //add the data at the correct start download index
            copy_down_start[j]++; //make sure next time use the next download time
        }
        
        if (sum > 2500)
            downHD++;
        else if (sum > 700)
            downSD++;
        else
            downLS++;
    }
    
    if (downHD >= 9)
        //"High Definition";
        return @"HD";
    else if ((downHD + downSD) >= 9)
        //"Standard Definition";
        return @"SD";
    else if(((downHD + downSD + downLS) >= 9))
        //return "Low Def";
        return @"LD";
    else
        //cannot calculate
        return @"N/A";
    
}

-(NSString*)calculateVideoConferenceForDatabase{
    int downHD = 0,
        downSD = 0,
        downLS = 0,
        upHD = 0,
        upSD = 0,
        upLS = 0;
    
    //now let's see which thread was the min
    // we do this to make sure that if a slow connection didn't allow one of the threads
    // to finish, then we don't count as a zero with other threads and instead only look
    // at times where all threads completed.
    int minThread = 100;
    
    for(int i = 0; i < VIDM.west_number_of_threads; i++) // check all valid threads in columns
    {
        if(VIDM.download_start_ind[i] < minThread)  // if we found a new minimum
            minThread = VIDM.download_start_ind[i]; // store this as the new minimum
    }
    
    //for loop to count all the values for upload in the array
    for(int i = 0; i < minThread; i++) // for our row.
    {
        int sum = 0;
        
        for(int j = 0; j < VIDM.west_number_of_threads; j++)
            sum += VIDM.data[i][j];
        
        if (sum > 2500)
            upHD++;
        else if (sum > 700)
            upSD++;
        else
            upLS++;
    }
    
    minThread = 100; //reset minThread to 100
    
    for(int i = 0; i < VIDM.west_number_of_threads; i++) //check all valid threads in columns
    {
        int count = 0; //start count at 0
        int j = VIDM.download_start_ind[i]; //find the start index for download for this column
        while(VIDM.time[j][i] != -1) // j, the time, and i, the column. -1 will be at end.
        {
            count++;
            j++;
        }
        if(count < minThread) //if we found a new minimum
            minThread = count; // store this as the new minimum
    }
    
    int copy_down_start[64];
    memcpy(copy_down_start, VIDM.download_start_ind, sizeof(VIDM.download_start_ind));
    
    for(int i = 0; i < minThread; i++)
    {
        int sum = 0;
        for(int j = 0; j < VIDM.west_number_of_threads; j++)
        {
            sum += VIDM.data[copy_down_start[j]][j]; //add the data at the correct start download index
            copy_down_start[j]++; //make sure next time use the next download time
        }
        if (sum > 2500)
            downHD++;
        else if (sum > 700)
            downSD++;
        else
            downLS++;
    }
    
    upHD = upSD = upLS = downHD = downSD = downLS = 0; // zero them again TODO: Why do we bother with part 1??
    
    int eastMinThreadUp = 100;
    
    for(int i = 32; i < (32 + VIDM.east_number_of_threads); i++) // check all valid threads in columns
    {
        if(VIDM.download_start_ind[i] < eastMinThreadUp)  // if we found a new minimum
            eastMinThreadUp = VIDM.download_start_ind[i]; // store this as the new minimum
    }
    
    //for loop to count all the values for upload in the array
    for(int i = 0; i < eastMinThreadUp; i++) // for our row.
    {
        int sum = 0;
        
        for(int j = 32; j < (32 + VIDM.east_number_of_threads); j++)
            sum += VIDM.data[i][j];
        
        if (sum > 2500)
            upHD++;
        else if (sum > 700)
            upSD++;
        else
            upLS++;
    }
    
    int eastMinThreadDown = 100;
    
    for(int i = 0; i < VIDM.east_number_of_threads; i++) //check all valid threads in columns
    {
        int count = 0; //start count at 0
        int j = VIDM.download_start_ind[i]; //find the start index for download for this column
        while(VIDM.time[j][i] != -1) // j, the time, and i, the column. -1 will be at end.
        {
            count++;
            j++;
        }
        if(count < eastMinThreadDown) //if we found a new minimum
            eastMinThreadDown = count; // store this as the new minimum
    }
    
    for(int i = 0; i < eastMinThreadDown; i++)
    {
        int sum = 0;
        for(int j = 32; j < (32 + VIDM.east_number_of_threads); j++)
        {
            sum += VIDM.data[copy_down_start[j]][j]; //add the data at the correct start download index
            copy_down_start[j]++; //make sure next time use the next download time
        }
        if (sum > 2500)
            downHD++;
        else if (sum > 700)
            downSD++;
        else
            downLS++;
    }
    
    if (eastMinThreadUp < 10 && eastMinThreadDown < 10 && ([MOSCalculation getEastMOS] <= 0.0))
        return @"N/A";
    else if ([MOSCalculation getEastMOS]  < 4.0)
        return @"LD";
    else if (downHD >= 9 && upHD >= 9)
        return @"HD";
    else if (upHD + upSD >= 9 && downHD + downSD >= 9)
        return @"SD";
    else if (upHD + upSD + upLS >= 10 && downHD + downSD + downLS >= 10)
        return @"LD";
    else
        return @"N/A";
}


-(void)getRandomSpeedometerValues{
    float randomSpeed;
    double rand;
    if (speedometerCurrentValue < 1.5)
    {
        rand = arc4random_uniform(10);
        rand = rand - 5;
        rand = rand / 100.0;
    }
    else{
        rand = arc4random_uniform(100);
        rand = rand - 50;
        rand = rand / 100.0;
    }
    randomSpeed = speedometerCurrentValue + rand;
    if (randomSpeed < 0)
        randomSpeed = 0.01;
    [self calculateDeviationAngleExtra:randomSpeed];
    speedometerReading.text =[[NSString alloc] initWithFormat:@"%.02f", randomSpeed];
    if(randomSpeed > 100)
    {
        maxSpeedometerLabel.text =[[NSString alloc] initWithFormat:@"%.02f", randomSpeed];
        
    }
    else {
        maxSpeedometerLabel.text =[[NSString alloc] initWithFormat:@"100"];
    }
    return;
}

-(void) resizeConstraints{
    [uploadLabel removeConstraints:uploadLabel.constraints];
    uploadLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    uploadLabel.translatesAutoresizingMaskIntoConstraints = YES;
    
    [downloadLabel removeConstraints:downloadLabel.constraints];
    downloadLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    downloadLabel.translatesAutoresizingMaskIntoConstraints = YES;
    
    [delayLabel removeConstraints:delayLabel.constraints];
    delayLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    delayLabel.translatesAutoresizingMaskIntoConstraints = YES;
    
    [delayVariationLabel removeConstraints:delayVariationLabel.constraints];
    delayVariationLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    delayVariationLabel.translatesAutoresizingMaskIntoConstraints = YES;
    
    [uploadFinal removeConstraints:uploadFinal.constraints];
    uploadFinal.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    uploadFinal.translatesAutoresizingMaskIntoConstraints = YES;
    
    [downloadFinal removeConstraints:downloadFinal.constraints];
    downloadFinal.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    downloadFinal.translatesAutoresizingMaskIntoConstraints = YES;
    
    [delayFinal removeConstraints:delayFinal.constraints];
    delayFinal.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;    delayFinal.translatesAutoresizingMaskIntoConstraints = YES;
    
    [delayVariationFinal removeConstraints:delayVariationFinal.constraints];
    delayVariationFinal.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    delayVariationFinal.translatesAutoresizingMaskIntoConstraints = YES;
    
    [progressBar removeConstraints:progressBar.constraints];
    progressBar.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    progressBar.translatesAutoresizingMaskIntoConstraints = YES;
    
    [progress removeConstraints:progress.constraints];
    progress.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    progress.translatesAutoresizingMaskIntoConstraints = YES;
    
    [maxSpeedometerLabel removeConstraints:maxSpeedometerLabel.constraints];
    maxSpeedometerLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    maxSpeedometerLabel.translatesAutoresizingMaskIntoConstraints = YES;
    
    [ulFinal removeConstraints:ul.constraints];
    ulFinal.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    ulFinal.translatesAutoresizingMaskIntoConstraints = YES;
    
    [dlFinal removeConstraints:dlFinal.constraints];
    dlFinal.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    dlFinal.translatesAutoresizingMaskIntoConstraints = YES;
    
    [dFinal removeConstraints:dFinal.constraints];
    dFinal.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;    dFinal.translatesAutoresizingMaskIntoConstraints = YES;
    
    [dvFinal removeConstraints:dvFinal.constraints];
    dvFinal.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    dvFinal.translatesAutoresizingMaskIntoConstraints = YES;
    
    [meterSpot removeConstraints:meterSpot.constraints];
    meterSpot.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    meterSpot.translatesAutoresizingMaskIntoConstraints = YES;
    
    [startButton removeConstraints:startButton.constraints];
    startButton.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    startButton.translatesAutoresizingMaskIntoConstraints = YES;
}


@end
