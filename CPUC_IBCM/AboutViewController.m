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

#import "AboutViewController.h"
#import "AppDelegate.h"

@implementation AboutViewController

@synthesize willDisplayMapViewText;

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    willDisplayMapViewText = false;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    [attributedString appendAttributedString:[self createAttributedHeaderWithText:[NSString stringWithFormat:@"About CalSPEED Version %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]]];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n"]];
    
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:86/255.0 green:178/255.0 blue:227/255.0 alpha:1.0];
    
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:86/255.0 green:178/255.0 blue:227/255.0 alpha:1.0]];
    
    if(willDisplayMapViewText)
        [self generateMapViewAboutText:attributedString];
    else
        [self generateDefaultAboutText:attributedString];
    
    [textView setAttributedText:attributedString];
    
    [textView scrollRangeToVisible:NSMakeRange(0, 0)];
}

-(void)generateDefaultAboutText:(NSMutableAttributedString *)attributedString{
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:
                                              @"CalSPEED, released by the California Public Utilities Commission (CPUC), empowers end-users with a professional-level, industry-standard testing tool to measure the quality and speed of their mobile data connection. "
                                              "CalSPEED conducts a two-step test with a California server and a Virginia server in order to ensure statistically significant measurements. "
                                              "The test captures upload speed, download speed, message delay (latency), and message delay variation (jitter). "
                                              "The first two metrics measure broadband throughput, while the second two measure the streaming quality of your mobile broadband connection. "
                                              "A brief results history of each test is stored locally, displaying a detailed description when a test is selected. "
                                              "The results are uploaded to a public repository at the CPUC to provide you with the ability to compare broadband coverage and performance at your location with that in other areas of California.\n\n"
                                              
                                              "The test results may vary based on factors such as location, end-user hardware, network congestion, and time of day. "
                                              "If you receive a results ‘Incomplete’ message, it is because one of these factors has hindered the collection of valid results. "
                                              "Please try running the test again.\n\n"]];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:
                                              @"The MOS (Mean Opinion Score) classification for a test result is as follows:\n"
                                              "\t- The thumbs-up icon means the MOS score is\n\t  higher than or equal to 4.0, which is satisfactory.\n"
                                              "\t- The thumbs-down icon means the MOS score is\n\t  lower than 4.0, which is unsatisfactory.\n\n"]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:
                                              @"Video streaming quality is based on the test result to the California server:\n"
                                              "\t- HD (High Definition): Smooth streaming of 720p\n\t  or above\n"
                                              "\t- SD (Standard Definition): Smooth streaming\n\t  between 380p and 720p\n"
                                              "\t- LD (Lower Definition): Streaming less than 380p\n"
                                              "\t- N/A: We can't determine the quality.\n\n"]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:
                                              @"Video conference quality is based on the test result to the Virginia server:\n"
                                              "\t- HD (High Definition): Smooth video\n\t  conferencing of 720p or above\n"
                                              "\t- SD (Standard Definition): Smooth video\n\t  conferencing between 380p and 720p\n"
                                              "\t- LD (Lower Definition): Video conferencing less\n\t  than 380p\n"
                                              "\t- N/A: We can't determine the quality.\n\n"]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:
                                              @"VoIP (Voice over IP) quality is based on the test result to the Virginia server:\n"
                                              "\t- Good: MOS value 4.0 or higher\n"
                                              "\t- Fair: MOS value between 3.0 and 4.0\n"
                                              "\t- Poor: MOS value 3.0 or less\n"
                                              "\t- N/A: We can't determine the quality.\n\n"]];
    
    [attributedString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:
                                              @"Please note that, depending on the network connection, tests in CalSPEED may use a lot of data capacity. "
                                              "As with any mobile application, monitor your usage relative to your particular data plan. "
                                              "The CPUC does not assume any responsibility for charges incurred while running CalSPEED.\n\n"
                                                                                    attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)}]];
    
    [attributedString appendAttributedString:[self createAttributedHeaderWithText:@"About the CPUC"]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:
                                              @"\n\nThe California Public Utilities Commission (CPUC) is the California recipient of an $8,000,000 State Broadband Data and Development Grant, awarded by the National Telecommunications and Information Administration (NTIA) under the American Recovery and Reinvestment Act (ARRA). "
                                              "A portion of this Grant funds the development, maintenance, and operation of CalSPEED.\n\n"
                                              
                                              "CalSPEED is developed by California State University, Monterey Bay's Computer Science Program.\n\n"]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Contact: " attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Helvetica-Bold" size:12.0]}]];
    
    [attributedString appendAttributedString:[self createAttributedLinkWithString:@"calspeed@cpuc.ca.gov" withLink:@"calspeed@cpuc.ca.gov"]];
}

-(void)generateMapViewAboutText:(NSMutableAttributedString *)attributedString{
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:
                                      @"CalSPEED, released by the California Public Utilities Commission (CPUC), is a mobile app for California citizens to view broadband services in their area. "
                                      "The app displays advertised upload and download speeds from broadband providers offering service in the area. "
                                      "It also displays estimated upload and download speeds of the four major mobile providers based on the mobile broadband drive-test, which is conducted by CPUC. "
                                      "The data currently displayed represents the situation as of December 31, 2012 and will be updated approximately every six months.\n\n"
                                      
                                      "The information displayed in the CalSPEED is not accurate down to a user's exact location. "
                                      "CalSPEED is intended to give the general public the most accurate information available to the CPUC about service speeds in the area where the application is being used, or in the area near an address provided by the user. "
                                      "Contact the providers displayed in the CalSPEED for service availability and speeds at a particular address.\n\n"
                                      
                                      "The app displays upload and download speeds in four categories: advertised fixed, advertised mobile, estimated mobile, and advertised satellite. "
                                      "The \"advertised fixed\" category displays advertised speeds of all services which are delivered to a particular, stationary location. "
                                      "Such services are provided using several different technologies, including \"wireline\" technologies such as xDSL, Cable Modem, or Fiber to the home, as well as fixed wireless. "
                                      "The \"advertised mobile\" category displays speeds of \"mobile wireless\" technologies, such as 3G, 4G, or LTE, to provide service to users (i.e., cellular broadband) who can receive a broadband signal while they are in motion. "
                                      "The \"estimated mobile\" category displays estimated wireless speeds of the four major mobile providers -- AT&T, Sprint, T-Mobile, and Verizon -- based on the CPUC's semi-annual mobile broadband drive test. "
                                      "For more detailed information on the drive test, see "]];
    
    [attributedString appendAttributedString:[self createAttributedLinkWithString:@"this link" withLink:@"http://www.cpuc.ca.gov/General.aspx?id=1778"]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@". The \"advertised satellite\" category displays speeds of satellite providers.\n\n"
                                      "The arrows in the results display indicate upstream speed (arrow pointing up) and downstream speed (arrow pointing down).The units used in the sliding bar scale are in megabits per second (Mb/s, or Mpbs).\n\nThe color scheme is "]];
    
    [attributedString appendAttributedString:[self createAttributedStringWithColor:[UIColor redColor] withText:@"red" toAppend:@", "]];
    
    [attributedString appendAttributedString:[self createAttributedStringWithColor:[UIColor orangeColor] withText:@"orange" toAppend:@", and "]];
    
    [attributedString appendAttributedString:[self createAttributedStringWithColor:[UIColor greenColor] withText:@"green" toAppend:@".\n\n"]];
    
    [attributedString appendAttributedString:[self createAttributedStringWithColor:[UIColor redColor] withText:@"Red" toAppend:@" indicates speeds falling below the FCC's broadband definition of .200 Mb/s for upstream, and for downstream, below .768 Mb/s.\n\n"]];
    
    [attributedString appendAttributedString:[self createAttributedStringWithColor:[UIColor orangeColor] withText:@"Orange" toAppend:@" indicates speeds equal or greater than .200 Mb/s for upstream, and .768 Mb/s for downstream but less than 1.50 Mb/s for upstream and 6.00 Mb/s for downstream.\n\n"]];
    
    [attributedString appendAttributedString:[self createAttributedStringWithColor:[UIColor greenColor] withText:@"Green" toAppend:@" indicates speeds equal or greater than 1.50 Mb/s for upstream and 6.00 Mb/s for downstream.\n\n"]];
    
    [attributedString appendAttributedString:[self createAttributedHeaderWithText:@"About the CPUC"]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\nThe California Public Utilities Commission is the California recipient of a State Broadband Initiative Grant, awarded by the National Telecommunications and Information Administration under the American Recovery and Reinvestment Act. "
                                      "A portion of this Grant funds the development, maintenance, and operation of CalBroadband.\n\n"
                                      "CalSPEED is developed by California State University, Monterey Bay's Computer Science and Information Technology Program under contract with the CPUC. Contact: "]];
    
    [attributedString appendAttributedString:[self createAttributedLinkWithString:@"calspeed@cpuc.ca.gov" withLink:@"calspeed@cpuc.ca.gov"]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n"]];
    
    [attributedString appendAttributedString:[self createAttributedHeaderWithText:@"Privacy Statement"]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\nThis application does not collect or retain any personally identifiable data."]];
}

-(BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange{
    if([URL.absoluteString characterAtIndex:0] == 'h'){
        bool isLongPress = false;
        for (UIGestureRecognizer *recognizer in self->textView.gestureRecognizers) {
            if([recognizer isKindOfClass:[UILongPressGestureRecognizer class]]&&recognizer.state == UIGestureRecognizerStateBegan)
                isLongPress = true;
        }
        
        if(isLongPress){
            // Unsure if the URL should be displayed in the message or not -- it's too big to
            // display in the title, yet the menu looks incomplete and ambiguous without it
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:URL.absoluteString preferredStyle:UIAlertControllerStyleActionSheet];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Open in Safari" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                [[UIApplication sharedApplication]openURL:URL];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Copy URL" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                [UIPasteboard generalPasteboard].string = URL.absoluteString;
            }]];
            
            [self presentViewController:alert animated:true completion:nil];
        }
        else{
            // Should probably use better terminology than this for the title and message
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Open in Safari?" message:@"You will be redirected to your default browser" preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                [[UIApplication sharedApplication] openURL:URL];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            
            [self presentViewController:alert animated:true completion:nil];
        }
    }
    else{
        // Unless all of the code in the didFinishLaunchingWithOptions: method in AppDelegate.m is
        // commented out, executing this MFMailCompose code will result in a crash. Regardless of whether said code is
        // commented or not, this code will also produce a crash in a simulator, but will work on an actual device.
        
        //[self.navigationController.navigationBar setBackgroundColor:[UIColor redColor]]; // WORKS
        
        /*MFMailComposeViewController *composeViewController = [[MFMailComposeViewController alloc] init];
        //[[composeViewController navigationBar] setBackgroundColor:[UIColor blueColor]];
        [composeViewController setMailComposeDelegate:self];
        [composeViewController setToRecipients:@[@"calspeed@cpuc.ca.gov"]];
        [self presentViewController:composeViewController animated:true completion:nil];*/
        
        // To add a default body message to the email, add "&body=text here" to the end of the mailto string.
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"mailto:calspeed@cpuc.ca.gov?subject=CalSPEED iOS App" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    }
    return false;
}

/*-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    [self dismissViewControllerAnimated:true completion:nil];
}*/

-(NSMutableAttributedString *)createAttributedHeaderWithText:(NSString *)string{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
    
    [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Helvetica-Bold" size:20.0] range:NSMakeRange(0, [string length])];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [string length])];
    
    return attributedString;
}

-(NSMutableAttributedString *)createAttributedLinkWithString:(NSString *)string withLink:(NSString *)link{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
    
    [attributedString addAttribute:NSLinkAttributeName value:link range:NSMakeRange(0, [string length])];
    
    return attributedString;
}

-(NSMutableAttributedString *)createAttributedStringWithColor:(UIColor *)color withText:(NSString *)string toAppend:(NSString *)appendation{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
    
    [attributedString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, [string length])];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:appendation]];
    
    return attributedString;
}

@end
