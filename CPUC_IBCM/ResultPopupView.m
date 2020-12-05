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

#import "ResultPopupView.h"

@implementation ResultPopupView

-(void)setResultsWithUp:(double)up withDown:(double)down withDelay:(double)delay withDelayVariation:(double)delayVariation withMOS:(double)mos withVideo:(NSString *) videoMetric withVideoConference:(NSString*) videoConference withVoip:(NSString*) voip{
    //Make sure upload always shows 3 digits
    if(up == 0)
        self.uploadLabel.text =[NSString stringWithFormat:@"N/A"];
    else if(up < 10)
        self.uploadLabel.text = [NSString stringWithFormat:@"%.2f mbps", up];
    else if(up < 100)
        self.uploadLabel.text = [NSString stringWithFormat:@"%.1f mbps", up];
    else
        self.uploadLabel.text = [NSString stringWithFormat:@"%.0f mbps", up];
    //Make sure download always shows 3 digits
    if(down == 0)
        self.downloadLabel.text =[NSString stringWithFormat:@"N/A"];
    else if(down < 10)
        self.downloadLabel.text = [NSString stringWithFormat:@"%.2f mbps", down];
    else if(down < 100)
        self.downloadLabel.text = [NSString stringWithFormat:@"%.1f mbps", down];
    else
        self.downloadLabel.text = [NSString stringWithFormat:@"%.0f mbps", down];
    //Make sure delay always shows 3 digits
    if(delay == 0)
        self.delayLabel.text =[NSString stringWithFormat:@"N/A"];
    else if(delay < 10)
        self.delayLabel.text = [NSString stringWithFormat:@"%.2f ms", delay];
    else if(delay < 100)
        self.delayLabel.text = [NSString stringWithFormat:@"%.1f ms", delay];
    else
        self.delayLabel.text = [NSString stringWithFormat:@"%.0f ms", delay];
    //Make sure delay variation always shows 3 digits
    if(delayVariation == 0)
        self.delayVariationLabel.text =[NSString stringWithFormat:@"N/A"];
    else if(delayVariation < 10)
        self.delayVariationLabel.text = [NSString stringWithFormat:@"%.2f ms", delayVariation];
    else if(delayVariation < 100)
        self.delayVariationLabel.text = [NSString stringWithFormat:@"%.1f ms", delayVariation];
    else
        self.delayVariationLabel.text = [NSString stringWithFormat:@"%.0f ms", delayVariation];
    
    self.delayVariationLabel.text = videoMetric;
    self.mosLabel.highlighted = mos < 4;
}

@end
