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

#import "advertisedFixedViewController.h"
#import "ViewController.h"
@interface advertisedFixedViewController ()

@end

@implementation advertisedFixedViewController

@synthesize advFixVCMeasurements,scrollView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (NSString*)getTechCodeString:(int)tech_code
{
    if(tech_code ==0) return @"All Other";
    else if(tech_code == 10) return @"Asymmetric xDSL";
    else if(tech_code == 11) return @"ADSL2, ADSL2+";
    else if(tech_code == 12) return @"VDSL";
    else if(tech_code == 20) return @"Symmetric xDSL";
    else if(tech_code == 30) return @"Other Copper Wireline";
    else if(tech_code == 40) return @"Cable Modem other";
    else if(tech_code == 41) return @"Cable Modem DOCSIS 1, 1.1, 2.0";
    else if(tech_code == 42) return @"Cable Modem DOCSIS 3.0";
    else if(tech_code == 43) return @"Cable Modem DOCSIS 3.1";
    else if(tech_code == 50) return @"Optical Carrier / Fiber to the end user";
    else if(tech_code == 60) return @"Satellite";
    else if(tech_code == 70) return @"Terrestrial Fixed Wireless";
    else if(tech_code == 80) return @"WCDMA/UTMS/HSPA";
    else if(tech_code == 81) return @"HSPA+";
    else if(tech_code == 82) return @"EVDO/EVDO Rev A";
    else if(tech_code == 83) return @"LTE";
    else if(tech_code == 84) return @"WiMAX";
    else if(tech_code == 85) return @"CDMA";
    else if(tech_code == 86) return @"GSM";
    else if(tech_code == 87) return @"Analog";
    else if(tech_code == 88) return @"Other";
    else if(tech_code == 89) return @"Mobile";
    else if(tech_code == 90) return @"Electric Power Line";
    else return @"N/A"; //(tech_code == -999)
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    //make array to store data
    NSMutableArray *providers = [[NSMutableArray alloc]init];
    NSMutableDictionary *temp, *after;
    
    //enumerate through results
    NSEnumerator *e = [advFixVCMeasurements objectEnumerator];
    id object;
    int i = 0;

    Boolean ios7 = false;
    int extraIos7 = 0;
    if([[[UIDevice currentDevice] systemVersion]floatValue] >= 7) {
        ios7 = true;
    }
    while (object = [e nextObject]) {
        if ([object isKindOfClass:[NSString class]]) {
            [_AFaddresLabel setText:object];
            [_AFaddresLabel setHidden:false];
            if (ios7) {
                CGRect newLabelPos = _AFaddresLabel.frame;
                newLabelPos.origin.y = 6;
                _AFaddresLabel.frame = newLabelPos;
                
                extraIos7 = 6;
            }
        }
        else if ([object isKindOfClass:[NSMutableDictionary class]]) {
            
            NSMutableDictionary *result = (NSMutableDictionary*)object;
            /*if (first) {
                [providers addObject:result];
                first = false;
            }
            else{
                found = false;
                for(i = 0; i<[providers count];i++)
                {
                    temp = [providers objectAtIndex:i];
                    if([[temp valueForKey:@"PROVIDER"] isEqualToString: [result valueForKey:@"PROVIDER"]])
                    {
                        found = true;
                        up1 = (int)[[result valueForKey:@"MaxAdUp"]integerValue];
                        up2 = (int)[[temp valueForKey:@"MaxAdUp"]integerValue];
                        down1 = (int)[[result valueForKey:@"MaxAdDn"]integerValue];
                        down2 = (int)[[temp valueForKey:@"MaxAdDn"]integerValue];
                        if(up1 > up2)
                        {
                            NSNumber *newn = [[NSNumber alloc]initWithInt:up1];
                            [temp setValue:newn forKey:@"MaxAdUp"];
                        }
                        if(down1 > down2)
                        {
                            NSNumber *newn = [[NSNumber alloc]initWithInt:down1];
                            [temp setValue:newn forKey:@"MaxAdDn"];
                        }
                    }
                }
                if(found == false)//was not previously found so add to array
                {
                    [providers addObject:result];
                }
            }*/
            [providers addObject:result];
        }
    }
    int size = (int)[providers count];
    NSString *name1, *name2;
    //sorting by provider name
    for (int p =0; p<(size-1); p++) {
        for (int k = p+1; k<size; k++) {
            temp = [providers objectAtIndex:p];
            after = [providers objectAtIndex:k];
            name1 = [temp valueForKey:@"PROVIDER"];
            name2 = [after valueForKey:@"PROVIDER"];
            if ([name1 compare:name2] == NSOrderedDescending) {
                [providers exchangeObjectAtIndex:p withObjectAtIndex:k];
            }
            else if ([name1 compare:name2] == NSOrderedSame)//if provider is same, look at techCode
            {
                NSString* s1 = [self getTechCodeString:[[temp valueForKey:@"TechCode"] intValue]];
                NSString* s2 = [self getTechCodeString:[[after valueForKey:@"TechCode"] intValue]];
                if([s1 compare:s2] == NSOrderedDescending)
                {
                    [providers exchangeObjectAtIndex:p withObjectAtIndex:k];
                }
            }
        }
    }
    
    for (int p = 0; p < (size - 1); p++)
    {
        for(int k = p + 1; k < size; k++)
        {
            temp = [providers objectAtIndex:p];
            after = [providers objectAtIndex:k];
            name1 = [temp valueForKey:@"PROVIDER"];
            name2 = [after valueForKey:@"PROVIDER"];
            NSString* s1 = [self getTechCodeString:[[temp valueForKey:@"TechCode"] intValue]];
            NSString* s2 = [self getTechCodeString:[[after valueForKey:@"TechCode"] intValue]];
            if ([name1 compare:name2] == NSOrderedSame)//if provider is same, look at techCode
            {
                if([s1 compare:s2] == NSOrderedSame)//if techcodes are same, delete slowest
                {
                    int down1 = (int)[[temp valueForKey:@"MaxAdDn"]integerValue];
                    int down2 = (int)[[after valueForKey:@"MaxAdDn"]integerValue];
                    //if(down1 > down2)
                    //    [providers removeObjectAtIndex:k];
                    //else if(down1 < down2)
                    //    [providers removeObjectAtIndex:p];
                    if(down1 == down2)
                    {
                        [providers removeObjectAtIndex:k];
                        size--;
                    }
                    if(down2 > down1)
                    {
                        [providers exchangeObjectAtIndex:p withObjectAtIndex:k];
                    }
                }
            }
        }
    }
    
    if ([providers count] > 0) {
        i=0;
        UIImageView *legend = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"uploadDownloadLegend.png"]];
        CGRect iframe = legend.frame;
        iframe.size.width = 320;
        
        iframe.origin.y = (-125 + (i*45) + extraIos7);
        legend.frame = iframe;
        
        [scrollView addSubview:legend];
        legend.contentMode = UIViewContentModeScaleAspectFit;
        
        legend = nil;
    }
    i=0;
    for(int p = 0;p<[providers count];p++)
    {
        temp = [providers objectAtIndex:p];
        UILabel *providerLabel = [[UILabel alloc] init];
        providerLabel.text = [temp valueForKey:@"PROVIDER"];
        [providerLabel sizeToFit];
        
        providerLabel.center = scrollView.center;
        CGRect pframe = providerLabel.frame;
        pframe.origin.y = i*90+87 + extraIos7;
        //change 90 to 45 if doesnt work
        providerLabel.frame = pframe;
        [scrollView addSubview:providerLabel];
        
        
        UILabel *serviceLabel = [[UILabel alloc] init];
        [serviceLabel setFont:[UIFont systemFontOfSize:12]];
        //serviceLabel.text = [[temp valueForKey:@"TechCode"] stringValue];
        serviceLabel.text = [self getTechCodeString:[[temp valueForKey:@"TechCode"] intValue]];
        //serviceLabel.text = @"TEST";
        [serviceLabel sizeToFit];
        serviceLabel.center = scrollView.center;
        CGRect sframe = serviceLabel.frame;
        sframe.origin.y = i*90+105 + extraIos7;
        //change 90 to 45 if doesnt work
        serviceLabel.frame = sframe;
        [scrollView addSubview:serviceLabel];
        
        for (int j=0; j<2; j++){
            
            int pspeed = -1;
            double speed;
            NSString *direction = @"notset";
            
            switch (j) {
                case 0:
                    //Looks like this is calculated in Mbps, instead of a value 1-9
                    speed = (double)[[temp valueForKey:@"MaxAdUp"]doubleValue];
                        if (speed < 0.2) {
                            pspeed = 1;
                        } else if (speed >= 0.2 && speed < 0.75) {
                            pspeed = 2;
                        } else if (speed >= 0.75 && speed < 1.5) {
                            pspeed = 3;
                        } else if (speed >= 1.5 && speed < 3) {
                            pspeed = 4;
                        } else if (speed >= 3 && speed < 6) {
                            pspeed = 5;
                        } else if (speed >= 6 && speed < 10) {
                            pspeed = 6;
                        } else if (speed >= 10 && speed < 25) {
                            pspeed = 7;
                        } else if (speed >= 25 && speed < 50) {
                            pspeed = 8;
                        } else if (speed >= 50 && speed < 100) {
                            pspeed = 9;
                        } else if (speed >= 100 && speed < 1000) {
                            pspeed = 10;
                        } else if (speed >= 1000) {
                            pspeed = 11;
                        } else {
                            pspeed = -1;
                        }
                    direction = @"up";
                    break;
                case 1:
                    speed = (double)[[temp valueForKey:@"MaxAdDn"]doubleValue];
                    if (speed < 0.2) {
                        pspeed = 1;
                    } else if (speed >= 0.2 && speed < 0.75) {
                        pspeed = 2;
                    } else if (speed >= 0.75 && speed < 1.5) {
                        pspeed = 3;
                    } else if (speed >= 1.5 && speed < 3) {
                        pspeed = 4;
                    } else if (speed >= 3 && speed < 6) {
                        pspeed = 5;
                    } else if (speed >= 6 && speed < 10) {
                        pspeed = 6;
                    } else if (speed >= 10 && speed < 25) {
                        pspeed = 7;
                    } else if (speed >= 25 && speed < 50) {
                        pspeed = 8;
                    } else if (speed >= 50 && speed < 100) {
                        pspeed = 9;
                    } else if (speed >= 100 && speed < 1000) {
                        pspeed = 10;
                    } else if (speed >= 1000) {
                        pspeed = 11;
                    } else {
                        pspeed = -1;
                    }
                    direction = @"down";
                    break;
                default:
                    break;
            }
            
            // set which .png file we should use
            NSString *filename = @"";
            
            // If no measurement data is returned
            if (pspeed == -1){
                filename = [NSString stringWithFormat:@"%@null.png",direction];
            }
            else{
                // If measurement data is returned
                filename = [NSString stringWithFormat:@"%@%d.png",direction,pspeed];
            }
            
            UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:filename]];
            
            CGRect iframe = iv.frame;
            iframe.size.width = 320;
            
            iframe.origin.y = (-95 + (i*90) + (j*30) + 100 + extraIos7);
            
            iv.frame = iframe;
            
            [scrollView addSubview:iv];
            iv.contentMode = UIViewContentModeScaleAspectFit;
            
            iv = nil;
        }
        i++;
        
    }
    if ([providers count] <= 0) {
        [_AFNoData setText:@"No Data Found"];
        [_AFNoData setHidden:false];
    }else{
        [_AFNoData setHidden:true];
    }
    scrollView.contentSize = CGSizeMake(320,(i*90)+35+extraIos7 +75);
    //scrollView.contentInset=UIEdgeInsetsMake(64.0,0.0,44.0,0.0);
    [scrollView setScrollEnabled:YES];
    self.view.backgroundColor = [UIColor whiteColor];
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(tappedRightButton:)];
    [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    
    [self.view addGestureRecognizer:swipeLeft];
    
    
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(tappedLeftButton:)];
    
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    
    [self.view addGestureRecognizer:swipeRight];
    
}

- (IBAction)tappedRightButton:(id)sender

{
    
    NSUInteger selectedIndex = [self.tabBarController selectedIndex];
    
    
    
    [self.tabBarController setSelectedIndex:selectedIndex + 1];
    
}



- (IBAction)tappedLeftButton:(id)sender

{
    
    NSUInteger selectedIndex = [self.tabBarController selectedIndex];
    
    
    
    [self.tabBarController setSelectedIndex:selectedIndex - 1];
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
