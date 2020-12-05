/*--------------------------------------------------------------- 
 * Copyright (c) 1999,2000,2001,2002,2003                              
 * The Board of Trustees of the University of Illinois            
 * All Rights Reserved.                                           
 *--------------------------------------------------------------- 
 * Permission is hereby granted, free of charge, to any person    
 * obtaining a copy of this software (Iperf) and associated       
 * documentation files (the "Software"), to deal in the Software  
 * without restriction, including without limitation the          
 * rights to use, copy, modify, merge, publish, distribute,        
 * sublicense, and/or sell copies of the Software, and to permit     
 * persons to whom the Software is furnished to do
 * so, subject to the following conditions: 
 *
 *     
 * Redistributions of source code must retain the above 
 * copyright notice, this list of conditions and 
 * the following disclaimers. 
 *
 *     
 * Redistributions in binary form must reproduce the above 
 * copyright notice, this list of conditions and the following 
 * disclaimers in the documentation and/or other materials 
 * provided with the distribution. 
 * 
 *     
 * Neither the names of the University of Illinois, NCSA, 
 * nor the names of its contributors may be used to endorse 
 * or promote products derived from this Software without
 * specific prior written permission. 
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
 * NONINFRINGEMENT. IN NO EVENT SHALL THE CONTIBUTORS OR COPYRIGHT 
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
 * ________________________________________________________________
 * National Laboratory for Applied Network Research 
 * National Center for Supercomputing Applications 
 * University of Illinois at Urbana-Champaign 
 * http://www.ncsa.uiuc.edu
 * ________________________________________________________________ 
 *
 * ReportDefault.c
 * by Kevin Gibbs <kgibbs@nlanr.net>
 *
 * ________________________________________________________________ */

#include "headers.h"
#include "Settings.hpp"
#include "util.h"
#include "Reporter.h"
#include "report_default.h"
#include "Thread.h"
#include "Locale.h"
#include "PerfSocket.hpp"
#include "SocketAddr.h"
#include <stdarg.h>
#include "VMContainer.h"

extern struct video_metric VIDM;
extern int probe_ary[10];
extern int reported_probe_speed;
#ifdef __cplusplus
extern "C" {
#endif

int tcp_count = 0;
int thread_count = 0;
int jitter_count = 0;
int tcp_speed = 0;
int thread_speed = 0;
int displayed_count = 0;

/*
 * Prints transfer reports in default style
 */
void reporter_printstats( Transfer_Info *stats )
{

    byte_snprintf( buffer, sizeof(buffer)/2, (double) stats->TotalLen,
                   toupper( stats->mFormat));
    byte_snprintf( &buffer[sizeof(buffer)/2], sizeof(buffer)/2,
                   stats->TotalLen / (stats->endTime - stats->startTime), 
                   stats->mFormat);
    
    if ( stats->mUDP != (char)kMode_Server )
    {
        int nt = stats->transferID;
        float f = stats->startTime;
        float f2 = stats->endTime;
        char *sr = buffer;
        char *sr2 = &buffer[sizeof(buffer)/2];
        ReportBWFormatToVC(nt,f,f2,sr,sr2);
        
        
        int current_thread_speed = atoi(&buffer[sizeof(buffer)/2]);
        
        thread_count++;
        
        
        //if the start time is 0, and the end time is close to the alloted 5 seconds
        if((stats->startTime) == 0.0 && (stats->endTime) >= 2.0)
        {
            //increment the number of times we've seen a thread finish
            tcp_count++;
            //print_to_console("\n^^DEBUG: speed: %i, tcp_count: %i\n", current_thread_speed,tcp_count);
            
            //correct for big number error. 99999998 is an arbitrary number
            if((current_thread_speed < 0) || (current_thread_speed > 99999998))
                current_thread_speed = 0;
            
            //keep a running sum of the speeds
            tcp_speed += current_thread_speed;
            //print_to_console("\n^^DEBUG: VIDM.phase: %i\n\n", VIDM.phase);
            if(VIDM.phase == -2) //probe test
            {
                char array[20];
                sprintf(array, " %d", tcp_speed);
                tcp_to_UI(array, tcp_count);
                //print_to_console("^^DEBUG: Final probe speed: \"%f\", \n", (float)tcp_speed / 1024);
                    
                tcp_speed = 0; //zero everything
                thread_speed = 0;
                thread_count = 0;
                displayed_count = 0;
                tcp_count = 0;
            }
            //denotes an upload or download portion has completed
            else if(VIDM.phase != -1 && VIDM.phase != -2 && tcp_count % ((VIDM.phase==0)?VIDM.west_number_of_threads:VIDM.east_number_of_threads) == 0){
                char array[20];
                sprintf(array, " %d", tcp_speed);
                tcp_to_UI(array, tcp_count);
                
                //print_to_console("\n^^DEBUG: VIDM Phase: %i, west: %i, east: %i, tcp_count: %i\n", VIDM.phase, VIDM.west_number_of_threads, VIDM.east_number_of_threads, tcp_count);
                //print_to_console("\n^^DEBUG: Final speed: \"%f\", \n", (float)tcp_speed / 1024);
                    
                tcp_speed = 0; //zero everything
                thread_speed = 0;
                thread_count = 0;
                displayed_count = 0;
            }
        }
        else //you're not dealing with a final thread summary
        {
            /*
            thread_speed += current_thread_speed;//add it to running count
            if(thread_count == 4) //you've seen 4 threads
            {
                displayed_count++;
                if(displayed_count < 6)
                {
                    //print_to_console("Current speed: \"%d\", \n", thread_speed / (6 - displayed_count)); //ramp up the speed
                    data_to_LoggingWrapper(thread_speed / (6 - displayed_count));
                    
                }
                else
                {
                    //print_to_console("Current speed: \"%d\", \n", thread_speed);
                    data_to_LoggingWrapper(thread_speed);
                    
                }
                thread_speed = 0; //zero it back out
                thread_count = 0;
            }
            */
            thread_speed += current_thread_speed;//add it to running count
            if(VIDM.phase != -1 && VIDM.phase != -2 && thread_count % ((VIDM.phase==0)?VIDM.west_number_of_threads:VIDM.east_number_of_threads) == 0) //you've seen correct number of threads
            {
                displayed_count++;
                if(displayed_count < 14) // 14 here is so first 14 of 20 seconds ramp up
                {
                    //print_to_console("Current speed: \"%d\", \n", thread_speed / (6 - displayed_count)); //ramp up the speed
                    data_to_LoggingWrapper(thread_speed / (displayed_count + (14 - displayed_count)));
                    
                }
                else
                {
                    //print_to_console("Current speed: \"%d\", \n", thread_speed);
                    data_to_LoggingWrapper(thread_speed / displayed_count);
                    
                }
            }
            
            
        }
        // TCP Reporting to console.
        print_to_console( report_bw_format, stats->transferID,
                stats->startTime, stats->endTime,
                buffer, &buffer[sizeof(buffer)/2] );
    }
    else
    {
        // UDP Reporting
        udp_result_to_LoggingWrapper(stats->jitter, (stats->cntError/stats->cntDatagrams)*100);
        print_to_console( report_bw_jitter_loss_format, stats->transferID,
                stats->startTime, stats->endTime,
                buffer, &buffer[sizeof(buffer)/2],
                stats->jitter*1000.0, stats->cntError, stats->cntDatagrams,
                (100.0 * stats->cntError) / stats->cntDatagrams );
        
        int nt = stats->transferID;
        float f = stats->startTime;
        float f2 = stats->endTime;
        char *sr = buffer;
        char *sr2 = &buffer[sizeof(buffer)/2];
        
        float j = stats->jitter*1000.0;
        int cE = stats->cntError;
        int cD = stats->cntDatagrams;
        
        float g = ((100.0 * stats->cntError) / stats->cntDatagrams );
        
        ReportUDPFormatToVC(nt,f,f2,sr,sr2,j,cE,cD,g);
        
        //sends jitter report to the UI
        jitter_to_UI(j,g);
        jitter_count++;
        tcp_count = 0; //hoping this zeroes out tcp_count after the jitter test
        
        if ( stats->cntOutofOrder > 0 )
        {
            print_to_console("Count is out of order");
            print_to_console( report_outoforder,
                    stats->transferID, stats->startTime, 
                    stats->endTime, stats->cntOutofOrder );
        }
    }
    
    if(stats != NULL)
    {
        // Jack: Changed the null check to a check for a value of zero -- integers, stored without pointers, can never be null, and are always initialied as zero -- to silence the invalid comparision warning
        if(stats->free != 0)
        if( stats->free == 1)
        {
            if(stats->mUDP == (char)kMode_Client )
            {
                print_to_console( report_datagrams, stats->transferID, stats->cntDatagrams );
                ReportDatagrams(stats->transferID, stats->cntDatagrams);
                if(stats->cntDatagrams == 0)
                    udp_err_to_UI(); //if no datagrams sent, no connection
            }
        }
    }
}


/*
 * Prints multiple transfer reports in default style
 */
void reporter_multistats( Transfer_Info *stats ) {

    byte_snprintf( buffer, sizeof(buffer)/2, (double) stats->TotalLen,
                   toupper( stats->mFormat));
    byte_snprintf( &buffer[sizeof(buffer)/2], sizeof(buffer)/2,
                   stats->TotalLen / (stats->endTime - stats->startTime), 
                   stats->mFormat);

    if ( stats->mUDP != (char)kMode_Server ) {
        // TCP Reporting
        print_to_console( report_sum_bw_format,
                stats->startTime, stats->endTime, 
                buffer, &buffer[sizeof(buffer)/2] );
        report_sum_bw_format_VC(stats->startTime, stats->endTime,
                                buffer, &buffer[sizeof(buffer)/2] );//sends to VC to print to file
        
        if(stats->startTime == 0 && stats->endTime < 0.1) tcp_err_to_UI(); //no connection

    } else {
        // UDP Reporting
        print_to_console( report_sum_bw_jitter_loss_format,
                stats->startTime, stats->endTime, 
                buffer, &buffer[sizeof(buffer)/2],
                stats->jitter*1000.0, stats->cntError, stats->cntDatagrams,
                (100.0 * stats->cntError) / stats->cntDatagrams );
        report_sum_bw_jitter_loss_format_VC(stats->startTime, stats->endTime,
                                            buffer, &buffer[sizeof(buffer)/2],
                                            stats->jitter*1000.0, stats->cntError, stats->cntDatagrams,
                                            (100.0 * stats->cntError) / stats->cntDatagrams );
        
        if ( stats->cntOutofOrder > 0 ) {
            print_to_console( report_sum_outoforder,
                    stats->startTime, 
                    stats->endTime, stats->cntOutofOrder );
            report_sum_outoforder_VC(stats->startTime,
                                     stats->endTime, stats->cntOutofOrder );
        }
    }
    if ( stats->free == 1 && stats->mUDP == (char)kMode_Client )
    {
        print_to_console( report_sum_datagrams, stats->cntDatagrams );
        //print_to_console("^ UDP");
        report_sum_datagrams_VC(stats->cntDatagrams);
    }
}

/*
 * Prints server transfer reports in default style
 */
void reporter_serverstats( Connection_Info *nused, Transfer_Info *stats ) {
    print_to_console( server_reporting, stats->transferID );
    reporter_printstats( stats );
    
    //ReportServerReport(stats->transferID);
}

/*
 * Report the client or listener Settings in default style
 */
void reporter_reportsettings( ReporterData *data ) {
    int win, win_requested;

    win = getsock_tcp_windowsize( data->info.transferID,
                  (data->mThreadMode == kMode_Listener ? 0 : 1) );
    win_requested = data->mTCPWin;

    print_to_console("%s", seperator_line );
    ReportGeneral("\n------------------------------------------------------------\n");
    if ( data->mThreadMode == kMode_Listener ) {
        print_to_console( server_port,
                (isUDP( data ) ? "UDP" : "TCP"), 
                data->mPort );
        server_port_VC((isUDP( data ) ? "UDP" : "TCP"),
                data->mPort );
    } else {
        print_to_console( client_port,
                data->mHost,
                (isUDP( data ) ? "UDP" : "TCP"),
                data->mPort );
        client_port_VC(data->mHost,
                       (isUDP( data ) ? "UDP" : "TCP"),
                       data->mPort );
    }
    if ( data->mLocalhost != NULL ) {
        print_to_console( bind_address, data->mLocalhost );
        bind_address_VC(data->mLocalhost );
        if ( SockAddr_isMulticast( &data->connection.local ) ) {
            print_to_console( join_multicast, data->mLocalhost );
            join_multicast_VC(data->mLocalhost );
        }
    }

    if ( isUDP( data ) ) {
        print_to_console( (data->mThreadMode == kMode_Listener ? 
                                   server_datagram_size : client_datagram_size),
                data->mBufLen );
        data->mThreadMode == kMode_Listener ? server_datagram_size_VC(data->mBufLen) : client_datagram_size_VC(data->mBufLen);
        
        if ( SockAddr_isMulticast( &data->connection.peer ) ) {
            print_to_console( multicast_ttl, data->info.mTTL);
            multicast_ttl_VC(data->info.mTTL);
        }
    }
    byte_snprintf( buffer, sizeof(buffer), win,
                   toupper( data->info.mFormat));
    print_to_console( "%s: %s", (isUDP( data ) ? 
                                udp_buffer_size : tcp_window_size), buffer );
    isUDP( data ) ? udp_buffer_size_VC(buffer) : tcp_window_size_VC(buffer);

    if ( win_requested == 0 ) {
        print_to_console( " %s", window_default );
        ReportGeneral("(default)");
        
    } else if ( win != win_requested ) {
        byte_snprintf( buffer, sizeof(buffer), win_requested,
                       toupper( data->info.mFormat));
        print_to_console( warn_window_requested, buffer );
        warn_window_requested_VC((buffer));
    }
    print_to_console( "\n" );
    print_to_console("%s", seperator_line );
    ReportGeneral("\n------------------------------------------------------------\n");
}

/*
 * Report a socket's peer IP address in default style
 */
void *reporter_reportpeer( Connection_Info *stats, int ID ) {
    if ( ID > 0 ) {
        // copy the inet_ntop into temp buffers, to avoid overwriting
        char local_addr[ REPORT_ADDRLEN ];
        char remote_addr[ REPORT_ADDRLEN ];
        struct sockaddr *local = ((struct sockaddr*)&stats->local);
        struct sockaddr *peer = ((struct sockaddr*)&stats->peer);
    
        if ( local->sa_family == AF_INET ) {
            inet_ntop( AF_INET, &((struct sockaddr_in*)local)->sin_addr, 
                       local_addr, REPORT_ADDRLEN);
        }
#ifdef HAVE_IPV6
          else {
            inet_ntop( AF_INET6, &((struct sockaddr_in6*)local)->sin6_addr, 
                       local_addr, REPORT_ADDRLEN);
        }
#endif
    
        if ( peer->sa_family == AF_INET ) {
            inet_ntop( AF_INET, &((struct sockaddr_in*)peer)->sin_addr, 
                       remote_addr, REPORT_ADDRLEN);
        }
#ifdef HAVE_IPV6
          else {
            inet_ntop( AF_INET6, &((struct sockaddr_in6*)peer)->sin6_addr, 
                       remote_addr, REPORT_ADDRLEN);
        }
#endif
        
        int n2 =( local->sa_family == AF_INET ?
                 ntohs(((struct sockaddr_in*)local)->sin_port) :
#ifdef HAVE_IPV6
                 ntohs(((struct sockaddr_in6*)local)->sin6_port));
#else
        0);
#endif
        //Alex Hauser: System to print iPerf reports to ViewController UI
        int n3 = ( peer->sa_family == AF_INET ?
                  ntohs(((struct sockaddr_in*)peer)->sin_port) :
#ifdef HAVE_IPV6
                  ntohs(((struct sockaddr_in6*)peer)->sin6_port));
#else
        0);
#endif
        
        
        ReportPeerToVC(ID, "127.0.0.1",n2,"127.0.0.1",n3);// "[%3d] local %s port %u connected with %s port %u\n";
        
        print_to_console( report_peer,
                ID,
                // local_addr,  ( local->sa_family == AF_INET ?    // CalSPEED: change the local IP address to a meaningless value.
                "127.0.0.1",  ( local->sa_family == AF_INET ?
                              ntohs(((struct sockaddr_in*)local)->sin_port) :
#ifdef HAVE_IPV6
                              ntohs(((struct sockaddr_in6*)local)->sin6_port)),
#else
                              0),
#endif
                // remote_addr, ( peer->sa_family == AF_INET ?    // CalSPEED: change the remote IP address to a meaningless value.
                "127.0.0.1", ( peer->sa_family == AF_INET ?
                              ntohs(((struct sockaddr_in*)peer)->sin_port) :
#ifdef HAVE_IPV6
                              ntohs(((struct sockaddr_in6*)peer)->sin6_port)));
#else
                              0));
#endif
    }
    return NULL;
}
// end ReportPeer

/* -------------------------------------------------------------------
 * Report the MSS and MTU, given the MSS (or a guess thereof)
 * ------------------------------------------------------------------- */

// compare the MSS against the (MTU - 40) to (MTU - 80) bytes.
// 40 byte IP header and somewhat arbitrarily, 40 more bytes of IP options.

#define checkMSS_MTU( inMSS, inMTU ) (inMTU-40) >= inMSS  &&  inMSS >= (inMTU-80)

void reporter_reportMSS( int inMSS, thread_Settings *inSettings ) {
    if ( inMSS <= 0 ) {
        print_to_console( report_mss_unsupported, inSettings->mSock );
    } else {
        char* net;
        int mtu = 0;

        if ( checkMSS_MTU( inMSS, 1500 ) ) {
            net = "ethernet";
            mtu = 1500;
        } else if ( checkMSS_MTU( inMSS, 4352 ) ) {
            net = "FDDI";
            mtu = 4352;
        } else if ( checkMSS_MTU( inMSS, 9180 ) ) {
            net = "ATM";
            mtu = 9180;
        } else if ( checkMSS_MTU( inMSS, 65280 ) ) {
            net = "HIPPI";
            mtu = 65280;
        } else if ( checkMSS_MTU( inMSS, 576 ) ) {
            net = "minimum";
            mtu = 576;
            print_to_console("%s", warn_no_pathmtu );
        } else {
            mtu = inMSS + 40;
            net = "unknown interface";
        }

        print_to_console( report_mss,
                inSettings->mSock, inMSS, mtu, net );
    }
}
// end ReportMSS

#ifdef __cplusplus
} /* end extern "C" */
#endif
