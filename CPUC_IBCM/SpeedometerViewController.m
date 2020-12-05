//
//  SpeedometerViewController.m
//  CalBroadband
//
//  Created by localadmin on 5/28/15.
//  Copyright (c) 2015 CSUMB. All rights reserved.
//

#import <Foundation/Foundation.h>
[objc highlight=”28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,127,128,129,130,131,132,133,134,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,158,159,160,161,162,163,164,165,166″]

@implementation SpeedometerViewController
@synthesize needleImageView;
@synthesize speedometerCurrentValue;
@synthesize prevAngleFactor;
@synthesize angle;
@synthesize speedometer_Timer;
@synthesize speedometerReading;
@synthesize maxVal;

– (void)viewDidLoad {
    
    // Add Meter Contents //
    [self addMeterViewContents];
    
    [super viewDidLoad];
}
– (void)dealloc {
    [maxVal release];
    [needleImageView release];
    [speedometer_Timer release];
    [speedometerReading release];
    [super dealloc];
}

#pragma mark –
#pragma mark addMeterViewContents Methods

-(void) addMeterViewContents
{
    
    UIImageView *backgroundImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 320,460)];
    backgroundImageView.image = [UIImage imageNamed:@"main_bg.png"];
    [self.view addSubview:backgroundImageView];
    [backgroundImageView release];
    
    UIImageView *meterImageView = [[UIImageView alloc]initWithFrame:CGRectMake(10, 40, 286,315)];
    meterImageView.image = [UIImage imageNamed:@"meter.png"];
    [self.view addSubview:meterImageView];
    [meterImageView release];
    
    // Needle //
    UIImageView *imgNeedle = [[UIImageView alloc]initWithFrame:CGRectMake(143,155, 22, 84)];
    self.needleImageView = imgNeedle;
    [imgNeedle release];
    
    self.needleImageView.layer.anchorPoint = CGPointMake(self.needleImageView.layer.anchorPoint.x, self.needleImageView.layer.anchorPoint.y*2); // Shift the Needle center point to one of the end points of the needle image.
    self.needleImageView.backgroundColor = [UIColor clearColor];
    self.needleImageView.image = [UIImage imageNamed:@"arrow.png"];
    [self.view addSubview:self.needleImageView];
    
    // Needle Dot //
    UIImageView *meterImageViewDot = [[UIImageView alloc]initWithFrame:CGRectMake(131.5, 175, 45,44)];
    meterImageViewDot.image = [UIImage imageNamed:@"center_wheel.png"];
    [self.view addSubview:meterImageViewDot];
    [meterImageViewDot release];
    
    // Speedometer Reading //
    UILabel *tempReading = [[UILabel alloc] initWithFrame:CGRectMake(125, 250, 60, 30)];
    self.speedometerReading = tempReading;
    [tempReading release];
    self.speedometerReading.textAlignment = UITextAlignmentCenter;
    self.speedometerReading.backgroundColor = [UIColor blackColor];
    self.speedometerReading.text= @"0";
    self.speedometerReading.textColor = [UIColor colorWithRed:114/255.f green:146/255.f blue:38/255.f alpha:1.0];
    [self.view addSubview:self.speedometerReading ];
    
    // Set Max Value //
    self.maxVal = @"100";
    
    /// Set Needle pointer initialy at zero //
    [self rotateIt:-118.4]; // Set the needle pointer initially at zero //
    
    // Set previous angle //
    self.prevAngleFactor = -118.4; // To keep track of previous deviated angle //
    
    // Set Speedometer Value //
    [self setSpeedometerCurrentValue];
}

#pragma mark –
#pragma mark calculateDeviationAngle Method

-(void) calculateDeviationAngle
{
    
    if([self.maxVal floatValue]>0)
    {
        self.angle = ((self.speedometerCurrentValue *237.4)/[self.maxVal floatValue])-118.4; // 237.4 – Total angle between 0 – 100 //
    }
    else
    {
        self.angle = 0;
    }
    
    if(self.angle<=-118.4)
    {
        self.angle = -118.4;
    }
    if(self.angle>=119) // 119 deg is the angle value for 100
    {
        self.angle = 119;
    }
    
    // If Calculated angle is greater than 180 deg, to avoid the needle to rotate in reverse direction first rotate the needle 1/3 of the calculated angle and then 2/3. //
    if(abs(self.angle-self.prevAngleFactor) >180)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.5f];
        [self rotateIt:self.angle/3];
        [UIView commitAnimations];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.5f];
        [self rotateIt:(self.angle*2)/3];
        [UIView commitAnimations];
        
    }
    self.prevAngleFactor = self.angle;
    
    // Rotate Needle //
    [self rotateNeedle];
    
}

#pragma mark –
#pragma mark rotateNeedle Method
-(void) rotateNeedle
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5f];
    [self.needleImageView setTransform: CGAffineTransformMakeRotation((M_PI / 180) * self.angle)];
    [UIView commitAnimations];
    
}

#pragma mark –
#pragma mark setSpeedometerCurrentValue

-(void) setSpeedometerCurrentValue
{
    if(self.speedometer_Timer)
    {
        [self.speedometer_Timer invalidate];
        self.speedometer_Timer = nil;
    }
    self.speedometerCurrentValue = arc4random() % 100; // Generate Random value between 0 to 100. //
    
    self.speedometer_Timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(setSpeedometerCurrentValue) userInfo:nil repeats:YES];
    
    self.speedometerReading.text = [NSString stringWithFormat:@"%.2f",self.speedometerCurrentValue];
    
    // Calculate the Angle by which the needle should rotate //
    [self calculateDeviationAngle];
}
#pragma mark –
#pragma mark Speedometer needle Rotation View Methods

-(void) rotateIt:(float)angl
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.01f];
    
    [self.needleImageView setTransform: CGAffineTransformMakeRotation((M_PI / 180) *angl)];
    
    [UIView commitAnimations];
}

[/objc]