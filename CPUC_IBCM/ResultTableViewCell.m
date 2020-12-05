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

#import "ResultTableViewCell.h"

@implementation ResultTableViewCell

-(void)didMoveToSuperview{
    float blockWidth = (self.viewForBaselineLayout.bounds.size.width-32)/5;//-32
    //printf("First blockWidth: %f\n", blockWidth);
    // ^ We subtract 50 pixels because of the 8 pixels on the very left of the left table cell margin,
    // and because of the 42 pixels that the disclosure indicator on the far right takes up.
    // Edit: Is now 32, looks better than 50. The extra space is taken up to the right.
    for(UIView *blockView in propertyBlockViewCollection){
        blockView.backgroundColor = [UIColor clearColor];
        CGRect frame = blockView.frame;
        float blockWidthToSet = blockWidth;
        if(blockView == propertyBlockViewCollection[0]){
            blockWidthToSet += 16;
            blockWidth = (self.viewForBaselineLayout.bounds.size.width-48)/5;
            //printf("Second blockWidth: %f\n", blockWidth);
        }
        blockView.frame = CGRectMake(frame.origin.x, frame.origin.y, blockWidthToSet, frame.size.height);
        blockView.translatesAutoresizingMaskIntoConstraints = false;
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:blockView
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1
                                                                      constant:blockWidthToSet]];
    }
}

@end
