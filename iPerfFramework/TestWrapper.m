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

#import "TestWrapper.h"
#import "LoggingWrapper.h"
#import "CPPWrapper.h"
#import "PingTest.h"
#include "Settings.hpp"
#include "VMContainer.h"

@implementation TestWrapper

PingTest *pingTest;

CPPWrapper *cppWrapper;

//CLLocationManager *locationManagerr;

float lastKnownLat;
float lastKnownLong;
CLLocation *lastKnownLocation;
float totalDistanceMoved;

bool willLogToConsole = false;

bool testInProgress = false;

int currentConnectivityTest;
int numberOfConnectivityTests;

int currentServerTest;

int serverPorts[2];

NSString *tcpCommandLineReport;
NSString *udpCommandLineReport;
NSString *currentTestIP;
NSString *currentTestLabel;

const char *ipToUse, *numberOfTestsToUse, *intervalsToUse, *numOfThreadsToUse, *winSize, *winSizeTCP;

ServerTestType currentServerTestType = Upload;

extern int iperf_timeout;
extern int cnx_error;
extern struct video_metric VIDM;
extern int probe_ary[10];
extern int reported_probe_speed;
int probeTest;

// Prints a C string without the verbose NSLog labeling
-(void)println:(const char *restrict)string{
    if(willLogToConsole) printf("%s\n", string);
}

// Prints an NSString without the verbose NSLog labeling
-(void)printlnNS:(NSString *)string{
    [self println:[string cStringUsingEncoding:NSASCIIStringEncoding]];
}

// Prints hella lines
-(void)printHellaLines{
    [self println:"----------------------------------------------------------"];
}

// Prints hella lines with a given number of sick heading and sick footing line breaks
-(void)printHellaLinesWithSickBreaks:(int)sickHeaders withSickFooters:(int)sickFooters{
    if(sickHeaders > 0) [self printlnNS:[@"" stringByPaddingToLength:sickHeaders-1 withString:@"\n" startingAtIndex:0]];
    [self printHellaLines];
    if(sickFooters > 0) [self printlnNS:[@"" stringByPaddingToLength:sickFooters-1 withString:@"\n" startingAtIndex:0]];
}

// Constructor; requires a TestWrapperDelegate to report test information, and passes
// down to itself, a delegate of PingTest, to the newly-created PingTest instance
-(id)initWithDelegate:(id<TestWrapperDelegate>)del{
    self.delegate = del;
    cppWrapper = [[CPPWrapper alloc] init];
    _locationManagerr = [CalSPEEDLocationManager getSharedLocationManager];
    [_locationManagerr setDelegate:self];
    [_locationManagerr startUpdatingLocation];
    return self;
}

// Delegate for the location manager
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocation* newLocation = [locations lastObject];
    lastKnownLat = [newLocation coordinate].latitude;
    lastKnownLong = [newLocation coordinate].longitude;
    //lastKnownLat = [locations[0] coordinate].latitude;
    //lastKnownLong = [locations[0] coordinate].longitude;
    //NSLog(@"Location: %f, %f", lastKnownLong, lastKnownLat);
    //printf("\nLocation: %f, %f\n", lastKnownLong, lastKnownLat);
}

// Tells all relevent receiving logging methods throughout the engine whether to log their output
// to the console or not. Off by default, so there shouldn't be a need to call this with anything but "true"
-(void)willLogTestToConsole:(bool)willLog{
    willLogToConsole = willLog;
    [cppWrapper willLogTestToConsole:willLog];
}

// Sets the ports to use during TCP and UDP tests, based on what carrier is being used
-(void)setCarrier:(NSString *)carrier{
    // This method receives only the first 4 characters of the carrier string, as one iteration of
    // AT&T's name is quite long, and 4 characters are plenty to identify the carrier
    if([carrier isEqual: @"AT&T"]){ // AT&T
        [self setPorts:5001 withUDP:5002];
    }
    else if([carrier isEqual: @"Spri"]){ // Sprint
        [self setPorts:5003 withUDP:5004];
    }
    else if([carrier isEqual: @"T-Mo"]){ // T-Mobile
        [self setPorts:5005 withUDP:5006];
    }
    else if([carrier isEqual: @"Veri"]){ // Verizon
        [self setPorts:5007 withUDP:5008];
    }
    else{ // Other
        [self setPorts:5009 withUDP:5010];
    }
}

// Just sets the class port values, to condense the setCarrier method
-(void)setPorts:(int)tcp withUDP:(int)udp{
    serverPorts[0] = tcp;
    serverPorts[1] = udp;
    //printf("Setting carrier ports as %d, %d\n", tcp, udp);
    tcpCommandLineReport = [NSString stringWithFormat:@"\nIperf command line:/data/data/net.measurementlab.ndt/files/iperfT -c 127.0.0.1 -e -w %s -P %s -i 1 -t %s -f k -p %d", winSize, numOfThreadsToUse, numberOfTestsToUse, serverPorts[0]];
    udpCommandLineReport = [NSString stringWithFormat:@"\nIperf command line:/data/data/net.measurementlab.ndt/files/iperfT -c 127.0.0.1 -u -l 220 -b 88k -i 1 -t 1 -f k -p %d", udp];
}

// Starts the entire test, returns whether test was started
-(bool)startTest{
    if(testInProgress){
        return false;
    }
    testInProgress = true;
    totalDistanceMoved = 0;
    lastKnownLocation = nil;
    
    
    _locationManagerr = [CalSPEEDLocationManager getSharedLocationManager];
    [_locationManagerr setDelegate:self];
    [_locationManagerr startUpdatingLocation];
    [LoggingWrapper initializeNewTestInfoWithLat:lastKnownLat withLong:lastKnownLong];
    [self reportLatLongToLog];
    [self printHellaLinesWithSickBreaks:2 withSickFooters:0];
    [self println:"Starting standard test"];
    [self beginStandardTest];
    return true;
}

// Starts the standard test; only actually tells the connectivity test to start, however
-(void)beginStandardTest{
    [UIApplication sharedApplication].idleTimerDisabled = YES; // Prevent device from sleeping while running the test
    
    currentTestIP = @"YOURIPERFSERVERIP";
    currentServerTest = 0;
    probeTest = 0;
    // Start a connectivity test with 4 ping test iterations
    [self startConnectivityTest:1]; //Let's change number of tests to just 1
}

// Handles the end of the test, for any reason
-(void)endTest{
    [LoggingWrapper newReport:@"Test finished, saving results to device..."];
    bool resultsSaved = [LoggingWrapper saveResults];
    if(resultsSaved){
        [self println:"Results saved successfully!"];
        bool resultsUploaded = [LoggingWrapper uploadResultsToServer];
        if(resultsUploaded){
            [self println:"Results uploaded successfully!"];
        }
        else{
            [self println:"Results were NOT uploaded successfully!"];
        }
    }
    else{
        [self println:"Results NOT saved."];
    }
    [UIApplication sharedApplication].idleTimerDisabled = NO; // Allow device to sleep again
    
    testInProgress = false;
    [self.delegate standardTestDidFinishWithFinalLocationLatitude:lastKnownLat withLongitude:lastKnownLong];
    lastKnownLat = lastKnownLong = 0;
    
    
    [self println:"Standard test finished"];
}

// Handles the end of the test, for not connection
-(void)endTestWithNoConnection:(NSString *)message{
    [self printlnNS:message];
    [self printHellaLines];
    [LoggingWrapper newReport:@"Test finished, saving results to device..."];
    bool resultsSaved = [LoggingWrapper saveResults];
    if(resultsSaved){
        [self println:"Results saved successfully!"];
    }
    else{
        [self println:"Results NOT saved."];
    }
    [UIApplication sharedApplication].idleTimerDisabled = NO; // Allow device to sleep again
    
    testInProgress = false;
    [self.delegate standardTestDidFinishWithFinalLocationLatitude:lastKnownLat withLongitude:lastKnownLong];
    
    
    [self println:"Standard test finished"];
}

// Ends the test, after printing a given explanation message
-(void)endTestWithMessage:(NSString *)message{
    [self printlnNS:message];
    [self printHellaLines];
    [self endTest];
}

-(void)receivePingResult:(double)pingResult{
    [self.delegate pingTestDidPingWithResult:pingResult];
}

-(void)receiveTestDataSum:(int)result{
    [self.delegate serverTestDidReportDataSum:result];
}

-(void)receiveTestResult:(int)resultSpeed withCount:(int)resultCount{
    [self.delegate serverTestDidCompletePortion:(int)currentServerTestType withSpeed:resultSpeed withCount:resultCount];
    currentServerTestType = !currentServerTestType;
}

-(void)receiveUDPResult:(double)result{
    [self.delegate didReceiveUDPResult:result];
}

-(void)receiveTimeout{
    [self.delegate serverTestDidTimeout];
}

// Performs a single iPerf test, with the given test protocol; 0 for TCP, 1 for UDP
-(void)singleiPerfTest:(id)protocolType{
    currentServerTestType = Upload;
    int protocol = [protocolType intValue];
    const char *port = [[NSString stringWithFormat:@"%d", serverPorts[protocol]] UTF8String];
    
    setSettings(ipToUse, numberOfTestsToUse, intervalsToUse, numOfThreadsToUse, winSize, port, protocol);
    
    [cppWrapper runiPerfThread:protocol];
}

// Performs a single probe iPerf test, using 1 thread, 512k window size, and 10 second test
-(void)singleProbeiPerfTest:(id)protocolType{
    int protocol = [protocolType intValue];
    currentServerTestType = Upload;
    NSString* currentTestIP = @"YOURIPERFSERVERIP";
    const char *ipToUse_ = [currentTestIP cStringUsingEncoding:NSUTF8StringEncoding];
    const char *port_ = [[NSString stringWithFormat:@"%d", serverPorts[protocol]] UTF8String];
    const char *numOfThreadsToUse_ = [@"1" cStringUsingEncoding:NSUTF8StringEncoding];
    const char *winSize_ = [@"512k" cStringUsingEncoding:NSUTF8StringEncoding];
    const char *numberOfTestsToUse_ = [@"10" cStringUsingEncoding:NSUTF8StringEncoding];
    const char *intervalsToUse_ = [@"1" cStringUsingEncoding:NSUTF8StringEncoding];
    
    setSettings(ipToUse_, numberOfTestsToUse_, intervalsToUse_, numOfThreadsToUse_, winSize_, port_, protocol);

    [cppWrapper runiPerfThread:protocol];
}

// Reports the current location, and the net change made in distance since the last location report, to the log file
-(void)reportLatLongToLog{
    // Need to address this somehow -- often, one or two location updates out of the ~8-9 total updates to the log don't finish calculating new distance before they're likely frozen by another thread somehow. Doing the operations on another thread, or pushing them to the main thread works, but they then update and log with a very noticeable and likely problematic delay.
    //dispatch_async(dispatch_get_main_queue(), ^{
    CLLocation *currentLocation = [[CLLocation alloc] initWithLatitude:lastKnownLat longitude:lastKnownLong];
    float recentDistanceMoved = [lastKnownLocation distanceFromLocation:currentLocation]*3.28084;
    totalDistanceMoved += recentDistanceMoved; // distanceFromLocation returns meters, so we  multiply the result by 3.28084 (as found in the Android version) to convert it to feet
    [LoggingWrapper newReport:[NSString stringWithFormat:@"\nLatitude: %f\nLongitude: %f\nDistanceMoved: %f\n", lastKnownLat, lastKnownLong, totalDistanceMoved]];
    [self printlnNS:[NSString stringWithFormat:@"Logging distance moved, last location: %f, %f | this location: %f, %f | distance moved from last location: %f ft | total distance moved: %f ft", lastKnownLocation.coordinate.latitude, lastKnownLocation.coordinate.longitude, currentLocation.coordinate.latitude, currentLocation.coordinate.longitude, recentDistanceMoved, totalDistanceMoved]];
    lastKnownLocation = currentLocation;
    currentLocation = nil;
    //});
}

// Begins the actual iPerf portion test;
-(void)beginiPerfTest{
    //[pingTest setPingTestMode:PingTestMode];
    [self handleNewTestPhase];
}

// Main sorting and test-semantics handling method for the bulk of the standard test
// Here is where you can set individual test settings.
-(void)handleNewTestPhase{
    currentServerTest++;
    
    bool isPingTest = false;
    bool isTCP = true;
    
    if(probeTest)
        currentServerTest = 0;
    
    switch (currentServerTest) {
        case 0:{
            if(probeTest) //probe test
            {
                ipToUse = [currentTestIP cStringUsingEncoding:NSUTF8StringEncoding];
                //[NSThread detachNewThreadSelector:@selector(singleProbeiPerfTest:) toTarget:self withObject:@(0)];
                numOfThreadsToUse = [@"1" cStringUsingEncoding:NSUTF8StringEncoding];
                winSize = [@"512k" cStringUsingEncoding:NSUTF8StringEncoding];
                numberOfTestsToUse = [@"10" cStringUsingEncoding:NSUTF8StringEncoding];
                intervalsToUse = [@"1" cStringUsingEncoding:NSUTF8StringEncoding];
                currentTestLabel = @"Probe Test";
                //VIDM.west_number_of_threads = VIDM.east_number_of_threads = 4;
            }
            break;
        }
            
        case 1:{
            ipToUse = [currentTestIP cStringUsingEncoding:NSUTF8StringEncoding];
            //numberOfTestsToUse = [@"20" cStringUsingEncoding:NSUTF8StringEncoding];
            //intervalsToUse = [@"1" cStringUsingEncoding:NSUTF8StringEncoding];
            
            //numOfThreadsToUse = [@"4" cStringUsingEncoding:NSUTF8StringEncoding];
            //VIDM.west_number_of_threads = 4;
            //winSize = [@"32k" cStringUsingEncoding:NSUTF8StringEncoding];

            // TCP West
            currentTestLabel = @"Iperf TCP West";
            break;
        }
        case 2:{
            // Ping West
            currentTestLabel = @"Ping West";
            isPingTest = true;
            break;
        }
        case 3:{
            // UDP West
            currentTestLabel = @"Iperf West UDP 1 second test";
            winSize = [@"0k" cStringUsingEncoding:NSUTF8StringEncoding];
            isTCP = false;
            break;
        }
        case 4:{
            // TCP East
            currentTestIP = @"174.129.206.169";
            ipToUse = [currentTestIP cStringUsingEncoding:NSUTF8StringEncoding];
            //numberOfTestsToUse = [@"20" cStringUsingEncoding:NSUTF8StringEncoding];
            //intervalsToUse = [@"1" cStringUsingEncoding:NSUTF8StringEncoding];
            
            //numOfThreadsToUse = [@"4" cStringUsingEncoding:NSUTF8StringEncoding];
            //VIDM.east_number_of_threads = 4;
            //winSize = [@"32k" cStringUsingEncoding:NSUTF8StringEncoding];
            winSize = winSizeTCP;
            
            currentTestLabel = @"Iperf TCP East";
            break;
        }
        case 5:{
            // Ping East
            currentTestLabel = @"Ping East";
            isPingTest = true;
            break;
        }
        case 6:{
            // UDP East
            pingTest = nil;
            currentTestLabel = @"Iperf East UDP 1 second test";
            winSize = [@"0k" cStringUsingEncoding:NSUTF8StringEncoding];
            isTCP = false;
            break;
        }
    }
    [self reportLatLongToLog];
    [self printHellaLinesWithSickBreaks:1 withSickFooters:0];
    
    [self printlnNS:[NSString stringWithFormat:@"Starting test %d: %@", currentServerTest, currentTestLabel]];

    if(currentServerTest != 0)
        [LoggingWrapper newReport:[NSString stringWithFormat:@"Starting Test %d: %@....\n\n", currentServerTest, currentTestLabel]];
    else
        [LoggingWrapper newReport:[NSString stringWithFormat:@"\n%@\n\n", currentTestLabel]];

    if(isPingTest){
        [pingTest performPingTestWithCompletionBlock:^void(double result){
            [self.delegate pingTestDidFinishWithAverage:result];
            NSString *connectionStatus = [NSString stringWithFormat:@" successfully, with an average of %f ms", result];
            if(result == 0) connectionStatus = @", but with NO connection";
            [self printlnNS:[NSString stringWithFormat:@"Test %d: %@ finished%@", currentServerTest, currentTestLabel, connectionStatus]];
            [self handleTestPhaseEnd];
        } withAddress:currentTestIP];
        return;
    }
    if(isTCP)
    {
        tcpCommandLineReport = [NSString stringWithFormat:@"\nIperf command line:/data/data/net.measurementlab.ndt/files/iperfT -c 127.0.0.1 -e -w %s -P %s -i 1 -t %s -f k -p %d", winSize, numOfThreadsToUse, numberOfTestsToUse, serverPorts[0]]; //taken from setPorts()
        [LoggingWrapper newReport:tcpCommandLineReport];
    }
    else
        [LoggingWrapper newReport:udpCommandLineReport];
        
    [NSThread detachNewThreadSelector:@selector(singleiPerfTest:) toTarget:self withObject:@(!isTCP)];
}

// Called by LoggingWrapper, from Settings.mm when the last iPerf test thread is destroyed, signifying the very end of an iPerf test
-(void)notifyTestEnd{
    [self.delegate serverTestDidFinish];
    [self printlnNS:[NSString stringWithFormat:@"\n\nTest %d: %@ finished!", currentServerTest, currentTestLabel]];
    
    [self performSelectorOnMainThread:@selector(handleTestPhaseEnd) withObject:nil waitUntilDone:false];
}

// Called each time a test phase ends, decides whether to end the test or to start a new phase
-(void)handleTestPhaseEnd{
    if(currentServerTest == 6){
        // End of tests
        [self reportLatLongToLog];
        if(iperf_timeout == 0)
            [self endTestWithMessage:@"\n\niPerf test finished sucessfully"];
        else
            [self endTestWithNoConnection:@"\n\niPerf test time out."];
        return;
    }
    
    if(iperf_timeout == 1)
    {
        if(currentServerTest == 0 || currentServerTest == 1 || currentServerTest == 3 || currentServerTest == 4)
            iperf_timeout = 0; //reset iperf_timeout
        [self reportLatLongToLog];
        /*currentServerTest = 6; //tries to do UDP, but iperf timeout is already set to 1, so it doesn't cancel it
        [self reportLatLongToLog];
        [self endTestWithNoConnection:@"\n\niPerf test time out."];
        return;*/
    }
    
    if(cnx_error == 1)
    {
        if(currentServerTest == 6) // if it's the last test, just end it
        {
            testInProgress = false;
            [self.delegate standardTestDidFinishWithFinalLocationLatitude:lastKnownLat withLongitude:lastKnownLong];
            return;
        }
        else                        // otherwise, reset cnx error to a 0 and go again
            cnx_error = 0;
    }

    if(probeTest == 1)
    {
        probeTest = 0;
        ///PROBE TEST RESULTS?
        ///PROBE TEST RESULTS CALCULATED HERE
        //printf("\n\n**PROBE TEST RESULTS\n");
        //for(int i = 0; i < 10; i++)
        //    printf("%d, ", probe_ary[i]);
        //printf("\n");
        int probeSpeed = 0, probeSpeedCount = 0;
        
        /*for(int i = 0; i < 10; i++)
        {
            if(probe_ary[i] != 0)
            {
                probeSpeed += (probe_ary[i]);
                probeSpeedCount++;
            }
        }
        
        probeSpeed /= probeSpeedCount;
         */
        probeSpeed = reported_probe_speed;
        
        if(probeSpeed < 10000)
        {
            numberOfTestsToUse = [@"20" cStringUsingEncoding:NSUTF8StringEncoding];
            intervalsToUse = [@"1" cStringUsingEncoding:NSUTF8StringEncoding];
            numOfThreadsToUse = [@"1" cStringUsingEncoding:NSUTF8StringEncoding];
            winSizeTCP = winSize = [@"512k" cStringUsingEncoding:NSUTF8StringEncoding];
            VIDM.west_number_of_threads = VIDM.east_number_of_threads = 1;
        }
        else if(probeSpeed >= 10000 && probeSpeed < 100000)
        {
            numberOfTestsToUse = [@"20" cStringUsingEncoding:NSUTF8StringEncoding];
            intervalsToUse = [@"1" cStringUsingEncoding:NSUTF8StringEncoding];
            numOfThreadsToUse = [@"4" cStringUsingEncoding:NSUTF8StringEncoding];
            winSizeTCP = winSize = [@"512k" cStringUsingEncoding:NSUTF8StringEncoding];
            VIDM.west_number_of_threads = VIDM.east_number_of_threads = 4;
        }
        else if(probeSpeed >= 100000 && probeSpeed < 250000)
        {
            numberOfTestsToUse = [@"20" cStringUsingEncoding:NSUTF8StringEncoding];
            intervalsToUse = [@"1" cStringUsingEncoding:NSUTF8StringEncoding];
            numOfThreadsToUse = [@"8" cStringUsingEncoding:NSUTF8StringEncoding];
            winSizeTCP = winSize = [@"512k" cStringUsingEncoding:NSUTF8StringEncoding];
            VIDM.west_number_of_threads = VIDM.east_number_of_threads = 8;
        }
        else //if(probeSpeed >= 250000)
        {
            numberOfTestsToUse = [@"20" cStringUsingEncoding:NSUTF8StringEncoding];
            intervalsToUse = [@"1" cStringUsingEncoding:NSUTF8StringEncoding];
            numOfThreadsToUse = [@"8" cStringUsingEncoding:NSUTF8StringEncoding];
            winSizeTCP = winSize = [@"1024k" cStringUsingEncoding:NSUTF8StringEncoding];
            VIDM.west_number_of_threads = VIDM.east_number_of_threads = 8;
        }
        /*HERE IS WHERE TO TEST FOR DIFFERENT CONDITIONS, like WINDOW SIZE AND NUMBER OF THREADS*/
        
        printf("\n\n****PROBE TEST SPEED: %d\n# of tests: %s\nthreads: %s\nwinSize: %s\n\n", probeSpeed, numberOfTestsToUse, numOfThreadsToUse,winSize);
        [LoggingWrapper newReport:[NSString stringWithFormat:@"\nDownload speed result is: %i\n", probeSpeed]];
        
    }
    else
        [self printlnNS:[NSString stringWithFormat:@"Starting test %d of 6 in 3 seconds...", currentServerTest+1]];
    [self performSelector:@selector(handleNewTestPhase) withObject:nil afterDelay:3];
}

// String formatting function to log the progress of the connectivity test
-(NSString *)connectivityTestProgress:(bool)needsIncrement{
    int currentTestToPrint = currentConnectivityTest;
    if(needsIncrement) currentTestToPrint++;
    return [NSString stringWithFormat:@"%d of %d", currentTestToPrint, numberOfConnectivityTests];
}

// Begins the connectivity test, with a given number of test iterations
-(void)startConnectivityTest:(int)numberOfTests{
    pingTest = [[PingTest alloc] init];
    [LoggingWrapper newReport:@"Checking Connectivity.....\n\n"];
    numberOfConnectivityTests = numberOfTests;
    currentConnectivityTest = 0;
    
    [self singleConnectivityTest];
}

// Performs a single connectivity test
-(void)singleConnectivityTest{
    currentConnectivityTest++;
    [self printlnNS:[NSString stringWithFormat:@"Starting connectivity test %@", [self connectivityTestProgress:false]]];
    [pingTest performConnectivityTestWithCompletionBlock:^void(double result){
        
        [self printlnNS:[NSString stringWithFormat:@"Finished connectivity test %@", [self connectivityTestProgress:false]]];
        
        // Check if the connectivity test has returned with no connection
        if(result == 0){
            if(currentConnectivityTest < numberOfConnectivityTests){
                // If we can start a new connectivity test, we schedule one to start in 3 seconds
                [self printlnNS:[NSString stringWithFormat:@"Connectivity test %d failed, starting test %@ in 3 seconds...\n\n", currentConnectivityTest, [self connectivityTestProgress:true]]];
                [self performSelector:@selector(singleConnectivityTest) withObject:nil afterDelay:3];
            }
            else{
                // All connectivity tests have failed, and the test ends prematurely
                [self.delegate connectivityTestDidFinishWithSuccess:false];
                [self endTestWithNoConnection:[NSString stringWithFormat:@"Failed all %d connectivity tests", numberOfConnectivityTests]];
                [LoggingWrapper newReport:@"\nConnectivity Test Failed--Exiting Test.\n"];
            }
            return;
        }
        // If we reach this point, a connectivity test has succeeded, and we start the iPerf server test routine
        probeTest = 1;
        [self.delegate connectivityTestDidFinishWithSuccess:true];
        [self printlnNS:[NSString stringWithFormat:@"Connectivity test #%d succeeded", currentConnectivityTest]];
        [self beginiPerfTest];
    }];
}

@end
