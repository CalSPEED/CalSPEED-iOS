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

#import "iPerfEngine.h"
#import "LoggingWrapper.h"

LoggingWrapper *loggingWrapper;

TestWrapper *testWrap;

@implementation iPerfEngine

bool testActive = false;

-(id)initWithDelegate:(id<iPerfEngineDelegate>)del{
    self.delegate = del;
    testWrap = [[TestWrapper alloc] initWithDelegate:self];
    loggingWrapper = [[LoggingWrapper alloc] initWithTestWrapper:testWrap];
    return self;
}

-(bool)testActive{
    return testActive;
}

-(void)setLogTestToConsole:(bool)toLog{
    [testWrap willLogTestToConsole:toLog];
}

-(bool)startTest{
    testActive = true;
    return [testWrap startTest];
}

-(void)connectivityTestDidFinishWithSuccess:(bool)didSucceed{
    if([self.delegate respondsToSelector:@selector(connectivityTestDidFinishWithSuccess:)]){
        [self.delegate connectivityTestDidFinishWithSuccess:didSucceed];
    }
}

-(void)pingTestDidPingWithResult:(double)result{
if([self.delegate respondsToSelector:@selector(pingTestDidPingWithResult:)]){
    [self.delegate pingTestDidPingWithResult:result];
}
}

-(void)pingTestDidFinishWithAverage:(double)average{
    if([self.delegate respondsToSelector:@selector(pingTestDidFinishWithAverage:)]){
        [self.delegate pingTestDidFinishWithAverage:average];
    }
}

-(void)serverTestDidReturnQuery:(int)queryResult{
    if([self.delegate respondsToSelector:@selector(serverTestDidReturnQuery:)]){
        [self.delegate serverTestDidReturnQuery:queryResult];
    }
}

-(void)serverTestDidReportDataSum:(int)resultSum{
    if([self.delegate respondsToSelector:@selector(serverTestDidReportDataSum:)]){
        [self.delegate serverTestDidReportDataSum:resultSum];
    }
}

-(void)serverTestDidCompletePortion:(bool)isDownload withSpeed:(int)resultSpeed withCount:(int)resultCount{
    if([self.delegate respondsToSelector:@selector(serverTestDidCompletePortion:withSpeed:withCount:)]){
        [self.delegate serverTestDidCompletePortion:isDownload withSpeed:resultSpeed withCount:resultCount];
    }
}

-(void)didReceiveUDPResult:(double)result{
    if([self.delegate respondsToSelector:@selector(didReceiveUDPResult:)]){
        [self.delegate didReceiveUDPResult:result];
    }
}

-(void)serverTestDidTimeout{
    testActive = false;
    if([self.delegate respondsToSelector:@selector(serverTestDidTimeout)]){
        [self.delegate serverTestDidTimeout];
    }
}

-(void)serverTestDidFinish{
    testActive = false;
    if([self.delegate respondsToSelector:@selector(serverTestDidFinish)]){
        [self.delegate serverTestDidFinish];
    }
}

-(void)standardTestDidFinishWithFinalLocationLatitude:(double)latitude withLongitude:(double)longitude{
    testActive = false;
    if([self.delegate respondsToSelector:@selector(standardTestDidFinishWithFinalLocationLatitude:withLongitude:)]){
        [self.delegate standardTestDidFinishWithFinalLocationLatitude:latitude withLongitude:longitude];
    }
}

@end
