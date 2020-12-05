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

#import "DeviceInformation.h"

@implementation DeviceInformation

NSString* typeOfNetwork;

NSString *doorStatus = @"Indoors";

static NSString * const KeychainItem_Service = @"FDKeychain";
static NSString * const KeychainItem_UUID = @"Local";

-(void)setDoorStatus:(NSString *)whatDoorIsInStore{ // Because we love doors that much
    doorStatus = whatDoorIsInStore;
}


-(NSString*) getOSName
{
    return [[UIDevice currentDevice] systemName];
}

-(NSString*) getOSVersion
{
    return [[UIDevice currentDevice] systemVersion];
}


-(NSString*) getDeviceName
{
    return [[UIDevice currentDevice] model];
}

-(NSString*) getCPUType
{
    NSMutableString *cpu = [[NSMutableString alloc] init];
    size_t size;
    cpu_type_t type;
    cpu_subtype_t subtype;
    size = sizeof(type);
    sysctlbyname("hw.cputype", &type, &size, NULL, 0);
    
    size = sizeof(subtype);
    sysctlbyname("hw.cpusubtype", &subtype, &size, NULL, 0);
    
    // values for cputype and cpusubtype defined in mach/machine.h
    if (type == CPU_TYPE_X86)
    {
        [cpu appendString:@"x86"];
        // check for subtype ...
        
    } else if (type == CPU_TYPE_ARM64)
    {
        [cpu appendString:@"ARM64"];
        switch(subtype)
        {
            case CPU_SUBTYPE_ARM64_V8:
                [cpu appendString:@"V8"];
                break;
                // ...
        }
    } else if (type == CPU_TYPE_ARM)
    {
        [cpu appendString:@"ARM"];
        switch(subtype)
        {
            case CPU_SUBTYPE_ARM_V7:
                [cpu appendString:@"V7"];
                break;
                // ...
        }
    }
    return cpu;
}

-(NSString*) getNetworkType
{
    NetworkStatus wifiStatus = [[Reachability reachabilityForLocalWiFi] currentReachabilityStatus];
    NetworkStatus internetStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    
    if (wifiStatus == ReachableViaWiFi) {
        typeOfNetwork = [NSString stringWithFormat:@"WIFI"];
        return [NSString stringWithFormat:@"WIFI"];
        
    }
    else if (wifiStatus != ReachableViaWiFi && internetStatus == ReachableViaWWAN) {
        typeOfNetwork = [NSString stringWithFormat:@"MOBILE"];
        return [NSString stringWithFormat:@"MOBILE"];
    }
    else {
        typeOfNetwork = [NSString stringWithFormat:@"No Connection"];
        return [NSString stringWithFormat:@"No Connection"];
    }
}

-(NSString*) getConnectionType
{
    if([typeOfNetwork isEqualToString:@"WIFI"]){
        return [NSString stringWithFormat:@"WIFI"];
    }
    else if([typeOfNetwork isEqualToString:@"MOBILE"]) {
        CTTelephonyNetworkInfo *telephonyInfo = [CTTelephonyNetworkInfo new];
        NSString *radioTech = [NSString stringWithFormat:@"%@", telephonyInfo.currentRadioAccessTechnology];
        if(radioTech == nil)
            return [NSString stringWithFormat:@"NA"];
        return [radioTech stringByReplacingOccurrencesOfString:@"CTRadioAccessTechnology"
                                                    withString:@""];
    }
    else {
        return [NSString stringWithFormat:@"No Connection"];
    }
}

+(NSString*) getDeviceID
{
    NSString *CFUUID = nil;
    
    if (![FDKeychain itemForKey: KeychainItem_UUID
                     forService: KeychainItem_Service
                          error: nil]) {
        CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
        
        CFUUID = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));
        
        [FDKeychain saveItem: CFUUID
                      forKey: KeychainItem_UUID
                  forService: KeychainItem_Service
                       error: nil];
        
    } else {
        CFUUID = [FDKeychain itemForKey: KeychainItem_UUID
                             forService: KeychainItem_Service
                                  error: nil];
    }
    
    return CFUUID;
}

-(NSString*) getNetworkProvider
{
    CTTelephonyNetworkInfo *CTTnetwork = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *CTcarrier = [CTTnetwork subscriberCellularProvider];
    
    NSString *CTcarrierString = [CTcarrier carrierName];
    
    if([CTcarrierString length] == 0)
        return @"Unknown";
    return CTcarrierString;
}

//if roaming, these values update, which carrierName is tied to SIM
-(NSString*) getNetworkOperator
{
    CTTelephonyNetworkInfo *CTTnetwork = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *CTcarrier = [CTTnetwork subscriberCellularProvider];
    
    //these values change when roaming
    NSString *mcc = [CTcarrier mobileCountryCode];
    NSString *mnc = [CTcarrier mobileNetworkCode];
    
    //method call to convert mcc/mnc to network
    return [self getOperatorCarrier:@([mcc intValue]):@([mnc intValue])];
}

-(NSString*) generateInformationWithLat:(float)latitude withLong:(float)longitude
{
    return [NSString stringWithFormat:@"OS: Name = %@, Architecture = %@, Version = %@\nDevice Name: %@\nNetworkType: %@\n\n\nLastKnownLat:%f\nLastKnownLong:%f\n\n\nNetworkProvider: %@\nNetworkOperator: %@\nThis device was %@\nConnectionType: %@\n\n",
            [self getOSName],
            [self getCPUType],
            [self getOSVersion],
            [self deviceName],
            [self getNetworkType],
            latitude,
            longitude,
            [self getNetworkProvider],
            [self getNetworkOperator],
            doorStatus,
            [self getConnectionType] ];
}

-(NSString*) deviceName
{
    struct utsname systemInfo;
    
    uname(&systemInfo);
    
    NSString* code = [NSString stringWithCString:systemInfo.machine
                                        encoding:NSUTF8StringEncoding];
    
    static NSDictionary* deviceNamesByCode = nil;
    
    if (!deviceNamesByCode) {
        
        deviceNamesByCode = @{
                              //iPhones
                              @"iPhone3,1"  : @"iPhone 4",
                              @"iPhone3,2"  : @"iPhone 4",
                              @"iPhone3,3"  : @"iPhone 4",
                              @"iPhone4,1"  : @"iPhone 4S",
                              @"iPhone4,2"  : @"iPhone 4S",
                              @"iPhone4,3"  : @"iPhone 4S",
                              @"iPhone5,1"  : @"iPhone 5",
                              @"iPhone5,2"  : @"iPhone 5",
                              @"iPhone5,3"  : @"iPhone 5C",
                              @"iPhone5,4"  : @"iPhone 5C",
                              @"iPhone6,1"  : @"iPhone 5S",
                              @"iPhone6,2"  : @"iPhone 5S",
                              @"iPhone7,2"  : @"iPhone 6",
                              @"iPhone7,1"  : @"iPhone 6 Plus",
                              @"iPhone8,1"  : @"iPhone 6S",
                              @"iPhone8,2"  : @"iPhone 6S Plus",
                              @"iPhone8,4"  : @"iPhone SE",
                              @"iPhone9,1"  : @"iPhone 7",
                              @"iPhone9,3"  : @"iPhone 7",
                              @"iPhone9,2"  : @"iPhone 7 Plus",
                              @"iPhone9,4"  : @"iPhone 7 Plus",
                              @"iPhone10,1" : @"iPhone 8",
                              @"iPhone10,4" : @"iPhone 8",
                              @"iPhone10,2" : @"iPhone 8 Plus",
                              @"iPhone10,5" : @"iPhone 8 Plus",
                              @"iPhone10,3" : @"iPhone X",
                              @"iPhone10,6" : @"iPhone X",
                              @"iPhone11,2" : @"iPhone XS",
                              @"iPhone11,4" : @"iPhone XS Max",
                              @"iPhone11,8" : @"iPhone XR",
                              @"iPhone11,6" : @"iPhone XS Max ",
                              @"iPhone11,8" : @"iPhone XR",
                              @"iPhone12,1" : @"iPhone 11",
                              @"iPhone12,3" : @"iPhone 11 Pro",
                              @"iPhone12,5" : @"iPhone 11 Pro Max",
                              @"iPhone12,8" : @"iPhone SE 2nd Gen",
                              @"iPhone13,1" : @"iPhone 12 Mini",
                              @"iPhone13,2" : @"iPhone 12",
                              @"iPhone13,3" : @"iPhone 12 Pro",
                              @"iPhone13,4" : @"iPhone 12 Pro Max",
                              @"i386"       : @"Simulator",
                              @"x86_64"     : @"Simulator",
                              
                              //iPads
                              @"iPad1,1"  : @"iPad 1",
                              @"iPad2,1"  : @"iPad 2",
                              @"iPad2,2"  : @"iPad 2",
                              @"iPad2,3"  : @"iPad 2",
                              @"iPad2,4"  : @"iPad 2",
                              @"iPad2,5"  : @"iPad Mini",
                              @"iPad2,6"  : @"iPad Mini",
                              @"iPad2,7"  : @"iPad Mini",
                              @"iPad3,1"  : @"iPad 3",
                              @"iPad3,2"  : @"iPad 3",
                              @"iPad3,3"  : @"iPad 3",
                              @"iPad3,4"  : @"iPad 4",
                              @"iPad3,5"  : @"iPad 4",
                              @"iPad3,6"  : @"iPad 4",
                              @"iPad4,1"  : @"iPad Air",
                              @"iPad4,2"  : @"iPad Air",
                              @"iPad4,3"  : @"iPad Air",
                              @"iPad4,4"  : @"iPad Mini 2",
                              @"iPad4,5"  : @"iPad Mini 2",
                              @"iPad4,6"  : @"iPad Mini 2",
                              @"iPad4,7"  : @"iPad Mini 3",
                              @"iPad4,8"  : @"iPad Mini 3",
                              @"iPad4,9"  : @"iPad Mini 3",
                              @"iPad5,1"  : @"iPad Mini 4",
                              @"iPad5,2"  : @"iPad Mini 4",
                              @"iPad5,3"  : @"iPad Air 2",
                              @"iPad5,4"  : @"iPad Air 2",
                              @"iPad6,3"  : @"iPad Pro 9Dot7 Inch",
                              @"iPad6,4"  : @"iPad Pro 9Dot7 Inch",
                              @"iPad6,7"  : @"iPad Pro 12Dot9 Inch",
                              @"iPad6,8"  : @"iPad Pro 12Dot9 Inch",
                              @"iPad6,11" : @"iPad 5",
                              @"iPad6,12" : @"iPad 5",
                              @"iPad7,1"  : @"iPad Pro 12Dot9 Inch 2Gen",
                              @"iPad7,2"  : @"iPad Pro 12Dot9 Inch 2Gen",
                              @"iPad7,3"  : @"iPad Pro 10Dot5 Inch",
                              @"iPad7,4"  : @"iPad Pro 10Dot5 Inch",
                              @"iPad7,5" : @"iPad 6th Gen (WiFi)",
                              @"iPad7,6" : @"iPad 6th Gen (WiFi+Cellular)",
                              @"iPad7,11" : @"iPad 7th Gen 10.2-inch (WiFi)",
                              @"iPad7,12" : @"iPad 7th Gen 10.2-inch (WiFi+Cellular)",
                              @"iPad8,1" : @"iPad Pro 11 inch 3rd Gen (WiFi)",
                              @"iPad8,2" : @"iPad Pro 11 inch 3rd Gen (1TB, WiFi)",
                              @"iPad8,3" : @"iPad Pro 11 inch 3rd Gen (WiFi+Cellular)",
                              @"iPad8,4" : @"iPad Pro 11 inch 3rd Gen (1TB, WiFi+Cellular)",
                              @"iPad8,5" : @"iPad Pro 12.9 inch 3rd Gen (WiFi)",
                              @"iPad8,6" : @"iPad Pro 12.9 inch 3rd Gen (1TB, WiFi)",
                              @"iPad8,7" : @"iPad Pro 12.9 inch 3rd Gen (WiFi+Cellular)",
                              @"iPad8,8" : @"iPad Pro 12.9 inch 3rd Gen (1TB, WiFi+Cellular)",
                              @"iPad8,9" : @"iPad Pro 11 inch 4th Gen (WiFi)",
                              @"iPad8,10" : @"iPad Pro 11 inch 4th Gen (WiFi+Cellular)",
                              @"iPad8,11" : @"iPad Pro 12.9 inch 4th Gen (WiFi)",
                              @"iPad8,12" : @"iPad Pro 12.9 inch 4th Gen (WiFi+Cellular)",
                              @"iPad11,1" : @"iPad mini 5th Gen (WiFi)",
                              @"iPad11,2" : @"iPad mini 5th Gen",
                              @"iPad11,3" : @"iPad Air 3rd Gen (WiFi)",
                              @"iPad11,4" : @"iPad Air 3rd Gen",
                              @"iPad11,6" : @"iPad 8th Gen (WiFi)",
                              @"iPad11,7" : @"iPad 8th Gen (WiFi+Cellular)",
                              @"iPad13,1" : @"iPad air 4th Gen (WiFi)",
                              @"iPad13,2" : @"iPad air 4th Gen (WiFi+Celular)",
                              
                              //iPods
                              @"iPod1,1" : @"iPodTouch1Gen",
                              @"iPod2,1" : @"iPodTouch2Gen",
                              @"iPod3,1" : @"iPodTouch3Gen",
                              @"iPod4,1" : @"iPodTouch4Gen",
                              @"iPod5,1" : @"iPodTouch5Gen",
                              @"iPod7,1" : @"iPodTouch6Gen",
                              @"iPod9,1" : @"iPodTouch7Gen"
                              };
    }
    
    NSString* deviceName = [deviceNamesByCode objectForKey:code];
    
    if (!deviceName) {
        // Not found on database. At least guess main device type from string contents:
        
        if ([code rangeOfString:@"iPod"].location != NSNotFound) {
            deviceName = @"iPod Touch";
        }
        else if([code rangeOfString:@"iPad"].location != NSNotFound) {
            deviceName = @"iPad";
        }
        else if([code rangeOfString:@"iPhone"].location != NSNotFound){
            deviceName = @"iPhone";
        }
        else {
            deviceName = @"iPhone Simulator";
        }
    }
    
    return deviceName;
}

-(NSString*) getOperatorCarrier:(NSNumber*)mcc :(NSNumber*)mnc
{
    NSDictionary *mcc310 = @{
                             [NSNumber numberWithInt:4] : @"Verizon Wireless",
                             [NSNumber numberWithInt:5] : @"Verizon Wireless",
                             [NSNumber numberWithInt:6] : @"Verizon Wireless",
                             [NSNumber numberWithInt:12] : @"Verizon Wireless",
                             [NSNumber numberWithInt:14] : @"Testing",
                             [NSNumber numberWithInt:16] : @"Cricket Wireless",
                             [NSNumber numberWithInt:17] : @"North Sight Communications Inc.",
                             [NSNumber numberWithInt:20] : @"Union Telephone Company",
                             [NSNumber numberWithInt:26] : @"T-Mobile",
                             [NSNumber numberWithInt:30] : @"AT&T Mobility",
                             [NSNumber numberWithInt:34] : @"Airpeak",
                             [NSNumber numberWithInt:40] : @"Concho Cellular Telephone Co., Inc.",
                             [NSNumber numberWithInt:46] : @"TMP Corp",
                             [NSNumber numberWithInt:53] : @"Virgin Mobile US",
                             [NSNumber numberWithInt:54] : @"Alltel US",
                             [NSNumber numberWithInt:60] : @"Consolidated Telcom",
                             [NSNumber numberWithInt:66] : @"U.S. Cellular",
                             [NSNumber numberWithInt:70] : @"Highland Cellular",
                             [NSNumber numberWithInt:80] : @"Corr Wireless Communications LLC",
                             [NSNumber numberWithInt:90] : @"Cricket Wireless",
                             [NSNumber numberWithInt:100] : @"New Mexico RSA 4 East Ltd. Partnership",
                             [NSNumber numberWithInt:110] : @"PTI Pacifica Inc.",
                             [NSNumber numberWithInt:120] : @"Sprint Corporation",
                             [NSNumber numberWithInt:130] : @"Carolina Wireless",
                             [NSNumber numberWithInt:150] : @"Cricket Wireless",
                             [NSNumber numberWithInt:160] : @"T-Mobile US",
                             [NSNumber numberWithInt:170] : @"AT&T Mobility",
                             [NSNumber numberWithInt:180] : @"West Central Wireless",
                             [NSNumber numberWithInt:190] : @"Alaska Wireless Communications, LLC",
                             [NSNumber numberWithInt:200] : @"T-Mobile",
                             [NSNumber numberWithInt:210] : @"T-Mobile",
                             [NSNumber numberWithInt:220] : @"T-Mobile",
                             [NSNumber numberWithInt:230] : @"T-Mobile",
                             [NSNumber numberWithInt:240] : @"T-Mobile",
                             [NSNumber numberWithInt:250] : @"T-Mobile",
                             [NSNumber numberWithInt:260] : @"T-Mobile USA",
                             [NSNumber numberWithInt:270] : @"T-Mobile",
                             [NSNumber numberWithInt:280] : @"AT&T Mobility",
                             [NSNumber numberWithInt:290] : @"T-Mobile",
                             [NSNumber numberWithInt:300] : @"Smart Call (Truphone)",
                             [NSNumber numberWithInt:310] : @"T-Mobile",
                             [NSNumber numberWithInt:311] : @"Farmers Wireless",
                             [NSNumber numberWithInt:320] : @"Smith Bagley, Inc.",
                             [NSNumber numberWithInt:330] : @"T-Mobile",
                             [NSNumber numberWithInt:340] : @"Westlink Communications",
                             [NSNumber numberWithInt:350] : @"Carolina Phone",
                             [NSNumber numberWithInt:380] : @"AT&T Mobility",
                             [NSNumber numberWithInt:390] : @"TX-11 Acquisition, LLC",
                             [NSNumber numberWithInt:400] : @"Wave Runner LLC (Guam)",
                             [NSNumber numberWithInt:410] : @"AT&T Mobility",
                             [NSNumber numberWithInt:420] : @"Cincinnati Bell Wireless",
                             [NSNumber numberWithInt:430] : @"Alaska Digitel",
                             [NSNumber numberWithInt:450] : @"Viaero Wireless",
                             [NSNumber numberWithInt:460] : @"TMP Corporation",
                             [NSNumber numberWithInt:480] : @"Choice Phone",
                             [NSNumber numberWithInt:510] : @"Airtel Wireless",
                             [NSNumber numberWithInt:530] : @"West Virginia Wireless",
                             [NSNumber numberWithInt:540] : @"Oklahoma Western Telephone Company",
                             [NSNumber numberWithInt:560] : @"AT&T Mobility",
                             [NSNumber numberWithInt:570] : @"MTPCS, LLC",
                             [NSNumber numberWithInt:590] : @"Alltel Communications Inc",
                             [NSNumber numberWithInt:600] : @"New Cell Inc. dba Cellcom",
                             [NSNumber numberWithInt:610] : @"Elkhart Telephone Co.",
                             [NSNumber numberWithInt:620] : @"Coleman County Telecommunications",
                             [NSNumber numberWithInt:630] : @"Choice Wireless",
                             [NSNumber numberWithInt:640] : @"Airadigm Communications",
                             [NSNumber numberWithInt:650] : @"Jasper Wireless, inc",
                             [NSNumber numberWithInt:670] : @"NorthStar",
                             [NSNumber numberWithInt:680] : @"AT&T Mobility",
                             [NSNumber numberWithInt:690] : @"Immix Wireless",
                             [NSNumber numberWithInt:730] : @"SeaMobile",
                             [NSNumber numberWithInt:740] : @"Convey Communications Inc.",
                             [NSNumber numberWithInt:750] : @"Appalachian Wireless",
                             [NSNumber numberWithInt:760] : @"Panhandle Telecommunications Systems Inc.",
                             [NSNumber numberWithInt:770] : @"Iowa Wireless Services",
                             [NSNumber numberWithInt:780] : @"Airlink PCS",
                             [NSNumber numberWithInt:790] : @"PinPoint Communications",
                             [NSNumber numberWithInt:800] : @"T-Mobile",
                             [NSNumber numberWithInt:830] : @"Caprock Cellular",
                             [NSNumber numberWithInt:840] : @"Telecom North America Mobile, Inc.",
                             [NSNumber numberWithInt:850] : @"Aeris Communications, Inc.",
                             [NSNumber numberWithInt:870] : @"Kaplan Telephone Company",
                             [NSNumber numberWithInt:880] : @"Advantage Cellular Systems",
                             [NSNumber numberWithInt:890] : @"Rural Cellular Corporation",
                             [NSNumber numberWithInt:900] : @"Mid-Rivers Communications",
                             [NSNumber numberWithInt:910] : @"First Cellular of Southern Illinois",
                             [NSNumber numberWithInt:940] : @"Iris Wireless LLC",
                             [NSNumber numberWithInt:950] : @"Texas RSA 1 dba XIT Cellular",
                             [NSNumber numberWithInt:960] : @"Plateau Wireless",
                             [NSNumber numberWithInt:970] : @"Globalstar",
                             [NSNumber numberWithInt:970] : @"Telemedicine Wireless (USA) Telecommunications,Inc",
                             [NSNumber numberWithInt:980] : @"AT&T (Antarctica, South Pole) Worldwide, Inc.",
                             [NSNumber numberWithInt:990] : @"AT&T Mobility",
                             };
    
    NSDictionary *mcc311 = @{
                             [NSNumber numberWithInt:0] : @"Mid-Tex Cellular",
                             [NSNumber numberWithInt:10] : @"Chariton Valley Communications",
                             [NSNumber numberWithInt:12] : @"Verizon Wireless",
                             [NSNumber numberWithInt:20] : @"Missouri RSA 5 Partnership",
                             [NSNumber numberWithInt:30] : @"Indigo Wireless",
                             [NSNumber numberWithInt:40] : @"Commnet Wireless",
                             [NSNumber numberWithInt:50] : @"Wikes Cellular",
                             [NSNumber numberWithInt:60] : @"Farmers Cellular Telephone",
                             [NSNumber numberWithInt:70] : @"Easterbrooke Cellular Corporation",
                             [NSNumber numberWithInt:80] : @"Pine Telephone Company",
                             [NSNumber numberWithInt:90] : @"Long Lines Wireless LLC",
                             [NSNumber numberWithInt:100] : @"High Plains Wireless",
                             [NSNumber numberWithInt:110] : @"High Plains Wireless",
                             [NSNumber numberWithInt:120] : @"Choice Phone",
                             [NSNumber numberWithInt:130] : @"Cell One Amarillo",
                             [NSNumber numberWithInt:140] : @"MBO Wireless",
                             [NSNumber numberWithInt:150] : @"Wilkes Cellular",
                             [NSNumber numberWithInt:160] : @"Endless Mountains Wireless",
                             [NSNumber numberWithInt:170] : @"Broadpoint Inc",
                             [NSNumber numberWithInt:180] : @"Cingular Wireless",
                             [NSNumber numberWithInt:190] : @"Cellular Properties",
                             [NSNumber numberWithInt:210] : @"Emery Telcom Wireless",
                             [NSNumber numberWithInt:220] : @"U.S. Cellular",
                             [NSNumber numberWithInt:230] : @"C Spire Wireless",
                             [NSNumber numberWithInt:330] : @"Bug Tussel Wireless",
                             [NSNumber numberWithInt:360] : @"Stelera Wireless",
                             [NSNumber numberWithInt:370] : @"General Communication Inc.",
                             [NSNumber numberWithInt:480] : @"Verizon Wireless",
                             [NSNumber numberWithInt:481] : @"Verizon Wireless",
                             [NSNumber numberWithInt:482] : @"Verizon Wireless",
                             [NSNumber numberWithInt:483] : @"Verizon Wireless",
                             [NSNumber numberWithInt:484] : @"Verizon Wireless",
                             [NSNumber numberWithInt:485] : @"Verizon Wireless",
                             [NSNumber numberWithInt:486] : @"Verizon Wireless",
                             [NSNumber numberWithInt:487] : @"Verizon Wireless",
                             [NSNumber numberWithInt:488] : @"Verizon Wireless",
                             [NSNumber numberWithInt:489] : @"Verizon Wireless",
                             [NSNumber numberWithInt:490] : @"Sprint",
                             [NSNumber numberWithInt:500] : @"Mosaic Telecom",
                             [NSNumber numberWithInt:530] : @"Panhandle Wireless",
                             [NSNumber numberWithInt:570] : @"BendBroadband",
                             [NSNumber numberWithInt:580] : @"U.S. Cellular",
                             [NSNumber numberWithInt:650] : @"United Wireless",
                             [NSNumber numberWithInt:660] : @"metroPCS",
                             [NSNumber numberWithInt:750] : @"NetAmerica Alliance",
                             [NSNumber numberWithInt:810] : @"Bluegrass Wireless",
                             [NSNumber numberWithInt:870] : @"Boost Mobile",
                             [NSNumber numberWithInt:930] : @"Syringa Wireless",
                             [NSNumber numberWithInt:950] : @"Enhanced Telecommmunications Corp.(Sunman Telecom)",
                             [NSNumber numberWithInt:960] : @"Lyca Technology Solutions",
                             [NSNumber numberWithInt:970] : @"Big River Broadband, LLC",
                             [NSNumber numberWithInt:990] : @"VTel Wireless",
                             };
    
    NSDictionary *mcc312 = @{
                             [NSNumber numberWithInt:50] : @"Fuego Wireless",
                             [NSNumber numberWithInt:70] : @"Adams Networks Inc",
                             [NSNumber numberWithInt:80] : @"South Georgia Regional Information Technology Authority",
                             [NSNumber numberWithInt:220] : @"Chariton Valley Telephone",
                             [NSNumber numberWithInt:330] : @"Sagebrush Cellular",
                             [NSNumber numberWithInt:350] : @"Triangle Communications",
                             [NSNumber numberWithInt:370] : @"Choice Wireless",
                             [NSNumber numberWithInt:420] : @"Nex-Tech Wireless",
                             [NSNumber numberWithInt:530] : @"Sprint Spectrum",
                             [NSNumber numberWithInt:590] : @"Northern Michigan University",
                             [NSNumber numberWithInt:610] : @"nTelos",
                             };
    NSDictionary *mcc316 = @{
                             [NSNumber numberWithInt:10] : @"Nextel Communications",
                             [NSNumber numberWithInt:11] : @"Southern Communications Services",
                             };
    
    if([mcc intValue] == 310)
        return mcc310[mnc];
    else if([mcc intValue] == 311)
        return mcc311[mnc];
    else if([mcc intValue] == 312)
        return mcc312[mnc];
    else if([mcc intValue] == 316)
        return mcc316[mnc];
    else
        return @"Unknown";
}

- (BOOL)connected
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    return networkStatus != NotReachable;
}

@end

