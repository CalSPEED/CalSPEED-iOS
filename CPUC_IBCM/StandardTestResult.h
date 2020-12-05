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
#import <CoreData/CoreData.h>


@interface StandardTestResult : NSManagedObject

@property (nonatomic, retain) NSDate * testDate;
@property (nonatomic, retain) NSNumber * uploadSpeed;
@property (nonatomic, retain) NSNumber * downloadSpeed;
@property (nonatomic, retain) NSNumber * delay;
@property (nonatomic, retain) NSNumber * delayVariation;
@property (nonatomic, retain) NSString * networkType;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * meanOpinionScore;
@property (nonatomic, retain) NSString * videoMetric;
@property (nonatomic, retain) NSString * videoConference;
@property (nonatomic, retain) NSString * voip;

-(NSString *)getDisplayUploadSpeed;
-(NSString *)getDisplayDownloadSpeed;
-(NSString *)getDisplayDelay;
-(NSString *)getDisplayDelayVariation;
-(NSString *)getDisplayMOS;
-(NSString *)getDisplayLongitude;
-(NSString *)getDisplayLatitude;
-(NSString *)getVideoMetric;
-(NSString *)getVideoConference;
-(NSString *)getVoip;

@end
