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
#import "tabController.h"

@interface tabController ()
@end

@implementation tabController
- (void)viewWillLayoutSubviews
{
    /*
    int requiredHeight = 45;
    CGRect tabFrame = self.tabBar.frame;
    if (tabFrame.size.height != requiredHeight)
    {
        tabFrame.size.height = requiredHeight;
        tabFrame.origin.y = self.view.frame.size.height - requiredHeight;
        self.tabBar.frame = tabFrame;
    }
    */
    [super viewDidLayoutSubviews];
    [self.tabBar invalidateIntrinsicContentSize];
    [self.view layoutIfNeeded];

    
    /*[UITabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                            [UIColor whiteColor], UITextAttributeTextColor,
                                            [NSValue valueWithUIOffset:UIOffsetMake(0,0)], UITextAttributeTextShadowOffset,
                                            [UIFont fontWithName:@"Helvetica" size:18.0], UITextAttributeFont, nil]
                                  forState:UIControlStateNormal];*/
   // [[UITabBarItem appearance] setTitleTextAttributes:@{UITextAttributeFont:[UIFont boldSystemFontOfSize:255]} forState:UIControlStateNormal];
}

@end
