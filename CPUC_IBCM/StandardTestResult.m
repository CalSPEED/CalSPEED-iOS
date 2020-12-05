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

#import "StandardTestResult.h"
#import "CoreDataManager.h"
#import <CoreData/CoreData.h>


@implementation StandardTestResult

@dynamic testDate;
@dynamic uploadSpeed;
@dynamic downloadSpeed;
@dynamic delay;
@dynamic delayVariation;
@dynamic networkType;
@dynamic latitude;
@dynamic longitude;
@dynamic meanOpinionScore;
@dynamic videoMetric;
@dynamic videoConference;
@dynamic voip;

-(NSString *)getPresentableStringFromValue:(NSNumber *)value withDecimalPlaces:(int)decimalPlaces{
    if([value isEqual:@0]){
        return @"N/A";
    }
    return [NSString stringWithFormat:@"%.*f", decimalPlaces, [value doubleValue]];
}

-(NSString *)getDisplayUploadSpeed{
    return [self getPresentableStringFromValue:self.uploadSpeed withDecimalPlaces:2];
}

-(NSString *)getDisplayDownloadSpeed{
    return [self getPresentableStringFromValue:self.downloadSpeed withDecimalPlaces:2];
}

-(NSString *)getDisplayDelay{
    return [self getPresentableStringFromValue:self.delay withDecimalPlaces:0];
}

-(NSString *)getDisplayDelayVariation{
    return [self getPresentableStringFromValue:self.delayVariation withDecimalPlaces:0];
}

-(NSString *)getDisplayMOS{
    return [self getPresentableStringFromValue:self.meanOpinionScore withDecimalPlaces:2];
}

-(NSString *)getDisplayLongitude{
    return [self getPresentableStringFromValue:self.longitude withDecimalPlaces:5];
}

-(NSString *)getDisplayLatitude{
    return [self getPresentableStringFromValue:self.latitude withDecimalPlaces:5];
}

-(NSString *)getVideoMetric{
    return self.videoMetric;
}

-(NSString *)getVideoConference{
    return self.videoConference;
}

-(NSString *)getVoip{
    return self.voip;
}

@end
