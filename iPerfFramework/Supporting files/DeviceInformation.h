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
#include <sys/types.h>
#include <sys/sysctl.h>
#include <mach/machine.h>
#import <sys/utsname.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "Reachability.h"
#import "FDKeychain.h"

@interface DeviceInformation : NSObject
{
    
    IBOutlet UITextView *reports;
    NSString* uploadLog;
    
}

-(void)setDoorStatus:(NSString *)whatDoorIsInStore;

-(NSString*) generateInformationWithLat:(float)latitude withLong:(float)longitude;
-(NSString*) getOperatorCarrier:(NSNumber*)mcc :(NSNumber*)mnc;
-(NSString*) getCPUType;
-(NSString*) getOSName;
-(NSString*) getOSVersion;
-(NSString*) getDeviceName;
-(NSString*) getNetworkType;
-(NSString*) getConnectionType;
+(NSString*) getDeviceID;
-(NSString*) getNetworkProvider;
-(NSString*) getNetworkOperator;
-(NSString*) deviceName;
- (BOOL)connected;

@end
