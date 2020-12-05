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

#import "StandardTestResultDetailTableViewController.h"

@implementation StandardTestResultDetailTableViewController

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    self.navigationItem.title = @"Results";
    return self;
}

-(void)deleteButtonPressed:(UIBarButtonItem *)button{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * deleteAction){
        [self.navigationController popViewControllerAnimated:true];
        [self.delegate deleteButtonPressed:self->testResult];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:deleteAction];
    [self presentViewController:alertController animated:true completion:nil];
    
    // The "old" (deprecated) way of displaying an action sheet. Keeping this included for now because
    // it's worth noting that the old style triggers actions the instant that a button is pressed,
    // and the new style triggers actions when the action sheet is finished being dismissed. To
    // use this old style instead of the new one, comment-out the lines above, uncomment the
    // lines below, along with the actionSheet delegate method below that, and make sure
    // that this class adopts the UIActionSheetDelegate protocol.
    /*UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Delete"
                                                    otherButtonTitles:nil];
    
    [actionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
    
    [actionSheet showInView:self.view];*/
}

/*- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0){
        [self.navigationController popViewControllerAnimated:true];
        [self.delegate deleteButtonPressed:testResult];
    }
}*/

-(void)viewDidLoad{
    UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc]initWithTitle:@"Delete" style:UIBarButtonItemStylePlain target:self action:@selector(deleteButtonPressed:)];
    [deleteButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor redColor], NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = deleteButton;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    dateLabel.text = [dateFormatter stringFromDate:testResult.testDate];
    
    dateFormatter.dateStyle = NSDateFormatterNoStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    timeLabel.text = [dateFormatter stringFromDate:testResult.testDate];
    
    uploadSpeedLabel.text = [testResult getDisplayUploadSpeed];
    printf("\nActual upload speed: %f\n", [testResult.uploadSpeed doubleValue]);
    
    downloadSpeedLabel.text = [testResult getDisplayDownloadSpeed];
    printf("Actual download speed: %f\n", [testResult.downloadSpeed doubleValue]);
    
    delayLabel.text = [testResult getDisplayDelay];
    printf("Actual delay: %f\n", [testResult.delay doubleValue]);
    
    delayVariationLabel.text = [testResult getDisplayDelayVariation];
    printf("Actual delay varation: %f\n", [testResult.delayVariation doubleValue]);
    
    videoLabel.text = [testResult getVideoMetric];
    printf("Actual video metric: %s\n", [[testResult getVideoMetric] UTF8String]);
    
    if([testResult getVideoConference] == nil) videoConfLabel.text = @"N/A";
    else videoConfLabel.text = [testResult getVideoConference];
    printf("Actual video conference: %s\n", [[testResult getVideoConference] UTF8String]);
    
    if([testResult getVoip] == nil) voipLabel.text = @"N/A";
    else voipLabel.text = [testResult getVoip];
    printf("Actual voip: %s\n", [[testResult getVoip] UTF8String]);
    
    NSString *networkTypeTouse = testResult.networkType;
    if([networkTypeTouse isEqualToString:@"WIFI"]){
        // Preferrably should use Apple's nomenclature -- "Wi-Fi" -- when presenting to the user
        networkTypeTouse = @"Wi-Fi";
    }
    networkTypeLabel.text = networkTypeTouse;
    
    latitudeLabel.text = [testResult getDisplayLatitude];
    
    longitudeLabel.text = [testResult getDisplayLongitude];
    
    mosLabel.text = [testResult getDisplayMOS];
    printf("Actual MOS: %f\n", [testResult.meanOpinionScore doubleValue]);
}

+(instancetype)initWithStandardTestResults:(StandardTestResult *)testResult withDelegate:(id<StandardTestResultDetailTableViewControllerDelegate>)del{
    StandardTestResultDetailTableViewController *newSelf = (StandardTestResultDetailTableViewController *)[[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"StandardTestResultView"];
    newSelf.delegate = del;
    newSelf->testResult = testResult;
    return newSelf;
}

@end
