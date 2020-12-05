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

#import "advertisedSatelliteViewController.h"

@interface advertisedSatelliteViewController ()

@end

@implementation advertisedSatelliteViewController

@synthesize advSatVCMeasurements,scrollView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    //make array to store data
    NSMutableArray *providers = [[NSMutableArray alloc]init];
    int up1,up2,down1,down2;
    NSMutableDictionary *temp, *after;
    //enumerate through results
    NSEnumerator *e = [advSatVCMeasurements objectEnumerator];
    id object;
    int i = 0;
    Boolean found = false;
    Boolean first = true;
    Boolean ios7 = false;
    int extraIos7 = 0;
    if([[[UIDevice currentDevice] systemVersion]floatValue] >= 7) {
        ios7 = true;
    }
    while (object = [e nextObject]) {
        if ([object isKindOfClass:[NSString class]]) {
            [_ASaddressLabel setText:object];
            [_ASaddressLabel setHidden:false];
            if (ios7) {
                CGRect newLabelPos = _ASaddressLabel.frame;
                newLabelPos.origin.y = 6;
                _ASaddressLabel.frame = newLabelPos;
                
                extraIos7 = 6;
                if([[[UIDevice currentDevice] systemVersion]floatValue] < 9){
                    newLabelPos.origin.y = 70;
                    _ASaddressLabel.frame = newLabelPos;
                    extraIos7 = 70;
                }
            }
        }
        else if ([object isKindOfClass:[NSMutableDictionary class]]) {
            
            NSMutableDictionary *result = (NSMutableDictionary*)object;
            if (first) {
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
                        up1 = (int)[[result valueForKey:@"MAXADUP"]integerValue];
                        up2 = (int)[[temp valueForKey:@"MAXADUP"]integerValue];
                        down1 = (int)[[result valueForKey:@"MAXADDOWN"]integerValue];
                        down2 = (int)[[temp valueForKey:@"MAXADDOWN"]integerValue];
                        if(up1 > up2)
                        {
                            NSNumber *newn = [[NSNumber alloc]initWithInt:up1];
                            [temp setValue:newn forKey:@"MAXADUP"];
                        }
                        if(down1 > down2)
                        {
                            NSNumber *newn = [[NSNumber alloc]initWithInt:down1];
                            [temp setValue:newn forKey:@"MAXADDOWN"];
                        }
                    }
                }
                if(found == false)//was not previously found so add to array
                {
                    [providers addObject:result];
                }
            }
        }
    }
    int size = (int)[providers count];
    //sorting by download speed
    for (int p =0; p<(size-1); p++) {
        for (int k = p+1; k<size; k++) {
            temp = [providers objectAtIndex:p];
            after = [providers objectAtIndex:k];
            down1 = (int)[[temp valueForKey:@"MAXADDOWN"]integerValue];
            down2 = (int)[[after valueForKey:@"MAXADDOWN"]integerValue];
            if (down2 > down1) {
                [providers exchangeObjectAtIndex:p withObjectAtIndex:k];
            }
            else if (down1 == down2)
            {
                up1 = (int)[[temp valueForKey:@"MAXADUP"]integerValue];
                up2 = (int)[[after valueForKey:@"MAXADUP"]integerValue];
                if(up2 > up1)
                {
                    [providers exchangeObjectAtIndex:p withObjectAtIndex:k];
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
        //iframe.origin.y = (-95 + (i*90) + (j*30) +35);
        
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
        pframe.origin.y = i*90+75+ extraIos7;
        //change 90 to 45 if doesnt work
        providerLabel.frame = pframe;
        [scrollView addSubview:providerLabel];
        for (int j=0; j<2; j++){
            
            int pspeed = -1;
            NSString *direction = @"notset";
            
            switch (j) {
                case 0:
                    pspeed = (int)[[temp valueForKey:@"MAXADUP"]integerValue];
                    direction = @"up";
                    break;
                case 1:
                    pspeed = (int)[[temp valueForKey:@"MAXADDOWN"]integerValue];
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
            
            iframe.origin.y = (-95 + (i*90) + (j*30) +75+ extraIos7);
            
            iv.frame = iframe;
            
            [scrollView addSubview:iv];
            iv.contentMode = UIViewContentModeScaleAspectFit;
            
            iv = nil;
        }
        i++;

    }
    if ([providers count] <= 0) {
        [_ASNoData setText:@"No Data Found"];
        [_ASNoData setHidden:false];
        if (ios7) {
            CGRect newLabelPos = _ASNoData.frame;
            newLabelPos.origin.y = 107;
            _ASNoData.frame = newLabelPos;
        }
    }
    else{
        [_ASNoData setHidden:true];
    }

    scrollView.contentSize = CGSizeMake(320,(i*90+70) + extraIos7+extraIos7);
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
