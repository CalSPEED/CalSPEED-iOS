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
 * Settings.cpp
 * by Mark Gates <mgates@nlanr.net>
 * & Ajay Tirumala <tirumala@ncsa.uiuc.edu>
 * -------------------------------------------------------------------
 * Stores and parses the initial values for all the global variables.
 * -------------------------------------------------------------------
 * headers
 * uses
 *   <stdlib.h>
 *   <stdio.h>
 *   <string.h>
 *
 *   <unistd.h>
 * ------------------------------------------------------------------- */

#define HEADERS()

#include "headers.h"

#include "Settings.hpp"
#include "Locale.h"
#include "SocketAddr.h"

#include "util.h"
#include "getopt.h"

#include "gnu_getopt.h"

#include "LoggingWrapper.h"
#include "TestWrapper.h"
//#include "CInterface.h"
#import <Foundation/Foundation.h>

#define SAME_TCP

// Byun: Add two definitions
// Jack: Added undef to silence macro redfinition warning
#undef HAVE_THREAD

#define HAVE_THREAD
#define HAVE_POSIX_THREAD

void Settings_Interpret( char option, const char *optarg, thread_Settings *mExtSettings );

char ipAddress[25];
char numberOfTests[5];
char intervals[5];
char windowSize[5];

//Alex Hauser: added to fascillitate multithreading option
char threadNumber[5] = {'4'};

//Alex Hauser: added to fascillitate custom port number option
char portNumber[5];

int reportCount = 0;

int uDPorTCP;

/* -------------------------------------------------------------------
 * command line options
 *
 * The option struct essentially maps a long option name (--foobar)
 * or environment variable ($FOOBAR) to its short option char (f).
 * ------------------------------------------------------------------- */
#define LONG_OPTIONS()

// Jack: Commented out unused struct "long_options", to silence the unused variable warning
/*const struct option long_options[] =
{
{"singleclient",     no_argument, NULL, '1'},
{"bandwidth",  required_argument, NULL, 'b'},
{"client",     required_argument, NULL, 'c'},
{"dualtest",         no_argument, NULL, 'd'},
{"format",     required_argument, NULL, 'f'},
{"help",             no_argument, NULL, 'h'},
{"interval",   required_argument, NULL, 'i'},
{"len",        required_argument, NULL, 'l'},
{"print_mss",        no_argument, NULL, 'm'},
{"num",        required_argument, NULL, 'n'},
{"output",     required_argument, NULL, 'o'},
{"port",       required_argument, NULL, 'p'},
{"tradeoff",         no_argument, NULL, 'r'},
{"server",           no_argument, NULL, 's'},
{"time",       required_argument, NULL, 't'},
{"udp",              no_argument, NULL, 'u'},
{"version",          no_argument, NULL, 'v'},
{"window",     required_argument, NULL, 'w'},
{"reportexclude", required_argument, NULL, 'x'},
{"reportstyle",required_argument, NULL, 'y'},

// more esoteric options
{"bind",       required_argument, NULL, 'B'},
{"compatibility",    no_argument, NULL, 'C'},
{"daemon",           no_argument, NULL, 'D'},
{"file_input", required_argument, NULL, 'F'},
{"stdin_input",      no_argument, NULL, 'I'},
{"mss",        required_argument, NULL, 'M'},
{"nodelay",          no_argument, NULL, 'N'},
{"listenport", required_argument, NULL, 'L'},
{"parallel",   required_argument, NULL, 'P'},
{"remove",           no_argument, NULL, 'R'},
{"tos",        required_argument, NULL, 'S'},
{"ttl",        required_argument, NULL, 'T'},
{"single_udp",       no_argument, NULL, 'U'},
{"ipv6_domian",      no_argument, NULL, 'V'},
{"suggest_win_size", no_argument, NULL, 'W'},
{0, 0, 0, 0}
};*/

#define ENV_OPTIONS()

const struct option env_options[] =
{
{"IPERF_SINGLECLIENT",     no_argument, NULL, '1'},
{"IPERF_BANDWIDTH",  required_argument, NULL, 'b'},
{"IPERF_CLIENT",     required_argument, NULL, 'c'},
{"IPERF_DUALTEST",         no_argument, NULL, 'd'},
{"IPERF_FORMAT",     required_argument, NULL, 'f'},
// skip help
{"IPERF_INTERVAL",   required_argument, NULL, 'i'},
{"IPERF_LEN",        required_argument, NULL, 'l'},
{"IPERF_PRINT_MSS",        no_argument, NULL, 'm'},
{"IPERF_NUM",        required_argument, NULL, 'n'},
{"IPERF_PORT",       required_argument, NULL, 'p'},
{"IPERF_TRADEOFF",         no_argument, NULL, 'r'},
{"IPERF_SERVER",           no_argument, NULL, 's'},
{"IPERF_TIME",       required_argument, NULL, 't'},
{"IPERF_UDP",              no_argument, NULL, 'u'},
// skip version
{"TCP_WINDOW_SIZE",  required_argument, NULL, 'w'},
{"IPERF_REPORTEXCLUDE", required_argument, NULL, 'x'},
{"IPERF_REPORTSTYLE",required_argument, NULL, 'y'},

// more esoteric options
{"IPERF_BIND",       required_argument, NULL, 'B'},
{"IPERF_COMPAT",           no_argument, NULL, 'C'},
{"IPERF_DAEMON",           no_argument, NULL, 'D'},
{"IPERF_FILE_INPUT", required_argument, NULL, 'F'},
{"IPERF_STDIN_INPUT",      no_argument, NULL, 'I'},
{"IPERF_MSS",        required_argument, NULL, 'M'},
{"IPERF_NODELAY",          no_argument, NULL, 'N'},
{"IPERF_LISTENPORT", required_argument, NULL, 'L'},
{"IPERF_PARALLEL",   required_argument, NULL, 'P'},
{"IPERF_TOS",        required_argument, NULL, 'S'},
{"IPERF_TTL",        required_argument, NULL, 'T'},
{"IPERF_SINGLE_UDP",       no_argument, NULL, 'U'},
{"IPERF_IPV6_DOMAIN",      no_argument, NULL, 'V'},
{"IPERF_SUGGEST_WIN_SIZE", required_argument, NULL, 'W'},
{0, 0, 0, 0}
};

#define SHORT_OPTIONS()

#ifdef SAME_TCP
// Jack: Commented out unused variable "short_options", to silence the unused variable warning
//const char short_options[] = "1b:c:def:hi:l:mn:o:p:rst:uvw:x:y:B:CDF:IL:M:NP:RS:T:UVW";
#else
const char short_options[] = "1b:c:df:hi:l:mn:o:p:rst:uvw:x:y:B:CDF:IL:M:NP:RS:T:UVW";
#endif

/* -------------------------------------------------------------------
 * defaults
 * ------------------------------------------------------------------- */
#define DEFAULTS()

const long kDefault_UDPRate = 1024 * 1024; // -u  if set, 1 Mbit/sec
const int  kDefault_UDPBufLen = 1470;      // -u  if set, read/write 1470 bytes
// 1470 bytes is small enough to be sending one packet per datagram on ethernet

// 1450 bytes is small enough to be sending one packet per datagram on ethernet
//  **** with IPv6 ****

void print_to_console(const char *format, ...){
    if(logToConsole){
        va_list argptr;
        va_start(argptr, format);
        vfprintf(stderr, format, argptr);
        va_end(argptr);
    }
}

void ReportGeneral(char *str)
{
    NSString *s = [NSString stringWithFormat:@"%s",str];
    [LoggingWrapper newReport:s];
}

void ReportPeerToVC(int n, char *str,int n2, char *str2, int n3)
{
    NSString *s;
    // "[%3d] local %s port %u connected with %s port %u\n";
    s = [NSString stringWithFormat:@"[%3d] local %s port %d connected with %s port %d\n",n,str,n2,str2,n3];
     [LoggingWrapper newReport:s];
    
    
}


void ReportDatagrams(int n, int d)
{
    NSString *s;
    
    // s = [NSString stringWithFormat:@"[%d] %4.1f-%4.1f sec %s %s/sec\n",n,f,f2,str2,str2];
    // s = [NSString stringWithFormat:@"[%3d] %4.1f-%4.1f sec  %s  %s/sec  %5.3f ms %4d/%5d (%.2g%%)\n",n,f,f2,str2,str2];
    
    s = [NSString stringWithFormat:@"[%3d] Sent %d datagrams\n[%3d] Server Report:\n",n, d, n];
    
    
    // s = [NSString stringWithFormat:@"\t%4.1f-%4.1f sec                 %s\n",f,f2,str];
    
    // if(reportCount%2 == 0)
    // {
    [LoggingWrapper newReport:s];
    
}

void ReportServerReport(int n)
{
    NSString *s;
    
    // s = [NSString stringWithFormat:@"[%d] %4.1f-%4.1f sec %s %s/sec\n",n,f,f2,str2,str2];
    // s = [NSString stringWithFormat:@"[%3d] %4.1f-%4.1f sec  %s  %s/sec  %5.3f ms %4d/%5d (%.2g%%)\n",n,f,f2,str2,str2];
    
    s = [NSString stringWithFormat:@"[%3d] End Server Report\n",n];
    
    
    
    // s = [NSString stringWithFormat:@"\t%4.1f-%4.1f sec                 %s\n",f,f2,str];
    
    // if(reportCount%2 == 0)
    // {
    [LoggingWrapper newReport:s];
    
}

void ReportUDPFormatToVC(int n,float f,float f2, char *str, char *str2, float j, int cE, int cD, float g)
{
    NSString *s;

   // s = [NSString stringWithFormat:@"[%d] %4.1f-%4.1f sec %s %s/sec\n",n,f,f2,str2,str2];
   // s = [NSString stringWithFormat:@"[%3d] %4.1f-%4.1f sec  %s  %s/sec  %5.3f ms %4d/%5d (%.2g%%)\n",n,f,f2,str2,str2];
    
    
    s = [NSString stringWithFormat:@"[%3d] %4.1f-%4.1f sec  %ss  %ss/sec  %5.3f ms %4d/%5d (%.2g%%)\n",n,f,f2,str,str2,j,cE,cD,g];
    
    // s = [NSString stringWithFormat:@"\t%4.1f-%4.1f sec                 %s\n",f,f2,str];
    
    // if(reportCount%2 == 0)
    // {
    [LoggingWrapper newReport:s];
    //}
    //else
    //{
    //    [viewController newReport2:s];
    //}
    reportCount++;
}

void ReportBWFormatToVC(int n,float f,float f2, char *str, char *str2)
{
    //const char report_bw_format[] =
    //"[%3d] %4.1f-%4.1f sec  %ss  %ss/sec\n";
    
    NSString *s;
    // "[%3d] local %s port %u connected with %s port %u\n";
    s = [NSString stringWithFormat:@"[%3d] %4.1f-%4.1f sec %ss %ss/sec\n",n,f,f2,str,str2];
    
    
   // s = [NSString stringWithFormat:@"\t%4.1f-%4.1f sec                 %s\n",f,f2,str];
    
   // if(reportCount%2 == 0)
   // {
        [LoggingWrapper newReport:s];
    //}
    //else
    //{
    //    [viewController newReport2:s];
    //}
    reportCount++;
}

void jitter_to_UI(float jit, float rate)
{
    NSString *s, *s2;
    s = [NSString stringWithFormat:@"   Jitter = %5.2f ms, Loss = %4.1f%%",jit, rate ];
    s2 = [NSString stringWithFormat:@"Jitter = %5.2f ms, Loss = %4.1f%%",jit, rate ];
    
    //[viewController replaceLastCell:s2];
}

void udp_err_to_UI() {
    //[viewController replaceLastCell:@"UDP Test Failed"];
}

void tcp_err_to_UI() {
    //[viewController replaceLastCell:@"TCP Test Failed"];
}

void tcp_to_UI(char *rate, int tcp_count){
    int numOfThreads = [[NSString stringWithFormat:@"%s", threadNumber] intValue]; //how many threads
    int count = tcp_count / numOfThreads;
    NSString *speed = [NSString stringWithFormat:@"%s Kb/s",rate];
    int resultSpeed = atoi(rate);
    if(!resultSpeed) speed = [NSString stringWithFormat:@"n/a"]; //if rate is zero, then print n/a instead of 0 kb/s
    [LoggingWrapper reportTestResult:resultSpeed withCount:count];
}

void data_to_LoggingWrapper(int data){
    [LoggingWrapper reportTestData:data];
}

void udp_result_to_LoggingWrapper(double result, double packet_loss){
    [LoggingWrapper reportUDPResult:result withPacketLoss:packet_loss];
}

void report_timeout_to_LoggingWrapper(){
    [LoggingWrapper reportTimeout];
}

void report_sum_bw_format_VC(float f, float f2, char *sr, char *sr2)
{
    NSString *s;
    s = [NSString stringWithFormat:@"[SUM] %4.1f-%4.1f sec  %ss  %ss/sec\n",f, f2, sr, sr2];
    [LoggingWrapper newReport:s];
}

void report_sum_outoforder_VC(float f, float f2, int n)
{
    NSString *s;
    s = [NSString stringWithFormat:@"[SUM] %4.1f-%4.1f sec  %d datagrams received out-of-order\n",f, f2, n];
         [LoggingWrapper newReport:s];
}

void report_sum_bw_jitter_loss_format_VC(float f, float f2, char *str, char *str2, float j, int cE, int cD, float g)
{
    NSString *s;
    s = [NSString stringWithFormat:@"[SUM] %4.1f-%4.1f sec  %ss  %ss/sec  %5.3f ms %4d/%5d (%.2g%%)\n",f,f2,str,str2,j,cE,cD,g];
    [LoggingWrapper newReport:s];
}

void report_sum_datagrams_VC(int n)
{
    NSString *s;
    s = [NSString stringWithFormat:@"[SUM] Sent %d datagrams\n", n];
    [LoggingWrapper newReport:s];
}

/* -------------------------------------------------------------------
 * SETTINGS SENT TO VC
 * ------------------------------------------------------------------- */
void server_port_VC(char *str, int n)
{
    NSString *s;
    s = [NSString stringWithFormat:@"Server listening on %s port %d\n", str, n];
    [LoggingWrapper newReport:s];
}


void client_port_VC(char *str, char *str2, int n)
{
    NSString *s;
    s = [NSString stringWithFormat:@"Client connecting to %s, %s port %d\n", str, str2, n];
    [LoggingWrapper newReport:s];
}

void bind_address_VC(char *str)
{
    NSString *s;
    s = [NSString stringWithFormat:@"Binding to local address %s\n", str];
    [LoggingWrapper newReport:s];
}

void join_multicast_VC(char *str)
{
    NSString *s;
    s = [NSString stringWithFormat:@"Joining multicast group  %s\n", str];
    [LoggingWrapper newReport:s];
}

void server_datagram_size_VC(int n)
{
    NSString *s;
    s = [NSString stringWithFormat:@"Receiving %d byte datagrams\n", n];
    [LoggingWrapper newReport:s];
}

void client_datagram_size_VC(int n)
{
    NSString *s;
    s = [NSString stringWithFormat:@"Sending %d byte datagrams\n", n];
    [LoggingWrapper newReport:s];
}

void multicast_ttl_VC(int n)
{
    NSString *s;
    s = [NSString stringWithFormat:@"Setting multicast TTL to %d\n", n];
    [LoggingWrapper newReport:s];
}

void udp_buffer_size_VC(char *str)
{
    NSString *s;
    s = [NSString stringWithFormat:@"UDP buffer size:   %s ", str];
    [LoggingWrapper newReport:s];
}


//Byun: v0_9_6
// Jack: Declared the string arguments as constant, to silence the warnings it caused when given constant strings when it gets called in the "error.c" class
void warn_errno_VC(const char *inMessage, const char *my_str)
{
    NSString *s;
    s = [NSString stringWithFormat:@"\n%s failed: %s\n", inMessage, my_str];
    [LoggingWrapper newReport:s];
}


//Byun: v0_9_6
void warn_UDP_ack_VC(int mSock, int count)
{
    NSString *s;
    s = [NSString stringWithFormat:@"[%3d] WARNING: did not receive ack of last datagram after %d tries.\n", mSock, count];
    [LoggingWrapper newReport:s];
}



void tcp_window_size_VC(char *str)
{
    NSString *s;
    s = [NSString stringWithFormat:@"TCP window size %s", str];
    [LoggingWrapper newReport:s];
}

void warn_window_requested_VC(char *str)
{
    NSString *s;
    s = [NSString stringWithFormat:@" (WARNING: requested %s)",str];
    [LoggingWrapper newReport:s];
}

/* -------------------------------------------------------------------
 * Initialize all settings to defaults.
 * ------------------------------------------------------------------- */

void Settings_Initialize( thread_Settings *main ) {
    // Everything defaults to zero or NULL with
    // this memset. Only need to set non-zero values
    // below.
    memset( main, 0, sizeof(thread_Settings) );
    main->mSock = INVALID_SOCKET;
    main->mReportMode = kReport_Default;
    // option, defaults
    main->flags         = FLAG_MODETIME | FLAG_STDOUT; // Default time and stdout

    if(uDPorTCP == 0)
        main->mUDPRate      = 0;           // -b,  ie. TCP mode
    
    //main->mHost         = NULL;        // -c,  none, required for client
    main->mMode         = kTest_Normal;  // -d,  mMode == kTest_DualTest
    //main->mMode         = kTest_DualTest;
    main->mFormat       = 'a';           // -f,  adaptive bits
    // skip help                         // -h,
    ///main->mBufLenSet  = false;         // -l,
    main->mBufLen       = 8 * 1024;      // -l,  8 Kbyte
    
    // Byun: Set the interval to 1 sec.
    main->mInterval     = 10;           // -i,  ie. no periodic bw reports
    //main->mPrintMSS   = false;         // -m,  don't print MSS
    // mAmount is time also              // -n,  N/A
    //main->mOutputFileName = NULL;      // -o,  filename
    main->mPort         = 5001;          // -p,  ttcp port
    // main->mMode    = kTest_TradeOff;          // -r,  mMode == kTest_TradeOff
    main->mThreadMode   = kMode_Client; // -s,  or -c, none
    //main->mThreadMode   = kMode_Reporter;
    main->mAmount       = 1000;          // -t,  10 seconds
    
    if(uDPorTCP == 1)
    {
        main->mUDPRate = 10;
        
    }
    
    // mUDPRate > 0 means UDP            // -u,  N/A, see kDefault_UDPRate
    // skip version                      // -v,
    //main->mTCPWin       = 0;           // -w,  ie. don't set window

    // more esoteric options
    //main->mLocalhost    = NULL;        // -B,  none
    //main->mCompat     = false;         // -C,  run in Compatibility mode
    //main->mDaemon     = false;         // -D,  run as a daemon
    //main->mFileInput  = false;         // -F,
    //main->mFileName     = NULL;        // -F,  filename 
    //main->mStdin      = false;         // -I,  default not stdin
    //main->mListenPort   = 0;           // -L,  listen port
    //main->mMSS          = 0;           // -M,  ie. don't set MSS
   // main->mNodelay    = false;         // -N,  don't set nodelay
    //main->mThreads      = 0;           // -P,
    //main->mRemoveService = false;      // -R,
    //main->mTOS          = 0;           // -S,  ie. don't set type of service
    main->mTTL          = 1;             // -T,  link-local TTL
    //main->mDomain     = kMode_IPv4;    // -V,
    //main->mSuggestWin = false;         // -W,  Suggest the window size.

} // end Settings


//returns version of iPerf FS
const char* getVersion(){
    return version;
}

//sets settings from ViewController FS
void setSettings(const char *ip, const char *numberTest, const char *interval,const char *thrNumber,const char *winSize, const char *portNum, int UDPorTCP){
    //copies passed in variables to global variables
    strcpy(ipAddress,ip);
    strcpy(numberOfTests, numberTest);
    strcpy(intervals, interval);
    //Alex Hauser: Added threadNumber strcpy instruction to fascillitate importing the
    //number of thread variable from the options ViewController, allowing the user
    //to specify at runtime to what extent they want iPerf to be multithreaded
    strcpy(windowSize, winSize);
    strcpy(threadNumber,thrNumber);
    strcpy(portNumber,portNum);
    
    
    uDPorTCP = UDPorTCP;
    
}


void Settings_Copy( thread_Settings *from, thread_Settings **into ) {
    *into = new thread_Settings;
    memcpy( *into, from, sizeof(thread_Settings) );
    if ( from->mHost != NULL ) {
        (*into)->mHost = new char[ strlen(from->mHost) + 1];
        strcpy( (*into)->mHost, from->mHost );
    }
    if ( from->mOutputFileName != NULL ) {
        (*into)->mOutputFileName = new char[ strlen(from->mOutputFileName) + 1];
        strcpy( (*into)->mOutputFileName, from->mOutputFileName );
    }
    if ( from->mLocalhost != NULL ) {
        (*into)->mLocalhost = new char[ strlen(from->mLocalhost) + 1];
        strcpy( (*into)->mLocalhost, from->mLocalhost );
    }
    if ( from->mFileName != NULL ) {
        (*into)->mFileName = new char[ strlen(from->mFileName) + 1];
        strcpy( (*into)->mFileName, from->mFileName );
    }
    // Zero out certain entries
    (*into)->mTID = thread_zeroid();
    (*into)->runNext = NULL;
    (*into)->runNow = NULL;
}

void Notify_Test_End(){
    [LoggingWrapper reportEnd];
}

/* -------------------------------------------------------------------
 * Delete memory: Does not clean up open file pointers or ptr_parents
 * ------------------------------------------------------------------- */

void Settings_Destroy( thread_Settings *mSettings) {
    DELETE_ARRAY( mSettings->mHost      );
    DELETE_ARRAY( mSettings->mLocalhost );
    DELETE_ARRAY( mSettings->mFileName  );
    DELETE_ARRAY( mSettings->mOutputFileName );
    DELETE_PTR( mSettings );
} // end ~Settings

/* -------------------------------------------------------------------
 * Parses settings from user's environment variables.
// * ------------------------------------------------------------------- */
void Settings_ParseEnvironment( thread_Settings *mSettings )
{
    char *theVariable;

    int i = 0;
    while ( env_options[i].name != NULL ) {
        theVariable = getenv( env_options[i].name );
        if ( theVariable != NULL ) {
            Settings_Interpret( env_options[i].val, theVariable, mSettings );
        }
        i++;
    }
} // end ParseEnvironment

/* -------------------------------------------------------------------
 * Parse settings from app's command line.
 * ------------------------------------------------------------------- */

void Settings_ParseCommandLine( int argc, thread_Settings *mSettings )
{
    // print_to_console("iperf ");
    char option=1; //used as character to show FS
    
    // Byun: added at v0_9_2
    if(uDPorTCP == 1) // UDP 1 sec
    {
        // print_to_console("\n Interpreting UDP Settings \n");
        
        option='u';
        Settings_Interpret(option, "",mSettings);
        
        option='p';
        Settings_Interpret(option, portNumber, mSettings);
        
        option='l';
        Settings_Interpret(option, "220", mSettings);
        
        option='b';
        Settings_Interpret(option, "88k", mSettings);
        
        option='t';
        Settings_Interpret(option, "1", mSettings);
    }
    else if(uDPorTCP == 5) // UDP 5 seconds
    {
        // print_to_console("\n Interpreting UDP Settings \n");
        
        option='u';
        Settings_Interpret(option, "",mSettings);
        
        option='p';
        Settings_Interpret(option, portNumber, mSettings);
        
        option='l';
        Settings_Interpret(option, "220", mSettings);
        
        option='b';
        Settings_Interpret(option, "88k", mSettings);
        
        option='t';
        Settings_Interpret(option, "5", mSettings);
    }
    else  // TCP test
    {
        // print_to_console("\n Interpreting TCP Settings \n");
        
        //sets mode to use same tcp connections FS
        // Byun: Set '-e' option. Then, we should set #define SAME_TCP as well.
        option='e';
        Settings_Interpret(option, "", mSettings);
        
        
        option='w';
        Settings_Interpret(option, windowSize, mSettings);
        //Settings_Interpret(option, "0k", mSettings);
        
        //Alex Hauser: This option specifies the port number for iPerf to use. Previously I suspected that
        //that an incorrect port number might be causing the Interval problem, but since that does not seem to
        //be the cause, this added statement is commented out for the time being.
        option='p';
        Settings_Interpret(option, portNumber , mSettings);
        
        // Byun:
        option='P';
        Settings_Interpret(option, threadNumber, mSettings);
        //printf("^^DEBUG: Setting numbers of threads: %s\n", threadNumber);
        //Settings_Interpret(option, "4", mSettings);
        
        //Alex Hauser: Added t option to be passed to the iPerf system, which specifies the
        //total time to conduct the iPerf test in seconds.
        option='t';
        Settings_Interpret(option, numberOfTests, mSettings);
        // Byun: For debugging purpose. It should be changed to numberOfTest
        //Settings_Interpret(option, "5", mSettings);
    }
    
    //sets mode to client FS
    option='c';
    Settings_Interpret(option, ipAddress ,mSettings);
    
    option='f';
    // Settings_Interpret(option, threadNumber, mSettings);
    Settings_Interpret(option, "k", mSettings);
    
    //Alex Hauser: This option instructs iPerf to run in compatibility mode - originally
    //I thought that the Interval problem might be caused by compatibility issues, but that
    //does not seem to be the case. As a result, this added statement has been commented out for now.
    //  option='C';
    //  Settings_Interpret(option, portNumber , mSettings);
    
    //    option='V';
    //   Settings_Interpret(option, portNumber , mSettings);
    
    
    
    
    //Alex Hauser: The T option, which interestingly seems to work similarly to the interval system.
    //However, it has a few problems and has been subsequently commented out as a result.
    // option = 'T';
    //Settings_Interpret(option, intervals, mSettings);
    
    
    
    //Alex Hauser: Added i option to be passed to the iPerf system. Currently
    //nonfunctional, generates an infinite number of erronous reports if
    //the interval option is set.
    option='i';
    Settings_Interpret(option, intervals, mSettings);
    
    
    //Alex Hauser: this option instructs iPerf to print version information
    // option='v';
    // Settings_Interpret(option,numberOfTests,mSettings);
    
    
    
    // option='N';
    // Settings_Interpret(option, threadNumber, mSettings);
    
    //option='1'; //single client mode?
    //Settings_Interpret(option, threadNumber, mSettings);
    
    
    //Commented out this section since fprintf is nonfunctional on the ios operating system.
    //Settings_Interpret(option, name, mSettings);
    //    }
    
    //    for ( int i = gnu_optind; i < argc; i++ ) {
    //        fprintf( stderr, "%s: ignoring extra argument -- %s\n", argv[0], argv[i] );
    //    }
} // end ParseCommandLine


/* -------------------------------------------------------------------
 * Interpret individual options, either from the command line
 * or from environment variables.
 * ------------------------------------------------------------------- */

void Settings_Interpret( char option, const char *optarg, thread_Settings *mExtSettings ) {
    char outarg[100];
    
    print_to_console("-%c %s\n",option,optarg);

    switch ( option )
    {
        case '1': // Single Client
            setSingleClient( mExtSettings );
            break;
        case 'b': // UDP bandwidth
            if ( !isUDP( mExtSettings ) )
            {
                fprintf( stderr, warn_implied_udp, option );
            }

            if ( mExtSettings->mThreadMode != kMode_Client )
            {
                fprintf( stderr, warn_invalid_server_option, option );
                break;
            }

            Settings_GetLowerCaseArg(optarg,outarg);
            mExtSettings->mUDPRate = byte_atoi(outarg);
            setUDP( mExtSettings );

            // if -l has already been processed, mBufLenSet is true
            // so don't overwrite that value.
            if ( !isBuflenSet( mExtSettings ) )
            {
                mExtSettings->mBufLen = kDefault_UDPBufLen;
            }
            break;

        case 'c': // client mode w/ server host to connect to
            mExtSettings->mHost = new char[10];
            strcpy( mExtSettings->mHost, optarg );

            if ( mExtSettings->mThreadMode == kMode_Unknown )
            {
                // Test for Multicast
                iperf_sockaddr temp;
                SockAddr_setHostname( mExtSettings->mHost, &temp,
                                      (isIPV6( mExtSettings ) ? 1 : 0 ));
                if ( SockAddr_isMulticast( &temp ) )
                {
                    setMulticast( mExtSettings );
                }
                mExtSettings->mThreadMode = kMode_Client;
                mExtSettings->mThreads = 1;
            }
            break;

        case 'd': // Dual-test Mode
            if ( mExtSettings->mThreadMode != kMode_Client )
            {
                fprintf( stderr, warn_invalid_server_option, option );
                break;
            }
            if ( isCompat( mExtSettings ) )
            {
                fprintf( stderr, warn_invalid_compatibility_option, option );
            }
#ifdef HAVE_THREAD
            mExtSettings->mMode = kTest_DualTest;
#else
            fprintf( stderr, warn_invalid_single_threaded, option );
            mExtSettings->mMode = kTest_TradeOff;
#endif
            break;

#ifdef SAME_TCP
        case 'e': // test mode tradeoff on the same TCP connection
            if ( mExtSettings->mThreadMode != kMode_Client )
            {
                fprintf( stderr, warn_invalid_server_option, option );
                break;
            }
            if ( isCompat( mExtSettings ) ) {
                fprintf( stderr, warn_invalid_compatibility_option, option );
            }

            mExtSettings->mMode = kTest_SameTCP_TradeOff;
            break;
#endif

        case 'f': // format to print in
            mExtSettings->mFormat = (*optarg);
            break;

        case 'h': // print help and exit
#ifndef WIN32
            fprintf( stderr, "%s", usage_long );
#else
            fprintf(stderr, usage_long1);
            fprintf(stderr, usage_long2);
#endif
            exit(1);
            break;

        case 'i': // specify interval between periodic bw reports
            mExtSettings->mInterval = atof(optarg);
            print_to_console("mInterval = %f",mExtSettings->mInterval);
            if(mExtSettings->mInterval < 0.5)
            {
                fprintf (stderr, report_interval_small, mExtSettings->mInterval);
                mExtSettings->mInterval = 0.5;
            }
            break;

        case 'l': // length of each buffer
            Settings_GetUpperCaseArg(optarg,outarg);
            // Jack: Added int cast to "byte_atoi" of type unsigned long, to silence the conversion precision loss warning
            mExtSettings->mBufLen = (int)byte_atoi( outarg );
            setBuflenSet( mExtSettings );
            if ( !isUDP( mExtSettings ) ) {
                 if ( mExtSettings->mBufLen < (int) sizeof( client_hdr ) &&
                      !isCompat( mExtSettings ) ) {
                    setCompat( mExtSettings );
                    fprintf( stderr, warn_implied_compatibility, option );
                 }
            } else
            {
                if ( mExtSettings->mBufLen < (int) sizeof( UDP_datagram ) )
                {
                    mExtSettings->mBufLen = sizeof( UDP_datagram );
                    fprintf( stderr, warn_buffer_too_small, mExtSettings->mBufLen );
                }
                if ( !isCompat( mExtSettings ) &&
                            mExtSettings->mBufLen < (int) ( sizeof( UDP_datagram )
                            + sizeof( client_hdr ) ) )
                {
                    setCompat( mExtSettings );
                    fprintf( stderr, warn_implied_compatibility, option );
                }
            }

            break;

        case 'm': // print TCP MSS
            setPrintMSS( mExtSettings );
            break;

        case 'n': // bytes of data
            // amount mode (instead of time mode)
            unsetModeTime( mExtSettings );
            Settings_GetUpperCaseArg(optarg,outarg);
            mExtSettings->mAmount = byte_atoi( outarg );
            break;

        case 'o' : // output the report and other messages into the file
            unsetSTDOUT( mExtSettings );
            mExtSettings->mOutputFileName = new char[strlen(optarg)+1];
            strcpy( mExtSettings->mOutputFileName, optarg);
            break;

        case 'p': // server port
            mExtSettings->mPort = atoi( optarg );
            break;

        case 'r': // test mode tradeoff
            if ( mExtSettings->mThreadMode != kMode_Client )
            {
                fprintf( stderr, warn_invalid_server_option, option );
                break;
            }
            if ( isCompat( mExtSettings ) )
            {
                fprintf( stderr, warn_invalid_compatibility_option, option );
            }

            mExtSettings->mMode = kTest_TradeOff;
            break;

        case 's': // server mode
            if ( mExtSettings->mThreadMode != kMode_Unknown )
            {
                fprintf( stderr, warn_invalid_client_option, option );
                break;
            }

            mExtSettings->mThreadMode = kMode_Listener;
            break;

        case 't': // seconds to write for
            // time mode (instead of amount mode)
            
            //Alex Hauser: added a print_to_console statement to confirm that the
            //program is indeed successfully reaching this point of code
            
            setModeTime( mExtSettings );
            // print_to_console("Got to case 't'\n");  // Byun
            mExtSettings->mAmount = (int) (atof( optarg ) * 100.0);
           // mExtSettings->mAmount = (int)(atof( optarg ));
            
          
            break;

        case 'u': // UDP instead of TCP
            // if -b has already been processed, UDP rate will
            // already be non-zero, so don't overwrite that value
            if ( !isUDP( mExtSettings ) )
            {
                setUDP( mExtSettings );
                mExtSettings->mUDPRate = kDefault_UDPRate;
            }

            // if -l has already been processed, mBufLenSet is true
            // so don't overwrite that value.
            if(!isBuflenSet(mExtSettings))
            {
                mExtSettings->mBufLen = kDefault_UDPBufLen;
            }
            else if ( mExtSettings->mBufLen < (int) ( sizeof( UDP_datagram )
                        + sizeof(client_hdr)) &&
                        !isCompat(mExtSettings))
            {
                setCompat( mExtSettings );
                fprintf( stderr, warn_implied_compatibility, option );
            }
            break;

        case 'v': // print version and exit
            fprintf( stderr, "%s", version );
            break;

        case 'w': // TCP window size (socket buffer size)
            Settings_GetUpperCaseArg(optarg,outarg);
            // Jack: Added int cast to "byte_atoi" of type long, to silence the conversion precision loss warning
            mExtSettings->mTCPWin = (int)byte_atoi(outarg);

            if ( mExtSettings->mTCPWin < 2048 )
            {
                fprintf( stderr, warn_window_small, mExtSettings->mTCPWin );
            }
            break;

        case 'x': // Limit Reports
            while(*optarg != '\0')
            {
                switch ( *optarg )
                {
                    case 's':
                    case 'S':
                        setNoSettReport( mExtSettings );
                        break;
                    case 'c':
                    case 'C':
                        setNoConnReport( mExtSettings );
                        break;
                    case 'd':
                    case 'D':
                        setNoDataReport( mExtSettings );
                        break;
                    case 'v':
                    case 'V':
                        setNoServReport( mExtSettings );
                        break;
                    case 'm':
                    case 'M':
                        setNoMultReport( mExtSettings );
                        break;
                    default:
                        fprintf(stderr, warn_invalid_report, *optarg);
                }
                optarg++;
            }
            break;

        case 'y': // Reporting Style
            switch ( *optarg )
            {
                case 'c':
                case 'C':
                    mExtSettings->mReportMode = kReport_CSV;
                    break;
                default:
                    fprintf( stderr, warn_invalid_report_style, optarg );
            }
            break;


            // more esoteric options
        case 'B': // specify bind address
            mExtSettings->mLocalhost = new char[ strlen( optarg ) + 1 ];
            strcpy( mExtSettings->mLocalhost, optarg );
            // Test for Multicast
            iperf_sockaddr temp;
            SockAddr_setHostname( mExtSettings->mLocalhost, &temp,
                                  (isIPV6( mExtSettings ) ? 1 : 0 ));
            if ( SockAddr_isMulticast( &temp ) )
            {
                setMulticast( mExtSettings );
            }
            break;

        case 'C': // Run in Compatibility Mode
            setCompat( mExtSettings );
            if ( mExtSettings->mMode != kTest_Normal )
            {
                fprintf( stderr, warn_invalid_compatibility_option,
                        ( mExtSettings->mMode == kTest_DualTest ?
                          'd' : 'r' ) );
                mExtSettings->mMode = kTest_Normal;
            }
            break;

        case 'D': // Run as a daemon
            setDaemon( mExtSettings );
            break;

        case 'F' : // Get the input for the data stream from a file
            if ( mExtSettings->mThreadMode != kMode_Client )
            {
                fprintf( stderr, warn_invalid_server_option, option );
                break;
            }

            setFileInput( mExtSettings );
            mExtSettings->mFileName = new char[strlen(optarg)+1];
            strcpy( mExtSettings->mFileName, optarg);
            break;

        case 'I' : // Set the stdin as the input source
            if ( mExtSettings->mThreadMode != kMode_Client )
            {
                fprintf( stderr, warn_invalid_server_option, option );
                break;
            }

            setFileInput( mExtSettings );
            setSTDIN( mExtSettings );
            mExtSettings->mFileName = new char[strlen("<stdin>")+1];
            strcpy( mExtSettings->mFileName,"<stdin>");
            break;

        case 'L': // Listen Port (bidirectional testing client-side)
            if ( mExtSettings->mThreadMode != kMode_Client )
            {
                fprintf( stderr, warn_invalid_server_option, option );
                break;
            }

            mExtSettings->mListenPort = atoi( optarg );
            break;

        case 'M': // specify TCP MSS (maximum segment size)
            Settings_GetUpperCaseArg(optarg,outarg);

            // Jack: Added int cast to "byte_atoi" of type unsigned long, to silence the conversion precision loss warning
            mExtSettings->mMSS = (int)byte_atoi( outarg );
            break;

        case 'N': // specify TCP nodelay option (disable Jacobson's Algorithm)
            setNoDelay( mExtSettings );
            break;

        case 'P': // number of client threads
#ifdef HAVE_THREAD
            mExtSettings->mThreads = atoi( optarg );
#else
            //Alex Hause: commented out this section as it was disabling multithreaded capability on ios
            //if ( mExtSettings->mThreadMode != kMode_Server ) {
            //    fprintf( stderr, warn_invalid_single_threaded, option );
            //} else {
                mExtSettings->mThreads = atoi( optarg );
            //}
#endif
            break;

        case 'R':
            setRemoveService( mExtSettings );
            break;

        case 'S': // IP type-of-service
            // TODO use a function that understands base-2
            // the zero base here allows the user to specify
            // "0x#" hex, "0#" octal, and "#" decimal numbers
            // Jack: Added int cast to "strtol" of type long, to silence the conversion precision loss warning
            mExtSettings->mTOS = (int)strtol( optarg, NULL, 0 );
            break;

        case 'T': // time-to-live for multicast
            mExtSettings->mTTL = atoi( optarg );
            break;

        case 'U': // single threaded UDP server
            setSingleUDP( mExtSettings );
            break;

        case 'V': // IPv6 Domain
            setIPV6( mExtSettings );
            if ( mExtSettings->mThreadMode == kMode_Server 
                 && mExtSettings->mLocalhost != NULL )
            {
                // Test for Multicast
                iperf_sockaddr temp;
                SockAddr_setHostname( mExtSettings->mLocalhost, &temp, 1);
                if ( SockAddr_isMulticast( &temp ) )
                {
                    setMulticast( mExtSettings );
                }
            } else if ( mExtSettings->mThreadMode == kMode_Client )
            {
                // Test for Multicast
                iperf_sockaddr temp;
                SockAddr_setHostname( mExtSettings->mHost, &temp, 1 );
                if ( SockAddr_isMulticast( &temp ) ) {
                    setMulticast( mExtSettings );
                }
            }
            break;

        case 'W' :
            setSuggestWin( mExtSettings );
            fprintf( stderr, "The -W option is not available in this release\n");
            break;

        default: // ignore unknown
            break;
    }
    print_to_console("\n");
} // end Interpret

void Settings_GetUpperCaseArg(const char *inarg, char *outarg)
{

    // Jack: Added int cast to "strlen" of type unsigned long, to silence the conversion precision loss warning
    int len = (int)strlen(inarg);
    strcpy(outarg,inarg);

    if ( (len > 0) && (inarg[len-1] >='a') 
         && (inarg[len-1] <= 'z') )
        outarg[len-1]= outarg[len-1]+'A'-'a';
}

void Settings_GetLowerCaseArg(const char *inarg, char *outarg)
{

    // Jack: Added int cast to "strlen" of type unsigned long, to silence the conversion precision loss warning
    int len = (int)strlen(inarg);
    strcpy(outarg,inarg);

    if ( (len > 0) && (inarg[len-1] >='A') 
         && (inarg[len-1] <= 'Z') )
        outarg[len-1]= outarg[len-1]-'A'+'a';
}

/*
 * Settings_GenerateListenerSettings
 * Called to generate the settings to be passed to the Listener
 * instance that will handle dual testings from the client side
 * this should only return an instance if it was called on 
 * the thread_Settings instance generated from the command line 
 * for client side execution 
 */
void Settings_GenerateListenerSettings( thread_Settings *client, thread_Settings **listener )
{
    if ( !isCompat( client ) && 
         (client->mMode == kTest_DualTest || client->mMode == kTest_TradeOff) )
    {
        *listener = new thread_Settings;
        memcpy(*listener, client, sizeof( thread_Settings ));
        setCompat( (*listener) );
        unsetDaemon( (*listener) );
        if(client->mListenPort != 0)
        {
            (*listener)->mPort   = client->mListenPort;
        }
        else
        {
            (*listener)->mPort   = client->mPort;
        }
        (*listener)->mFileName   = NULL;
        (*listener)->mHost       = NULL;
        (*listener)->mLocalhost  = NULL;
        (*listener)->mOutputFileName = NULL;
        (*listener)->mMode       = kTest_Normal;
        (*listener)->mThreadMode = kMode_Listener;
        if(client->mHost != NULL)
        {
            (*listener)->mHost = new char[strlen( client->mHost ) + 1];
            strcpy( (*listener)->mHost, client->mHost );
        }
        if ( client->mLocalhost != NULL )
        {
            (*listener)->mLocalhost = new char[strlen( client->mLocalhost ) + 1];
            strcpy( (*listener)->mLocalhost, client->mLocalhost );
        }
    }
    else
    {
        *listener = NULL;
    }
}
#ifdef SAME_TCP
/*
 * Settings_GenerateServerSettings
 * Called to generate the settings to be passed to the Server
 * instance that will handle dual testings from the client side
 * using the same TCP Connection
 * this should only return an instance if it was called on 
 * the thread_Settings instance generated from the command line 
 * for client side execution 
 */
void Settings_GenerateServerSettings( thread_Settings *client, thread_Settings **server )
{
    if ( !isCompat( client ) && 
         (client->mMode == kTest_SameTCP_TradeOff_ClientSide ) )
    {
            //Alex Hauser: print_to_console statement for debug purposes
            // print_to_console("\nSettings_GenerateServerSettings\n");
            *server = new thread_Settings;
            memcpy(*server, client, sizeof( thread_Settings ));
            setCompat( (*server) );
            unsetDaemon( (*server) );
            (*server)->mFileName   = NULL;
            (*server)->mHost       = NULL;
            (*server)->mLocalhost  = NULL;
            (*server)->mOutputFileName = NULL;
            (*server)->mMode       = kTest_SameTCP_TradeOff_ClientSide;
            (*server)->mThreadMode = kMode_Server;
            (*server)->mSock = client->mSock;
            if ( client->mHost != NULL )
            {
                (*server)->mHost = new char[strlen( client->mHost ) + 1];
                strcpy( (*server)->mHost, client->mHost );
            }
            if ( client->mLocalhost != NULL )
            {
                (*server)->mLocalhost = new char[strlen( client->mLocalhost ) + 1];
                strcpy( (*server)->mLocalhost, client->mLocalhost );
            }
    }
    else
    {
        //Alex Hauser: print_to_console statement for debug purposes
        //print_to_console("\nServer is apparently null\n");
        *server = NULL;
    }
}
#endif

/*
 * Settings_GenerateSpeakerSettings
 * Called to generate the settings to be passed to the Speaker
 * instance that will handle dual testings from the server side
 * this should only return an instance if it was called on 
 * the thread_Settings instance generated from the command line 
 * for server side execution. This should be an inverse operation
 * of GenerateClientHdr. 
 */
void Settings_GenerateClientSettings( thread_Settings *server, 
                                      thread_Settings **client,
                                      client_hdr *hdr )
{
    //Alex Hauser: print_to_console statement for debug purposes
    // print_to_console("\nGot here\n");
    int flags = ntohl(hdr->flags);
    if ( (flags & HEADER_VERSION1) != 0 )
    {
#ifdef SAME_TCP
		if ((flags & RUN_ON_SAME_TCP) != 0)  // Commented by Byun to turn the -e option on.
		// if (true)
        {
			server -> mThreadMode = kMode_Client;
        		server->mMode       = kTest_SameTCP_TradeOff_ServerSide;
			fprintf (stderr,"I am being asked to launch a client instead of a server\n");
            setCompat( (server) );
           (server)->mTID = thread_zeroid();
            (server)->mPort       = (unsigned short) ntohl(hdr->mPort);
            (server)->mThreads    = ntohl(hdr->numThreads);
            if ( hdr->bufferlen != 0 )
            {
                (server)->mBufLen = ntohl(hdr->bufferlen);
            }
            if ( hdr->mWinBand != 0 )
            {
            
                if ( isUDP( server ) )
                {
                    (server)->mUDPRate = ntohl(hdr->mWinBand);
                }
                else
                {
                    (server)->mTCPWin = ntohl(hdr->mWinBand);
                }
            }
            (server)->mAmount     = ntohl(hdr->mAmount);
            if ( ((server)->mAmount & 0x80000000) > 0 )
            {
                setModeTime( (server) );
#ifndef WIN32
                    (server)->mAmount |= 0xFFFFFFFF00000000LL;
#else
                    (server)->mAmount |= 0xFFFFFFFF00000000;
#endif
                    (server)->mAmount = -(server)->mAmount;
            }
            (server)->mFileName   = NULL;
            (server)->mOutputFileName = NULL;
            server->multihdr = NULL;
            return;
		}
#endif // SAME_TCP
        *client = new thread_Settings;
        memcpy(*client, server, sizeof( thread_Settings ));
        setCompat((*client));
        (*client)->mTID = thread_zeroid();
        (*client)->mPort       = (unsigned short) ntohl(hdr->mPort);
        (*client)->mThreads    = ntohl(hdr->numThreads);
        if ( hdr->bufferlen != 0 )
        {
            (*client)->mBufLen = ntohl(hdr->bufferlen);
        }
        if ( hdr->mWinBand != 0 )
        {
            if ( isUDP( server ) )
            {
                (*client)->mUDPRate = ntohl(hdr->mWinBand);
            }
            else
            {
                (*client)->mTCPWin = ntohl(hdr->mWinBand);
            }
        }
        (*client)->mAmount     = ntohl(hdr->mAmount);
        if ( ((*client)->mAmount & 0x80000000) > 0 )
        {
            setModeTime( (*client) );
#ifndef WIN32
            (*client)->mAmount |= 0xFFFFFFFF00000000LL;
#else
           (*client)->mAmount |= 0xFFFFFFFF00000000;
#endif
            (*client)->mAmount = -(*client)->mAmount;
        }
        (*client)->mFileName   = NULL;
        (*client)->mHost       = NULL;
        (*client)->mLocalhost  = NULL;
        (*client)->mOutputFileName = NULL;
        (*client)->mMode       = ((flags & RUN_NOW) == 0 ?
                                   kTest_TradeOff : kTest_DualTest);
        (*client)->mThreadMode = kMode_Client;
        if(server->mLocalhost != NULL)
        {
            (*client)->mLocalhost = new char[strlen( server->mLocalhost ) + 1];
            strcpy( (*client)->mLocalhost, server->mLocalhost );
        }
        (*client)->mHost = new char[REPORT_ADDRLEN];
        if(((sockaddr*)&server->peer)->sa_family == AF_INET)
        {
            inet_ntop( AF_INET, &((sockaddr_in*)&server->peer)->sin_addr, 
                       (*client)->mHost, REPORT_ADDRLEN);
        }
#ifdef HAVE_IPV6
        else
        {
            inet_ntop( AF_INET6, &((sockaddr_in6*)&server->peer)->sin6_addr, 
                       (*client)->mHost, REPORT_ADDRLEN);
        }
#endif
    }
    else
    {
        *client = NULL;
    }
}

/*
 * Settings_GenerateClientHdr
 * Called to generate the client header to be passed to the
 * server that will handle dual testings from the server side
 * This should be an inverse operation of GenerateSpeakerSettings
 */
void Settings_GenerateClientHdr( thread_Settings *client, client_hdr *hdr )
{
    // print_to_console("\nGot to 'Settings_GenerateClientHdr'\n");
#ifdef SAME_TCP
    if((client->mMode == kTest_DualTest) || (client->mMode == kTest_TradeOff) || (client->mMode == kTest_SameTCP_TradeOff_ClientSide))
    {
#else
    if(client->mMode != kTest_Normal)
    {
#endif
        hdr->flags  = htonl(HEADER_VERSION1);
    }
    else
    {
        hdr->flags  = 0;
    }
    if(isBuflenSet(client))
    {
        hdr->bufferlen = htonl(client->mBufLen);
    }
    else
    {
        hdr->bufferlen = 0;
    }
    if(isUDP(client))
    {
        hdr->mWinBand  = htonl(client->mUDPRate);
    }
    else
    {
        hdr->mWinBand  = htonl(client->mTCPWin);
    }
    if ( client->mListenPort != 0 )
    {
        hdr->mPort  = htonl(client->mListenPort);
    }
    else
    {
        hdr->mPort  = htonl(client->mPort);
    }
    hdr->numThreads = htonl(client->mThreads);
    if(isModeTime(client))
    {
        hdr->mAmount    = htonl(-(long)client->mAmount);
    }
    else
    {
        //Alex Hauser: print_to_console statement for debug purposes
        //print_to_console("\nDid not get past 'isModeTime(client)' check\n");
        hdr->mAmount    = htonl((long)client->mAmount);
        hdr->mAmount &= htonl( 0x7FFFFFFF );
    }
    if ( client->mMode == kTest_DualTest )
    {
        hdr->flags |= htonl(RUN_NOW);
    }
#ifdef SAME_TCP
    if ( client->mMode == kTest_SameTCP_TradeOff_ClientSide ) {
        hdr->flags |= htonl(RUN_ON_SAME_TCP);
    }
#endif
}
