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

#define NSLog(FORMAT, ...) printf("%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String])


#import "MOSCalculation.h"
#import "LoggingWrapper.h"

@implementation MOSCalculation

static MOSCalculation *instance;

bool debugMode = false;

NSMutableArray *pingAverages, *udpJitters, *udpLosses;
NSMutableArray *eastPingAverages, *eastUdpJitters, *eastUdpLosses;

+(instancetype)init{
    instance = [[super alloc] init];
    pingAverages = [[NSMutableArray alloc] init];
    udpJitters = [[NSMutableArray alloc] init];
    udpLosses = [[NSMutableArray alloc] init];
    eastPingAverages = [[NSMutableArray alloc] init];
    eastUdpJitters = [[NSMutableArray alloc] init];
    eastUdpLosses = [[NSMutableArray alloc] init];
    return instance;
}

+(void)setDebugMode:(bool)mode{
    debugMode = mode;
}

+(void)debugMessage:(NSString *)string withDouble:(double)value{
    if(debugMode)
        NSLog(@"%@: %g", string, value);
}

+(void)clearData{
    [pingAverages removeAllObjects];
    [udpJitters removeAllObjects];
    [udpLosses removeAllObjects];
    [eastPingAverages removeAllObjects];
    [eastUdpJitters removeAllObjects];
    [eastUdpLosses removeAllObjects];
}

+(void)addPing:(double)ping{
    [MOSCalculation debugMessage:@"MOS Add Ping" withDouble:ping];
    [pingAverages addObject:[NSNumber numberWithDouble:ping]];
}

+(void)addJitter:(double)jitter{
    [MOSCalculation debugMessage:@"MOS Add Jitter" withDouble:jitter];
    [udpJitters addObject:[NSNumber numberWithDouble:jitter]];
}

+(void)addUDPLoss:(double)loss{
    [MOSCalculation debugMessage:@"MOS Add Loss" withDouble:loss];
    [udpLosses addObject:[NSNumber numberWithDouble:loss]];
}

+(void)addEastPing:(double)ping{
    [MOSCalculation debugMessage:@"MOS Add East Ping" withDouble:ping];
    [eastPingAverages addObject:[NSNumber numberWithDouble:ping]];
}

+(void)addEastJitter:(double)jitter{
    [MOSCalculation debugMessage:@"MOS Add East Jitter" withDouble:jitter];
    [eastUdpJitters addObject:[NSNumber numberWithDouble:jitter]];
}

+(void)addEastUDPLoss:(double)loss{
    [MOSCalculation debugMessage:@"MOS Add East Loss" withDouble:loss];
    [eastUdpLosses addObject:[NSNumber numberWithDouble:loss]];
}

+(double)averageOfArray:(NSMutableArray *)array{
    double sum = 0;
    int arraySize = (int)[array count];
    for(int i = 0; i < arraySize; i++){
        sum += [[array objectAtIndex:i] doubleValue];
    }
    return sum / arraySize;
}

+(double)getMOS{
    
    double meanLatencey = [MOSCalculation averageOfArray:pingAverages];
    [MOSCalculation debugMessage:@"MOS Mean Latency" withDouble:meanLatencey];
    
    double meanJitter = [MOSCalculation averageOfArray:udpJitters];
    [MOSCalculation debugMessage:@"MOS Mean Jitter" withDouble:meanJitter];
    
    double effectiveLatencey = meanLatencey + meanJitter * 2 + 10;
    [MOSCalculation debugMessage:@"MOS Effective Latency" withDouble:effectiveLatencey];
    
    double meanPacketLoss = [MOSCalculation averageOfArray:udpLosses];
    [MOSCalculation debugMessage:@"MOS Mean Packet Loss" withDouble:meanPacketLoss];
    
    double rValue;
    if(effectiveLatencey < 160){
        rValue = 93.2 - (effectiveLatencey / 40) - 2.5 * meanPacketLoss;
    }
    else{
        rValue = 93.2 - (effectiveLatencey - 120) / 10 - 2.5 * meanPacketLoss;
    }
    [MOSCalculation debugMessage:@"MOS R-Value" withDouble:rValue];
    
    double finalMOS = 0;
    if(rValue > 0 && rValue < 101){
        finalMOS = 1 + 0.035 * rValue + 0.000007 * rValue * (rValue - 60) * (100 -rValue);
    }
    [MOSCalculation debugMessage:@"MOS Value" withDouble:finalMOS];
    
    return finalMOS;
}

+(double)getEastMOS{
    
    double meanLatencey = [MOSCalculation averageOfArray:eastPingAverages];
    [MOSCalculation debugMessage:@"East MOS Mean Latency" withDouble:meanLatencey];
    
    double meanJitter = [MOSCalculation averageOfArray:eastUdpJitters];
    [MOSCalculation debugMessage:@"East MOS Mean Jitter" withDouble:meanJitter];
    
    double effectiveLatencey = meanLatencey + meanJitter * 2 + 10;
    [MOSCalculation debugMessage:@"East MOS Effective Latency" withDouble:effectiveLatencey];
    
    double meanPacketLoss = [MOSCalculation averageOfArray:eastUdpLosses];
    [MOSCalculation debugMessage:@"East MOS Mean Packet Loss" withDouble:meanPacketLoss];
    
    double rValue;
    if(effectiveLatencey < 160){
        rValue = 93.2 - (effectiveLatencey / 40) - 2.5 * meanPacketLoss;
    }
    else{
        rValue = 93.2 - (effectiveLatencey - 120) / 10 - 2.5 * meanPacketLoss;
    }
    [MOSCalculation debugMessage:@"East MOS R-Value" withDouble:rValue];
    
    double finalMOS = 0;
    if(rValue > 0 && rValue < 101){
        finalMOS = 1 + 0.035 * rValue + 0.000007 * rValue * (rValue - 60) * (100 -rValue);
    }
    [MOSCalculation debugMessage:@"East MOS Value" withDouble:finalMOS];
    
    return finalMOS;
}

+(NSString*)calcVoip{
    //printf("East MOS: %f\n", [self getEastMOS]);
    double mosValueEast = [self getEastMOS];
    if (mosValueEast <= 0.0) {
        return @"N/A";
    } else if (mosValueEast < 3.0) {
        return @"Poor";
    } else if (mosValueEast < 4.0) {
        return @"Fair";
    } else {
        return @"Good";
    }
}

@end
