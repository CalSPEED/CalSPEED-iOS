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
#import "StandardTestResult.h"

@protocol StandardTestResultDetailTableViewControllerDelegate;

@interface StandardTestResultDetailTableViewController : UITableViewController{
    IBOutlet UILabel *dateLabel;
    IBOutlet UILabel *timeLabel;
    IBOutlet UILabel *uploadSpeedLabel;
    IBOutlet UILabel *downloadSpeedLabel;
    IBOutlet UILabel *delayLabel;
    IBOutlet UILabel *delayVariationLabel;
    IBOutlet UILabel *networkTypeLabel;
    IBOutlet UILabel *latitudeLabel;
    IBOutlet UILabel *longitudeLabel;
    IBOutlet UILabel *mosLabel;
    IBOutlet UILabel *videoLabel;
    IBOutlet UILabel *videoConfLabel;
    IBOutlet UILabel *voipLabel;
    
    StandardTestResult *testResult;
}

@property (nonatomic, weak) id<StandardTestResultDetailTableViewControllerDelegate> delegate;

+(instancetype)initWithStandardTestResults:(StandardTestResult *)testResult withDelegate:(id<StandardTestResultDetailTableViewControllerDelegate>)del;

@end

@protocol StandardTestResultDetailTableViewControllerDelegate<NSObject>

-(void)deleteButtonPressed:(StandardTestResult *)testResult;

@end
