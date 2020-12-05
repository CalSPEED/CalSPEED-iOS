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
#import "ResultsViewController.h"
#import "StandardTestResult.h"
#import "ResultTableViewCell.h"

@implementation ResultsViewController

CoreDataManager *coreDataManager;

NSMutableArray *tableData;

int layoutIteration = 0;

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    coreDataManager = [CoreDataManager getSharedCoreDataManager];
    coreDataManager.delegate = self;
    return self;
}

- (void)viewDidLoad
{
    [self.navigationItem setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Results" style:UIBarButtonItemStylePlain target:nil action:nil]];
    
    //back chevron color
    self.navigationItem.backBarButtonItem.tintColor = [UIColor colorWithRed:10/255.0 green:134/255.0 blue:191/255.0 alpha:1.0];
    
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:86/255.0 green:178/255.0 blue:227/255.0 alpha:1.0]];

    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:86/255.0 green:178/255.0 blue:227/255.0 alpha:1.0];
    
    table.delegate = self;
    table.dataSource = self;
    tableData = (NSMutableArray *)[self getAllStoredData];
    
    table.delegate = self;
    table.dataSource = self;
}

-(void)viewDidLayoutSubviews{
    if(layoutIteration < 2){
        if(layoutIteration == 1){
            CGFloat cumulativeLength = ((self.view.viewForBaselineLayout.bounds.size.width-32)/10)+7;
            for(UIImageView *imageView in resultImageLabelViewCollection){
                imageView.translatesAutoresizingMaskIntoConstraints = true;
                
                CGRect frame = imageView.frame;
                imageView.frame = CGRectMake(frame.origin.x, frame.origin.y, 40, 40);
                
                imageView.center = CGPointMake(cumulativeLength, imageView.center.y);
                cumulativeLength += 57.5;
            }
        }
        layoutIteration++;
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:false animated:true];
}

-(IBAction)infoButtonPressed:(id)sender{
    [self.navigationController pushViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"AboutViewController"] animated:true];
}

-(NSString *)stringFromDate:(NSDate *)date getTime:(bool)willGetTime{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    if(willGetTime){
        [dateFormatter setDateFormat:@"hh:mm a"];
    }
    else{
        [dateFormatter setDateFormat:@"MM/dd/yy"]; // TO-DO: Give year 4 digits
    }
    return [dateFormatter stringFromDate:date];
}

-(void)didCreateStandardTestResult:(StandardTestResult *)testResult{
    if(tableData.count >= 100){
        [self deleteTestResult:tableData.lastObject];
    }
    [tableData insertObject:testResult atIndex:0];
    [table reloadData];
}

-(IBAction)addButtonPressed:(id)sender{
    [CoreDataManager createStandardTestResultWithStartDate:[NSDate date] withUpload:12 withDownload:43.2 withDelay:12.3 withDelayVariation:27.9 withNetworkType:@"WIFI" withLatitude:0 withLongitude:0 withMeanOpinionScore:5 withVideoMetric:@"N/A" withVideoConference:@"N/A" withVoip:@"N/A"];
}

-(IBAction)clearButtonPressed:(id)sender{
    [coreDataManager flushDatabase];
    [tableData removeAllObjects];
    [table reloadData];
}

-(StandardTestResult *)getAllStoredData{
    NSManagedObjectContext *managedObjectContext = [coreDataManager managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"StandardTestResult" inManagedObjectContext:managedObjectContext]];
    
    NSError *error;
    NSArray *objects = [[[managedObjectContext executeFetchRequest:request error:&error] reverseObjectEnumerator] allObjects];
    
    return [(StandardTestResult*)objects mutableCopy];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return tableData.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ResultTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ResultCell"];
    
    StandardTestResult *testResult = tableData[indexPath.row];
    cell.dateLabel.text = [self stringFromDate:testResult.testDate getTime:false];
    cell.timeLabel.text = [self stringFromDate:testResult.testDate getTime:true];
    
    if([[testResult getDisplayUploadSpeed]  isEqual: @"0"])
        cell.uploadSpeedLabel.text = [NSString stringWithFormat:@"N/A"];
    else
        cell.uploadSpeedLabel.text = [testResult getDisplayUploadSpeed];
    
    if([[testResult getDisplayDownloadSpeed] isEqual: @"0"])
        cell.downloadSpeedLabel.text = [NSString stringWithFormat:@"N/A"];
    else
        cell.downloadSpeedLabel.text = [testResult getDisplayDownloadSpeed];
    
    if([[testResult getDisplayDelay] isEqual: @"0"])
        cell.delayLabel.text = [NSString stringWithFormat:@"N/A"];
    else
        cell.delayLabel.text = [testResult getDisplayDelay];
    
    /*if([[testResult getDisplayDelayVariation] isEqual: @"0"])
        cell.delayVariationLabel.text = [NSString stringWithFormat:@"N/A"];
    else
        cell.delayVariationLabel.text = [testResult getDisplayDelayVariation];*/
    
    if([testResult getVideoMetric] == nil)
        cell.videoMetricsLabel.text = [NSString stringWithFormat:@"N/A"];
    else
        cell.videoMetricsLabel.text = [testResult getVideoMetric];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:false];
    StandardTestResultDetailTableViewController *resultsViewController = [StandardTestResultDetailTableViewController initWithStandardTestResults:tableData[indexPath.row] withDelegate:self];
    
    [self.navigationController pushViewController:resultsViewController animated:true];
    [self.navigationController setNavigationBarHidden:false animated:true];
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return true;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if(editingStyle == UITableViewCellEditingStyleDelete){
        [self deleteTestResult:tableData[indexPath.row]];
        //[tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        //[tableView endUpdates];
    }
}

-(void)deleteButtonPressed:(StandardTestResult *)testResult{
    [self deleteTestResult:testResult];
    [table reloadData];
}

-(void)deleteTestResult:(StandardTestResult *)testResult{
    [tableData removeObject:testResult];
    
    NSManagedObjectContext *managedObjectContext = [coreDataManager managedObjectContext];
    [managedObjectContext deleteObject:testResult];
    [managedObjectContext save:nil];
}

@end
