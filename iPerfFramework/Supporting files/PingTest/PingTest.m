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

#import "LoggingWrapper.h"
#import "PingTest.h"

@implementation PingTest

#pragma mark - Class variables

static GBPing *gbPing = nil;
PingTestModeType currentTestModeType = ConnectivityTestMode;
NSTimeInterval pingStartDate;
int totalNumberOfPings, cumulativePingsSent, successfulReplies, currentPingPacket;
double minimumPing, cumulativePingResults, maximumPing;
bool lastPingFailedToSend = false;

// The callback block to be completed when a test is complete; defined in the header file
CompletionBlock pingTestCompletionBlock;

#pragma mark - Public methods

// Public method to perform a connectivity test, with a given CompletionBlock
-(void)performConnectivityTestWithCompletionBlock:(CompletionBlock)completionBlock{
    [self initGBPingWithHost:@"SERVERYOUWANTTOPING"];
    [self startGBPingWithPings:4 withCompletionBlock:completionBlock];
}

// Public method to perform an "actual" ping test, with a given CompletionBlock, and with a given IP address
-(void)performPingTestWithCompletionBlock:(CompletionBlock)completionBlock withAddress:(NSString *)address{
    [self initGBPingWithHost:address];
    currentTestModeType = PingTestMode;
    [self startGBPingWithPings:10 withCompletionBlock:completionBlock];
}

#pragma mark - Ping test methods

// Initializes the GBPing object with a given address to ping.
// The object is reconstructed for each test in order to try to
// save memory, and to prevent errant ping responses -- namely
// timeouts -- from interfering with the rest of the class
-(void)initGBPingWithHost:(NSString *)address{
    gbPing = [[GBPing alloc] init];
    gbPing.delegate = self;
    
    // The ping response timeout period; the amount of time, in seconds, to
    // wait for a sent ping's response before declaring it as a timed-out ping
    gbPing.timeout = 1;
    gbPing.host = address;
}

// Starts a ping operation/test with a given number of pings, and with
// a CompletionBlock to execute after the ping test has finished
-(void)startGBPingWithPings:(int)numberOfPings withCompletionBlock:(CompletionBlock)completionBlock{
    totalNumberOfPings = numberOfPings;
    pingTestCompletionBlock = completionBlock;
    cumulativePingsSent = 0;
    successfulReplies = 0;
    currentPingPacket = 0;
    minimumPing = 0;
    cumulativePingResults = 0;
    maximumPing = 0;
    lastPingFailedToSend = false;
    
    // The actual setup method for GBPing, just tells it to
    // initialize itself with our previously-given parameters
    [gbPing setupWithBlock:^(BOOL success, NSError *error){
        pingStartDate = CACurrentMediaTime();
        if(success){
            
            // If it initialized correctly, then we start sending pings
            [gbPing startPinging];
            
            // We set a task to end the test after numberOfPings seconds, in case
            // the test doesn't end itself after receiving enough successful replies
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(numberOfPings * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self endPinging];
            });
        } else {
            
            // If GBPing was unable to start, we print/log that error and print/log the test information anyway
            [LoggingWrapper newReportAndPrint:[NSString stringWithFormat:@"GBPing failed to start. Error: %@", error]];
            [self endPinging];
        }
    }];
}

// Stops the active ping test, if possible, and prints/logs a summary of the test's information
-(void)endPinging{
    if(gbPing == nil)
        return;
    
    // We ask GBPing to stop sending new pings -- note that this doesn't prevent it from receiving signals
    [gbPing stop];
    
    // We print and log the ping test's statistical summation
    [LoggingWrapper newReportAndPrint:[NSString stringWithFormat:@"-- %@ ping statistics --", gbPing.host]];
    [LoggingWrapper newReportAndPrint:[NSString stringWithFormat:@"%d packets transmitted, %d received, %.2f%% packet loss, total time %fm", totalNumberOfPings, successfulReplies, fabs((double)successfulReplies / (double)totalNumberOfPings - 1)*100, CACurrentMediaTime() - pingStartDate]];
    double finalPingAverage = cumulativePingResults/cumulativePingsSent;
    [LoggingWrapper newReportAndPrint:[NSString stringWithFormat:@"rtt min/avg/max = %@/%@/%@ ms\n", [self getStringRTT:minimumPing], [self getStringRTT:finalPingAverage], [self getStringRTT:maximumPing]]];
    
    // It's imperative that we release the GBPing object, so that
    // straggling ping signals don't cause any disruptions
    gbPing = nil;
    
    // If we're running a connectivity test, then we return the test's success as the number of
    // successful ping responses -- the receiving class simply checks if this number is 0 or not.
    if(currentTestModeType == ConnectivityTestMode){
        finalPingAverage = successfulReplies;
    }
    
    // Finally, we execute the "completion" code block with a callback,
    // passing our return value through as the sole argument
    pingTestCompletionBlock(finalPingAverage);
}

-(NSString *)getStringRTT:(double)value{
    if(value == 0)
        return @"NA";
    return [NSString stringWithFormat:@"%lf", value];
}

// Ends the ping test if possible
-(void)endIfMaximumPingsReached{
    
    // Checks if the most recent ping packet received is the last one that we're looking for
    if(totalNumberOfPings == currentPingPacket + 1){
        [self endPinging];
    }
}

#pragma mark - GBPing delegate methods

// Called when a ping packet is sent
-(void)ping:(GBPing *)pinger didSendPingWithSummary:(GBPingSummary *)summary {
    lastPingFailedToSend = false;
    cumulativePingsSent++;
    currentPingPacket = (int)summary.sequenceNumber;
}

// Called when a ping reply is received successfully
-(void)ping:(GBPing *)pinger didReceiveReplyWithSummary:(GBPingSummary *)summary {
    // If the reply packet says that the ping was a success, and if its sequence
    // number is the one that we're expecting, then it's a valid ping reply
    if(summary.status == GBPingStatusSuccess&&summary.sequenceNumber == currentPingPacket){
        double resultTime = summary.rtt*1000;
        
        // We try to find the highest and lowest pings
        if(resultTime < minimumPing||minimumPing == 0){
            minimumPing = resultTime;
        }
        if(resultTime > maximumPing){
            maximumPing = resultTime;
        }
        
        // We keep a running sum of all results, to find the average ping value at the very end of the test
        cumulativePingResults += resultTime;
        
        [LoggingWrapper newReportAndPrint:[NSString stringWithFormat:@"%d bytes from %@: icmp_seq=%d ttl=1 time=%.1f ms", (int)gbPing.payloadSize, gbPing.host, currentPingPacket+1, resultTime]];
        successfulReplies++;
        
        // If we're running a ping test, not a connectivity test, then we send
        // each individual ping result for display on the speed test UI
        if(currentTestModeType == PingTestMode){
            [LoggingWrapper reportPingResult:resultTime];
        }
        
        // We check to see if we can end the ping test if we've received all the replies that we're expecting
        [self endIfMaximumPingsReached];
    }
}

// Called when a ping is attempted to be sent and immediately fails, for whatever reason.
// If this is received for a given ping attempt, then it can be assumed that the entire
// individual ping iteration itself will fail, and so it can be considered a ping result.
-(void)ping:(GBPing *)pinger didFailToSendPingWithSummary:(GBPingSummary *)summary error:(NSError *)error {
    [LoggingWrapper newReportAndPrint:[NSString stringWithFormat:@"icmp_seq %d could not reach host", (int)summary.sequenceNumber + 1]];
    lastPingFailedToSend = true;
    [self endIfMaximumPingsReached];// Maximum pings reached, ending test
}

// Called after the given timeout period (currently set to 1 second) of
// a sent ping has ended, without any response from the original packet.
-(void)ping:(GBPing *)pinger didTimeoutWithSummary:(GBPingSummary *)summary {
    if(!lastPingFailedToSend)
        [LoggingWrapper newReportAndPrint:[NSString stringWithFormat:@"icmp_seq %d timed out", (int)summary.sequenceNumber + 1]];
}

// Unknown when this gets called
-(void)ping:(GBPing *)pinger didReceiveUnexpectedReplyWithSummary:(GBPingSummary *)summary {
    [LoggingWrapper newReportAndPrint:[NSString stringWithFormat:@"Ping packet %d received unexpected reply (BREPLY). Summary: %@", (int)summary.sequenceNumber + 1, summary]];
}

// Unknown when this gets called
-(void)ping:(GBPing *)pinger didFailWithError:(NSError *)error {
    [LoggingWrapper newReportAndPrint:[NSString stringWithFormat:@"Ping failed (FAIL) with error: %@", error]];
}

@end
