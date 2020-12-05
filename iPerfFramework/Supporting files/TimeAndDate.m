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

#import "TimeAndDate.h"
#import "Settings.hpp"

@implementation TimeAndDate

+ (NSString*) getDateForFileName
{
    NSDate *date = [NSDate date];
    NSDateFormatter *formattedDateForFile = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [formattedDateForFile setLocale:enUSPOSIXLocale];
    [formattedDateForFile setDateFormat:@"MMddyyyyHHmmss"];
    NSString *str_Date = [formattedDateForFile stringFromDate: date];
    return str_Date;
}

+ (NSString*) getDateForAlertView
{
    NSDate *date = [NSDate date];
    NSDateFormatter *formattedDate = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [formattedDate setLocale:enUSPOSIXLocale];
    [formattedDate setDateFormat:@"MM/dd/yyyy HH:mma"];
    NSString *str_Date = [formattedDate stringFromDate: date];
    return str_Date;
}

+ (NSString*) getDateForStartTime
{
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormat setLocale:enUSPOSIXLocale];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss TZD"];
    NSString *dateString = [dateFormat stringFromDate:date];
    print_to_console("Current Date: %s\n", [dateString cStringUsingEncoding:NSASCIIStringEncoding]);
    
    NSDateFormatter *nowDateFormatter = [[NSDateFormatter alloc] init];
    [nowDateFormatter setLocale:enUSPOSIXLocale];
    NSArray *daysOfWeek = @[@"",@"Sun",@"Mon",@"Tue",@"Wed",@"Thu",@"Fri",@"Sat"];
    [nowDateFormatter setDateFormat:@"e"];
    NSDate *newDate = [NSDate date];
    NSInteger weekdayNumber = (NSInteger)[[nowDateFormatter stringFromDate:newDate] integerValue];
    
    [nowDateFormatter setDateFormat:@"MM"];
    NSString *dateString2 = [nowDateFormatter stringFromDate:date];
    
    NSString *monthString;
    if([dateString2  isEqual: @"01"]) monthString = @"Jan";
    else if([dateString2  isEqual: @"02"]) monthString = @"Feb";
    else if([dateString2  isEqual: @"03"]) monthString = @"Mar";
    else if([dateString2  isEqual: @"04"]) monthString = @"Apr";
    else if([dateString2  isEqual: @"05"]) monthString = @"May";
    else if([dateString2  isEqual: @"06"]) monthString = @"Jun";
    else if([dateString2  isEqual: @"07"]) monthString = @"Jul";
    else if([dateString2  isEqual: @"08"]) monthString = @"Aug";
    else if([dateString2  isEqual: @"09"]) monthString = @"Sep";
    else if([dateString2  isEqual: @"10"]) monthString = @"Oct";
    else if([dateString2  isEqual: @"11"]) monthString = @"Nov";
    else if([dateString2  isEqual: @"12"]) monthString = @"Dec";
    
    [nowDateFormatter setDateFormat:@"dd"];
    NSString *dayString = [nowDateFormatter stringFromDate:date];
    
    [nowDateFormatter setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [nowDateFormatter stringFromDate:date];
    
    [nowDateFormatter setDateFormat:@"yyyy"];
    NSString *yearString = [nowDateFormatter stringFromDate:date];
    
    print_to_console("Testing started at %s %s %s %s %s %s\n",[[daysOfWeek objectAtIndex:weekdayNumber] cStringUsingEncoding:NSASCIIStringEncoding], [monthString cStringUsingEncoding:NSASCIIStringEncoding], [dayString cStringUsingEncoding:NSASCIIStringEncoding], [timeString cStringUsingEncoding:NSASCIIStringEncoding],[[[NSTimeZone systemTimeZone] abbreviation] cStringUsingEncoding:NSASCIIStringEncoding], [yearString cStringUsingEncoding:NSASCIIStringEncoding]);
    
    return [NSString stringWithFormat:@"Testing started at %@ %@ %@ %@ %@ %@\n\n",
            [daysOfWeek objectAtIndex:weekdayNumber],
            monthString,
            dayString,
            timeString,
            [[NSTimeZone systemTimeZone] abbreviation],
            yearString];
}
@end
