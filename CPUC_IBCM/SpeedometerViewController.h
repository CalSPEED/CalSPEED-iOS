//
//  Speedometer.h
//  CalBroadband
//
//  Created by localadmin on 5/28/15.
//  Copyright (c) 2015 CSUMB. All rights reserved.
//

#ifndef CalBroadband_Speedometer_h
#define CalBroadband_Speedometer_h


[objc]

@interface SpeedometerViewController : UIViewController {
    UIImageView *needleImageView;
    float speedometerCurrentValue;
    float prevAngleFactor;
    float angle;
    NSTimer *speedometer_Timer;
    UILabel *speedometerReading;
    NSString *maxVal;
    
}
@property(nonatomic,retain) UIImageView *needleImageView;
@property(nonatomic,assign) float speedometerCurrentValue;
@property(nonatomic,assign) float prevAngleFactor;
@property(nonatomic,assign) float angle;
@property(nonatomic,retain) NSTimer *speedometer_Timer;
@property(nonatomic,retain) UILabel *speedometerReading;
@property(nonatomic,retain) NSString *maxVal;

-(void) addMeterViewContents;
-(void) rotateIt:(float)angl;
-(void) rotateNeedle;
-(void) setSpeedometerCurrentValue;
-(void) calculateDeviationAngle;
[/objc]

#endif
