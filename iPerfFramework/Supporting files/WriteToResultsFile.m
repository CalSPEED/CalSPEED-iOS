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
#import "WriteToResultsFile.h"

@implementation WriteToResultsFile

-(void)initLog
{
    uploadLog = @"";
}

-(void)newReport: (NSString *) newReportString
{
    uploadLog = [NSString stringWithFormat:@"%@%@",uploadLog,newReportString];
}

-(void)newReport2: (NSString *) newReportString
{
    downloadLog = [NSString stringWithFormat:@"%@%@",downloadLog,newReportString];
}

-(BOOL)writeToFile
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex: 0];
    NSString *docFile = [docDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.txt", [TimeAndDate getDateForFileName]]];
    
    if([[uploadLog dataUsingEncoding:NSUTF8StringEncoding] writeToFile:docFile atomically:NO])
        return true;
    else return false;
    
}

-(BOOL)writeToUnixServer
{
    //Credentials for FTP server
    NMSSHSession *session = [NMSSHSession connectToHost:@"YOURHOSTIP"
                                           withUsername:@"YOURHOSTUSERNAME"];
    
    if (session.isConnected) {
        [session authenticateByPassword:@"YOURHOSEPASSWORD"];
        
        if (session.isAuthorized)
        {
            // NSLog(@"Authentication succeeded");
        }
    }
    else { //if there is not a connection, we leave this method, preventing a crash
        NSLog(@"No connection, stopping upload");
        return false;
    }
    
    //NSError *error = nil;
    //NSString *response = [session.channel execute:@"ls -l UploadData" error:&error];
    
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex: 0];
    
    NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:docDir];
    for (NSString *path in directoryEnumerator)
    {
        NSString *docFile = [docDir stringByAppendingPathComponent:path];
        if ([docFile rangeOfString:@"txt"].location == NSNotFound) continue; //if not a txt file, go back
        NSString *recipientPath = [NSString stringWithFormat:@"/home/iosuser/UploadData/%@",path];
        //NSString *recipientPath = [NSString stringWithFormat:@"/home/crowduser/UploadData/%@",path];
        BOOL success = [session.channel uploadFile:docFile to:recipientPath];
        if(success)
            [[NSFileManager defaultManager] removeItemAtPath:docFile error:nil];
        else
        {
            [session disconnect];
            return false;
        }
        
    }
    
    [session disconnect];
    
    return true;
    
}

- (NSString*)readStringFromFile
{
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"output"
                                                         ofType:@"txt"];
    // The main act...
    return [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:filePath] encoding:NSUTF8StringEncoding];
}


@end
