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
#import "WriteToResultsFile.h"
#import "MOSCalculation.h"

TestWrapper *testWrapper;

DeviceInformation *deviceInformation;

WriteToResultsFile *writeToResults;

int numOfUDPResults;

@implementation LoggingWrapper

// Constructor; needs to store the instance of TestWrapper in order to pass iPerf test information
-(id)initWithTestWrapper:(TestWrapper *)wrapper{
    testWrapper = wrapper;
    deviceInformation = [[DeviceInformation alloc] init];
    writeToResults = [[WriteToResultsFile alloc] init];
    numOfUDPResults = 0;
    [testWrapper setCarrier:[[deviceInformation getNetworkOperator] substringToIndex:4]];
    return self;
}

+(DeviceInformation *)getDeviceInformation{
    return deviceInformation;
}

+(void)setDoorStatus:(NSString *)whatDoorIsInStore{
    [deviceInformation setDoorStatus:whatDoorIsInStore];
}

// Attempts to save the current log file to the device, returns wether the save succeeded or not
+(bool)saveResults{
    return [writeToResults writeToFile];
}

// Attempts to upload the current log file on the device to the SFTP server, returns wether the upload succeeded or not
+(bool)uploadResultsToServer{
    return [writeToResults writeToUnixServer];
}

+(void)initializeNewTestInfoWithLat:(float)latitude withLong:(float)longitude{
    //Test and device information is appended to the file to be uploaded
    
    [writeToResults initLog];
    // Just grabs the current app version from the .plist file so that it doesn't need to be manually changed here with every update
    [writeToResults newReport:[NSString stringWithFormat:@"Crowd Source iOS Device v%@\n", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]];
    [writeToResults newReport:[TimeAndDate getDateForStartTime]];
    [writeToResults newReport:[deviceInformation generateInformationWithLat:latitude withLong:longitude]];
}

// Wrapper for the counterpart method found in WriteToResultsFile.h
+(void)newReport:(NSString *)reportString{
    [writeToResults newReport:reportString];
}

+(void)newReportAndPrint:(NSString *)reportString{
    [self newReport:[reportString stringByAppendingString:@"\n"]];
    [testWrapper printlnNS:reportString];
}

+(void)reportPingResult:(double)finalPingResult{
    [testWrapper receivePingResult:finalPingResult];
}

+(void)reportTestData:(int)reportData{
    [testWrapper receiveTestDataSum:reportData];
}

+(void)reportUDPResult:(double)result withPacketLoss:(double)packetLoss{
    [MOSCalculation addUDPLoss:packetLoss];
    [testWrapper receiveUDPResult:result];
    if(numOfUDPResults % 2 == 1) [MOSCalculation addEastUDPLoss:packetLoss];
    numOfUDPResults++;
}

+(void)reportTimeout{
    [testWrapper receiveTimeout];
}

// Passes on an iPerf test result to TestWrapper
+(void)reportTestResult:(int)resultSpeed withCount:(int)resultCount{
    [testWrapper receiveTestResult:resultSpeed withCount:resultCount];
}

// Passes on to TestWrapper that an iPerf test has finished
+(void)reportEnd{
    [testWrapper notifyTestEnd];
}

@end
