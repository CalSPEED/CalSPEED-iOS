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
#import "TestWrapper.h"

@protocol iPerfEngineDelegate;

@interface iPerfEngine : NSObject<TestWrapperDelegate>

// Holds the id reference for the engine's delegate
@property (nonatomic, weak) id<iPerfEngineDelegate> delegate;

// Creates the engine with a delegate to report test results to.
// Any delegate class just needs to implement iPerfEngineDelegate, and pass itself as an argument
-(id)initWithDelegate:(id<iPerfEngineDelegate>)del;

-(bool)testActive;

// Starts the iPerf test, returns whether the test was started successfully or not
-(bool)startTest;

// Opts to log the details of the test to the console, false by default. Make sure to call this *before* a test is started
-(void)setLogTestToConsole:(bool)toLog;

@end

// Delegate declarations
@protocol iPerfEngineDelegate <NSObject>

// Mark each delegate method as optional, so that the implementing class isn't required to explicitly implement each and every method
// TO-DO: This optional modifier is probably unnecessary, as are the respondsToSelector checks in this class's message file, as
// speedTest.m is the only delegate of this class.
@optional

// Called when the preliminary connectivity test either succeeds or fails completely
-(void)connectivityTestDidFinishWithSuccess:(bool)didSucceed;

// Returns individual ping query results during a ping test
-(void)pingTestDidPingWithResult:(double)result;

// Called when a ping test is finished, returns the average ping result
-(void)pingTestDidFinishWithAverage:(double)average;

// Returns individual iPerf server test query results
-(void)serverTestDidReturnQuery:(int)queryResult;

// Called when the last 4 iPerf server test queries are added together and a sum is found
-(void)serverTestDidReportDataSum:(int)resultSum;

// Returns the result of either an upload or download portion of an iPerf test (true for upload, false for download), with the given speed and count
-(void)serverTestDidCompletePortion:(bool)isDownload withSpeed:(int)resultSpeed withCount:(int)resultCount;

// Returns the result of a UDP test
-(void)didReceiveUDPResult:(double)result;

// Called when an iPerf server test has timed out
-(void)serverTestDidTimeout;

// Called when an iPerf server test has completed
-(void)serverTestDidFinish;

// Called when the standard test has completely finished, with the last known latitude and longitude found during the test
-(void)standardTestDidFinishWithFinalLocationLatitude:(double)latitude withLongitude:(double)longitude;

@end
