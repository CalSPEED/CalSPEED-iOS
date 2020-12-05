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
#import "iPerfEngine.h"

@interface speedTestViewController : UIViewController<iPerfEngineDelegate>{
    IBOutlet UIView *meterSpot;
    IBOutlet UISwitch *inOutSwitch;
    IBOutlet UILabel *inOutLabel;
    
    IBOutlet UIButton *indoorButton;
    IBOutlet UIButton *startButton;
    IBOutlet UINavigationItem *item2;
    
    IBOutlet UIActivityIndicatorView *spinner;
    
    IBOutlet UIProgressView *progressBar;
    
    IBOutlet UIImageView *pulse;
    IBOutlet UILabel *welcome;
    
    IBOutlet UILabel *maxSpeedometerLabel;
    IBOutlet UILabel *uploadLabel;
    IBOutlet UILabel *ul;
    IBOutlet UILabel *downloadLabel;
    IBOutlet UILabel *dl;
    IBOutlet UILabel *delayLabel;
    IBOutlet UILabel *d;
    IBOutlet UILabel *delayVariationLabel;
    IBOutlet UILabel *dv;
    IBOutlet UILabel *satisfyLabel;
    IBOutlet UILabel *mosDescriptionLabel;
    
    IBOutlet UILabel *uploadFinal;
    IBOutlet UILabel *downloadFinal;
    IBOutlet UILabel *delayFinal;
    IBOutlet UILabel *delayVariationFinal;
    
    IBOutlet UILabel *dlFinal;
    IBOutlet UILabel *ulFinal;
    IBOutlet UILabel *dFinal;
    IBOutlet UILabel *dvFinal;
    
    IBOutlet UILabel *progress;
    
    IBOutlet UILabel *connectedToWifiLabel;
    IBOutlet UILabel *readyToBegin;
}

@end
