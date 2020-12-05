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

#import "AppDelegate.h"
#import "CoreDataManager.h"

@implementation AppDelegate

static UIColor *tintColor, *containedTintColor;

/*+(UIColor *)getTintColor{
    return tintColor;
}

+(UIColor *)getContainedTintColor{
    return containedTintColor;
}*/

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //CGColorGetComponents([UINavigationBar appearance].tintColor.CGColor)
    //CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha =0.0;
    //[[UINavigationBar appearance].tintColor getRed:&red green:&green blue:&blue alpha:&alpha];
    //NSLog(@"red: %f, green: %f, blue: %f, alpha: %f", red, green, blue, alpha);
    
    //tintColor = [UINavigationBar appearance].tintColor;
    //containedTintColor = [UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil].tintColor;
    
    // Override point for customization after application launch.
    [[UINavigationBar appearance] setShadowImage:[[UIImage alloc] init]]; // GOOD
    
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"gradientNavBarImage.png"]]]; // BAD
    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil] setTintColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"Top_Bar_Color.png"]]]; // BAD
    [[UINavigationBar appearance] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"Top_Bar_Color.png"]]]; // BAD
    
    /*[[UIBarButtonItem appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor colorWithPatternImage:[UIImage imageNamed:@"gradientNavBarImage.png"]], UITextAttributeTextColor, // BAD
      [UIFont fontWithName:@"Hiragino Kaku Gothic ProN W3" size:16.0f], UITextAttributeFont, // GOOD
      [UIColor darkGrayColor], UITextAttributeTextShadowColor, // GOOD
      [NSValue valueWithCGSize:CGSizeMake(0.0, 0.0)], UITextAttributeTextShadowOffset, // GOOD
      nil] forState:UIControlStateNormal];*/
    NSShadow *shadow = [NSShadow new];
    [shadow setShadowColor: [UIColor darkGrayColor]];
    [shadow setShadowOffset: CGSizeMake(0.0f, 0.0f)];
    [[UIBarButtonItem appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
     [UIColor colorWithPatternImage:[UIImage imageNamed:@"gradientNavBarImage.png"]], NSForegroundColorAttributeName, // BAD
     [UIFont fontWithName:@"Hiragino Kaku Gothic ProN W3" size:16.0f], NSFontAttributeName, // GOOD
     shadow, NSShadowAttributeName,
     nil] forState:UIControlStateNormal];
    
    /*[[UINavigationBar appearance].tintColor getRed:&red green:&green blue:&blue alpha:&alpha];
    NSLog(@"red: %f, green: %f, blue: %f, alpha: %f", red, green, blue, alpha);*/
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    //NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if(![[[NSUserDefaults standardUserDefaults] stringForKey:@"softwareAgreementVersion"] isEqualToString:@"agreed"]){
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"End User Agreement" message:@"Have you read and agree to our terms and conditions?" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Yes, I agree" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
            [[NSUserDefaults standardUserDefaults] setValue:@"agreed" forKey:@"softwareAgreementVersion"];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Read" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.cpuc.ca.gov/General.aspx?id=1778"]];
        }]];
        
        if(self.window.subviews.count < 2)
        [(UIViewController*)self.window.rootViewController showViewController:alert sender:self];
    }

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[CoreDataManager getSharedCoreDataManager] saveContext];
}

@end
