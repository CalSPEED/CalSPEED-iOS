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

#ifndef VMContainer_h
#define VMContainer_h

#include <stdio.h>

struct video_metric{
    int i1, i2, i3, i4, i5, i6, i7, i8; // index for different threads (4 upload and 4 download)
    int indicesW[32]; //indeces for different threads (32 west, 32 east)
    int indicesE[32]; //indeces for different threads (32 west, 32 east)
    int data[100][64]; // holds all the speeds in a row (half up, second half down) (100 choosen arbitrarily)
    int time[100][64]; // holds all the time in a row (half up, second half down)
    int threadCA[32];  // maps an index to a thread (32 threads max)
    int threadVA[32];  // maps an index to a thread (32 threads max)
    int phase;         // 0 is west, and 1 is east
    int download_start_ind[64];
    int number_of_threads, west_number_of_threads, east_number_of_threads;
    int westUpCount, westDownCount, eastUpCount, eastDownCount;
    
};

extern struct video_metric VIDM;


#endif /* VMContainer_h */
