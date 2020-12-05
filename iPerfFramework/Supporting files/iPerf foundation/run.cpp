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

#include "run.h"
#include "Settings.hpp"
extern "C"
{
    // Global flag to signal a user interrupt
    int sInterupted = 0;
    // Global ID that we increment to be used
    // as identifier for SUM reports
    int groupID = 0;
    // Mutex to protect access to the above ID
    Mutex groupCond;
    // Condition used to signify advances of the current
    // records being accessed in a report and also to
    // serialize modification of the report list
    Condition ReportCond;
    nthread_t sThread;
    
    // Function prototype
    void * run_iPerf_command(void *ptr);
    
    // Indicate if an iPerf timeout happened.
    extern int iperf_timeout;
    
    // Byun: added at v0_9_3
    extern struct thread_Settings* iOS_iPerf_thread_info[64];  // to keep the thread info to terminate at timeout
}

/* -------------------------------------------------------------------
 * main()
 *      Entry point into Iperf
 *
 * sets up signal handlers
 * initialize global locks and conditions
 * parses settings from environment and command line
 * starts up server or client thread
 * waits for all threads to complete
 * ------------------------------------------------------------------- */
#define SAME_TCP

// Byun: Add the two definitions
#define HAVE_THREAD
#define HAVE_POSIX_THREAD

// Byun: to finish the reporter thread
int unique_num = 0;
static int isUDP;

void * run_iPerf_command(void *threadid)
{
    // Byun: added at v0_9_3
    for (int i=0; i < 10; i++)
    {
        iOS_iPerf_thread_info[i] = 0;
    }
    
    // Initialize global mutexes and conditions
    Condition_Initialize ( &ReportCond );
    Mutex_Initialize( &groupCond );
    Mutex_Initialize( &clients_mutex );
    // Initialize the thread subsystem
    thread_init( );
    
    // Initialize the interrupt handling thread to 0
    sThread = thread_zeroid();
    
    // perform any cleanup when quitting Iperf
    atexit( cleanup );
    
    // Allocate the "global" settings
    thread_Settings* ext_gSettings = new thread_Settings;
    
    // Initialize settings to defaults
    Settings_Initialize( ext_gSettings );
    Settings_ParseEnvironment( ext_gSettings );
    // read settings from command-line parameters
    Settings_ParseCommandLine( 1, ext_gSettings );
    
    // Check for either having specified client or server
    if ( ext_gSettings->mThreadMode == kMode_Client
        || ext_gSettings->mThreadMode == kMode_Listener )
    {
        
        // initialize client(s)
        if ( ext_gSettings->mThreadMode == kMode_Client )
        {
            client_init( ext_gSettings );
        }
        
        // start up the reporter and client(s) or listener
        thread_Settings *into = NULL;
        // Create the settings structure for the reporter thread
        Settings_Copy( ext_gSettings, &into );
        // Byun: When I uncomment it, the simulator doesn't display "Test Complete" on the simulator.
        // But I think that "uncomment" is a correct approach because it doesn't start a new thread.
        into->mThreadMode = kMode_Reporter;
            
        // Have the reporter launch the client or listener
        into->runNow = ext_gSettings;
            
        // Start all the threads that are ready to go
        thread_start( into );
        
    } else {
        // neither server nor client mode was specified
        // print usage and exit
        return NULL;
    }
    
    sleep(2);   // Byun: v0_9_4 - to guarantee that the reporter thread starts for the processing.
                // FIXME: sleep(2) may not be a good solution.
    
    // wait for other (client, server) threads to complete
    // thread_joinall();
    // Byun: v0_9_5
    iOS_iPerf_thread_joinall(isUDP);
    
    // Byun: Added to finish the reporter thread
    unique_num++;
    
    // Byun: Wait for a while to make sure that the reporter thread terminates.
    // It's important for the reporter thread to get Condition_Signal( &ReportCond )
    // FIXME! Use a loop and a glabal variable to make sure the termination of reporter thread
    sleep(2);
    
    Condition_Signal( &ReportCond );
    
    cleanup();
    
    // all done!
    pthread_exit(0); /* exit */
    
} // end main


// Byun: v0_9_5 - add the argument "tcp_or_udp"
int launch_iPerf_thread(int tcp_or_udp)
{
    // Jack: Commented out unused variable "x", to silence the warning
    //int x = 0;
    isUDP = tcp_or_udp;
    
    pthread_t thread1;
    
    /* create threads 1 */
    // Jack: Changed the use of an empty integer to the equivalent, clean use of a null pointer for use in the "pthread_create" method, to silence the warning
    pthread_create (&thread1, NULL, run_iPerf_command,
                    NULL);
                    // Jack: Below, old part of method that was replaced
                    //(void *)x);
    
    // Main thread waits for the thread1 to terminate
    pthread_join(thread1, NULL);
    
    return 0;
} // end main





/* -------------------------------------------------------------------
 * Signal handler sets the sInterupted flag, so the object can
 * respond appropriately.. [static]
 * ------------------------------------------------------------------- */

void Sig_Interupt( int inSigno ) {
#ifdef HAVE_THREAD
    // We try to not allow a single interrupt handled by multiple threads
    // to completely kill the app so we save off the first thread ID
    // then that is the only thread that can supply the next interrupt
    if ( thread_equalid( sThread, thread_zeroid() ) ) {
        sThread = thread_getid();
    } else if ( thread_equalid( sThread, thread_getid() ) ) {
        // Byun: Original sig_exit() is at the signal.c. But I added it here.
        // sig_exit( inSigno );
        fflush( 0 );
        exit( 0 );
    }
    
    // global variable used by threads to see if they were interrupted
    sInterupted = 1;
    
    // with threads, stop waiting for non-terminating threads
    // (ie Listener Thread)
    thread_release_nonterm( 1 );
    
#else
    // without threads, just exit quietly, same as sig_exit()
    // Byun: Original sig_exit() is at the signal.c. But I added it here.
    // sig_exit( inSigno );
    fflush( 0 );
    exit( 0 );
#endif
}

/* -------------------------------------------------------------------
 * Any necesary cleanup before Iperf quits. Called at program exit,
 * either by exit() or terminating main().
 * ------------------------------------------------------------------- */

void cleanup( void ) {
    // clean up the list of clients
    Iperf_destroy ( &clients );
    
    // shutdown the thread subsystem
    thread_destroy( );
} // end cleanup

#ifdef WIN32
/*--------------------------------------------------------------------
 * ServiceStart
 *
 * each time starting the service, this is the entry point of the service.
 * Start the service, certainly it is on server-mode
 *
 *-------------------------------------------------------------------- */
VOID ServiceStart (DWORD dwArgc, LPTSTR *lpszArgv) {
    
    // report the status to the service control manager.
    //
    if ( !ReportStatusToSCMgr(
                              SERVICE_START_PENDING, // service state
                              NO_ERROR,              // exit code
                              3000) )                 // wait hint
        goto clean;
    
    thread_Settings* ext_gSettings = new thread_Settings;
    
    // Initialize settings to defaults
    Settings_Initialize( ext_gSettings );
    // read settings from environment variables
    Settings_ParseEnvironment( ext_gSettings );
    // read settings from command-line parameters
    Settings_ParseCommandLine( dwArgc, lpszArgv, ext_gSettings );
    
    // report the status to the service control manager.
    //
    if ( !ReportStatusToSCMgr(
                              SERVICE_START_PENDING, // service state
                              NO_ERROR,              // exit code
                              3000) )                 // wait hint
        goto clean;
    
    // if needed, redirect the output into a specified file
    if ( !isSTDOUT( ext_gSettings ) ) {
        redirect( ext_gSettings->mOutputFileName );
    }
    
    // report the status to the service control manager.
    //
    if ( !ReportStatusToSCMgr(
                              SERVICE_START_PENDING, // service state
                              NO_ERROR,              // exit code
                              3000) )                 // wait hint
        goto clean;
    
    // initialize client(s)
    if ( ext_gSettings->mThreadMode == kMode_Client ) {
        client_init( ext_gSettings );
    }
    
    // start up the reporter and client(s) or listener
    {
        thread_Settings *into = NULL;
#ifdef HAVE_THREAD
        Settings_Copy( ext_gSettings, &into );
        into->mThreadMode = kMode_Reporter;
        into->runNow = ext_gSettings;
#else
        into = ext_gSettings;
#endif
        thread_start( into );
    }
    
    // report the status to the service control manager.
    //
    if ( !ReportStatusToSCMgr(
                              SERVICE_RUNNING,       // service state
                              NO_ERROR,              // exit code
                              0) )                    // wait hint
        goto clean;
    
clean:
    // wait for other (client, server) threads to complete
    thread_joinall();
}


//
//  FUNCTION: ServiceStop
//
//  PURPOSE: Stops the service
//
//  PARAMETERS:
//    none
//
//  RETURN VALUE:
//    none
//
//  COMMENTS:
//    If a ServiceStop procedure is going to
//    take longer than 3 seconds to execute,
//    it should spawn a thread to execute the
//    stop code, and return.  Otherwise, the
//    ServiceControlManager will believe that
//    the service has stopped responding.
//
VOID ServiceStop()
{
#ifdef HAVE_THREAD
    Sig_Interupt( 1 );
#else
    sig_exit(1);
#endif
}

#endif
