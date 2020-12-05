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

#import "VMScore.h"
#include "VMContainer.h"

extern struct video_metric VIDM;

@implementation VMScore

+(VMScore *)beginNewScore{
    VMScore *vmScore = [[VMScore alloc] init];
    vmScore.HDcount = vmScore.SDcount = vmScore.LScount = 0;
    vmScore.eastUpCount = vmScore.eastDownCount = vmScore.westUpCount = vmScore.westDownCount = 0;
    VIDM.phase = 0;
    VIDM.i1 = VIDM.i2 = VIDM.i3 = VIDM.i4 = VIDM.i5 = VIDM.i6 = VIDM.i7 = VIDM.i8 = 0;
    
    for(int i = 0; i < 32; i++) //this sets up the correct row to store time/speed for California
        VIDM.indicesW[i] = 0;
    for(int i = 0; i < 32; i++) //this sets up the correct row to store time/speed for Virginia
        VIDM.indicesE[i] = 0;
    for(int i = 0; i < 32; i++) //empty spots have a -1 to make searching for open spot easy
        VIDM.threadCA[i] = -1;
    for(int i = 0; i < 32; i++) //empty spots have a -1 to make searching for open spot easy
        VIDM.threadVA[i] = -1;
    for(int i = 0; i < 64; i++) // keep track of when download starts for each column
        VIDM.download_start_ind[i] = -1;
    
    for(int i = 0; i < 100; i++) // set everything in data/time 2d arrays to -1 (i.e. invalid values)
    {
        for(int j = 0; j < 64; j++)
            VIDM.data[i][j] = VIDM.time[i][j] = -1;
    }
    
    return vmScore;
}

-(void)setPhase:(int)new_phase
{
    VIDM.phase = new_phase;
}

-(void)setWestUpCount
{
   /* printf("--> setWestUpCount: %d %d %d %d\n",VIDM.i1, VIDM.i2,VIDM.i3,VIDM.i4); //debug to see results
    int minThread = MIN(MIN(MIN(VIDM.i1, VIDM.i2),VIDM.i3),VIDM.i4);//which thread had fewest results
    if(minThread > 10)                                              //if we saw more than 10, disregard
        minThread = 10;                                             //set min thread to 10
    //VIDM.i1 = VIDM.i2 = VIDM.i3 = VIDM.i4 = minThread;              //set all counters to 10
    _westUpCount = minThread;
    VIDM.westUpCount = minThread; */
}
-(void)setWestDownCount
{
    /* printf("--> setWestDownCount: %d %d %d %d\n",VIDM.i1, VIDM.i2,VIDM.i3,VIDM.i4); //debug to see results

    int minThread = MIN(MIN(MIN(VIDM.i1, VIDM.i2),VIDM.i3),VIDM.i4);
    if(minThread > (_westUpCount + 10))
        minThread = _westUpCount + 10;
    //VIDM.i1 = VIDM.i2 = VIDM.i3 = VIDM.i4 = minThread;
    _westDownCount = minThread;
    VIDM.westDownCount = minThread; */
    VIDM.phase = 1; //now moving to east
}
-(void)setEastUpCount
{
    /* printf("--> setEastUpCount: %d %d %d %d\n",VIDM.i5, VIDM.i6,VIDM.i7,VIDM.i8); //debug to see results

    int minThread = MIN(MIN(MIN(VIDM.i5, VIDM.i6),VIDM.i7),VIDM.i8);
    if(minThread > 10)
        minThread = 10;
    //VIDM.i5 = VIDM.i6 = VIDM.i7 = VIDM.i8 = minThread;
    _eastUpCount = minThread;
    VIDM.eastUpCount = minThread; */
}
-(void)setEastDownCount
{
   /* printf("--> setEastDownCount: %d %d %d %d\n",VIDM.i5, VIDM.i6,VIDM.i7,VIDM.i8); //debug to see results

    int minThread = MIN(MIN(MIN(VIDM.i5, VIDM.i6),VIDM.i7),VIDM.i8);
    if(minThread > (_eastUpCount + 10))
        minThread = _eastUpCount + 10;
    //VIDM.i5 = VIDM.i6 = VIDM.i7 = VIDM.i8 = minThread;
    _eastDownCount = minThread;
    VIDM.eastDownCount = minThread; */
    VIDM.phase = 0; //back west
}

-(NSString *)getStringRepresentation{
    int downHD, downSD, downLS, upHD, upSD, upLS;
    upHD = upSD = upLS = downHD = downSD = downLS = 0;
    
    //now let's see which thread was the min
    int minThread = 100;
    
    printf("There are %d west upload threads: ", VIDM.west_number_of_threads);
    for(int i = 0; i < VIDM.west_number_of_threads; i++) // check all valid threads in columns
    {
        if(VIDM.download_start_ind[i] < minThread)  // if we found a new minimum
            minThread = VIDM.download_start_ind[i]; // store this as the new minimum
        printf("%d ", VIDM.download_start_ind[i]);
    }
    printf("\n");
    
    //for loop to count all the values for upload in the array
    for(int i = 0; i < minThread; i++) // for our row.
    {
        int sum = 0;
        
        for(int j = 0; j < VIDM.west_number_of_threads; j++)
            sum += VIDM.data[i][j];
        
        if (sum > 2500)
            upHD++;
        else if (sum > 700)
            upSD++;
        else
            upLS++;
    }
    
    minThread = 100; //reset minThread to 100
    
    printf("There are %d west download threads: ", VIDM.west_number_of_threads);
    for(int i = 0; i < VIDM.west_number_of_threads; i++) //check all valid threads in columns
    {
        int count = 0; //start count at 0
        int j = VIDM.download_start_ind[i]; //find the start index for download for this column
        while(VIDM.time[j][i] != -1) // j, the time, and i, the column. -1 will be at end.
        {
            count++;
            j++;
        }
        if(count < minThread) //if we found a new minimum
            minThread = count; // store this as the new minimum
        printf("%d ", count);
    }
    printf("\n");
    
    int copy_down_start[64];
    memcpy(copy_down_start, VIDM.download_start_ind, sizeof(VIDM.download_start_ind));
    
    for(int i = 0; i < minThread; i++)
    {
        int sum = 0;
        for(int j = 0; j < VIDM.west_number_of_threads; j++)
        {
            sum += VIDM.data[copy_down_start[j]][j]; //add the data at the correct start download index
            copy_down_start[j]++; //make sure next time use the next download time
        }
        if (sum > 2500)
            downHD++;
        else if (sum > 700)
            downSD++;
        else
            downLS++;
    }

    _videoDetails =
        [NSString stringWithFormat:@"West [Down] HD: %d, SD: %d, LS: %d -- West [Up] HD: %d, SD: %d, LS : %d\n", downHD, downSD, downLS, upHD, upSD, upLS];
    
    upHD = upSD = upLS = downHD = downSD = downLS = 0;

    //now let's see which thread was the min
    int eastMinThreadUp  = 100;
    
    printf("There are %d east upload threads: ", VIDM.east_number_of_threads);
    for(int i = 32; i < (32 + VIDM.east_number_of_threads); i++) // check all valid threads in columns
    {
        if(VIDM.download_start_ind[i] < eastMinThreadUp)  // if we found a new minimum
            eastMinThreadUp = VIDM.download_start_ind[i]; // store this as the new minimum
        printf("%d ", VIDM.download_start_ind[i]);
    }
    printf("\n");
    
    //for loop to count all the values for upload in the array
    for(int i = 0; i < eastMinThreadUp; i++) // for our row.
    {
        int sum = 0;
        
        for(int j = 32; j < (32 + VIDM.east_number_of_threads); j++)
            sum += VIDM.data[i][j];
        
        if (sum > 2500)
            upHD++;
        else if (sum > 700)
            upSD++;
        else
            upLS++;
    }
    
    int eastMinThreadDown = 100;
    
    printf("There are %d east download threads: ", VIDM.east_number_of_threads);
    for(int i = 0; i < VIDM.west_number_of_threads; i++) //check all valid threads in columns
    {
        int count = 0; //start count at 0
        int j = VIDM.download_start_ind[i]; //find the start index for download for this column
        while(VIDM.time[j][i] != -1) // j, the time, and i, the column. -1 will be at end.
        {
            count++;
            j++;
        }
        if(count < eastMinThreadDown) //if we found a new minimum
            eastMinThreadDown = count; // store this as the new minimum
        printf("%d ", count);
    }
    printf("\n");

    for(int i = 0; i < eastMinThreadDown; i++)
    {
        int sum = 0;
        for(int j = 32; j < (32 + VIDM.east_number_of_threads); j++)
        {
            sum += VIDM.data[copy_down_start[j]][j]; //add the data at the correct start download index
            copy_down_start[j]++; //make sure next time use the next download time
        }
        if (sum > 2500)
            downHD++;
        else if (sum > 700)
            downSD++;
        else
            downLS++;
    }
    
    printf("West Data Summary:\n");
    for(int j = 0; j < 30; j ++)
    {
        for(int i = 0; i < VIDM.west_number_of_threads; i++)
        {
            printf("T: %d, S: %d |",  VIDM.time[j][i], VIDM.data[j][i]);
        }
        printf("\n");
    }
    printf("East Data Summary:\n");
    for(int j = 0; j < 30; j++)
    {
        for(int i = 32; i < VIDM.east_number_of_threads + 32; i++)
        {
            printf("T: %d, S: %d |", VIDM.time[j][i], VIDM.data[j][i]);
        }
        printf("\n");
    }
    
    for(int i = 0; i < 64; i++)
    {
        printf("%d ", VIDM.download_start_ind[i]);
    }
    printf("\n");

    _conferenceDetails =
        [NSString stringWithFormat:@"East [Down] HD: %d, SD: %d, LS: %d -- East [Up] HD: %d, SD: %d, LS : %d\n", downHD, downSD, downLS, upHD, upSD, upLS];
    
    return [_videoDetails stringByAppendingString:_conferenceDetails];
}

@end
