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
 * Thread.c
 * by Kevin Gibbs <kgibbs@nlanr.net>
 *
 * Based on:
 * Thread.cpp
 * by Mark Gates <mgates@nlanr.net>
 * -------------------------------------------------------------------
 * The thread subsystem is responsible for all thread functions. It
 * provides a thread implementation agnostic interface to Iperf. If
 * threads are not available (HAVE_THREAD is undefined), thread_start
 * does not start a new thread but just launches the specified object
 * in the current thread. Everything that defines a thread of
 * execution in Iperf is contained in an thread_Settings structure. To
 * start a thread simply pass one such structure into thread_start.
 * -------------------------------------------------------------------
 * headers
 * uses
 *   <stdlib.h>
 *   <stdio.h>
 *   <assert.h>
 *   <errno.h>
 * Thread.h may include <pthread.h>
 * ------------------------------------------------------------------- */

#include "headers.h"

#include "Thread.h"
#include "Locale.h"
#include "util.h"

#include "Settings.hpp"

#include "VMContainer.h"

// Byun: Add the two definitions
#define HAVE_THREAD
#define HAVE_POSIX_THREAD

// Byun: v0_9_5 - Timeout period in seconds (FIX for UDP_TIMEOUT_PERIOD?)
#define TCP_TIMEOUT_PERIOD  90
#define UDP_TIMEOUT_PERIOD  20
#define PRELIM_TCP_TIMEOUT_PERIOD 40

#ifdef __cplusplus
extern "C" {
#endif
    
    /* -------------------------------------------------------------------
     * define static variables.
     * ------------------------------------------------------------------- */
    
    // number of currently running threads
    int thread_sNum = 0;
    // number of non-terminating running threads (ie listener thread)
    int nonterminating_num = 0;
    // condition to protect updating the above and alerting on
    // changes to above
    Condition thread_sNum_cond;
    
    // Byun: added at v0_9_5
    extern int iperf_timeout; // to indicate that the iPerf timeout happened.
    
    // Byun: added at v0_9_3
    struct thread_Settings* iOS_iPerf_thread_info[64];  // to keep the thread info to terminate at timeout
    
    // check for test phase
    extern struct video_metric VIDM;
    
    /* -------------------------------------------------------------------
     * Initialize the thread subsystems variables and set the concurrency
     * level in solaris.
     * ------------------------------------------------------------------- */
    void thread_init( ) {
        Condition_Initialize( &thread_sNum_cond );
#if defined( sun )
        /* Solaris apparently doesn't default to timeslicing threads,
         * as such we force it to play nice. This may not work perfectly
         * when _sending_ multiple _UDP_ streams.
         */
        pthread_setconcurrency (3);
#endif
    }
    
    /* -------------------------------------------------------------------
     * Destroy the thread subsystems variables.
     * ------------------------------------------------------------------- */
    void thread_destroy( ) {
        Condition_Destroy( &thread_sNum_cond );
    }
    
    /* -------------------------------------------------------------------
     * Start the specified object's thread execution. Increments thread
     * count, spawns new thread, and stores thread ID.
     * ------------------------------------------------------------------- */
    void thread_start( struct thread_Settings* thread ) {
        
        // Make sure this object has not been started already
        if ( thread_equalid( thread->mTID, thread_zeroid() ) ) {
            
            // Check if we need to start another thread before this one
            if ( thread->runNow != NULL ) {
                thread_start( thread->runNow );
            }
            
            // increment thread count
            Condition_Lock( thread_sNum_cond );
            
            // Byun: added at v0_9_3
            iOS_iPerf_thread_info[thread_sNum] = thread;
            
            thread_sNum++;
            Condition_Unlock( thread_sNum_cond );
            
#if   defined( HAVE_POSIX_THREAD )
            
            // pthreads -- spawn new thread
            if ( pthread_create( &thread->mTID, NULL, thread_run_wrapper, thread ) != 0 ) {
                WARN( 1, "pthread_create" );
                
                // decrement thread count
                Condition_Lock( thread_sNum_cond );
                thread_sNum--;
                Condition_Unlock( thread_sNum_cond );
            }
            
#elif defined( HAVE_WIN32_THREAD )
            
            // Win32 threads -- spawn new thread
            // Win32 has a thread handle in addition to the thread ID
            thread->mHandle = CreateThread( NULL, 0, thread_run_wrapper, thread, 0, &thread->mTID );
            if ( thread->mHandle == NULL ) {
                WARN( 1, "CreateThread" );
                
                // decrement thread count
                Condition_Lock( thread_sNum_cond );
                thread_sNum--;
                Condition_Unlock( thread_sNum_cond );
            }
            
#else
            
            // single-threaded -- call Run_Wrapper in this thread
            thread_run_wrapper( thread );
#endif
        }
    } // end thread_start
    

    // Byun: Added at v0_9_3
    void iOS_iPerf_thread_stop( struct thread_Settings* thread , bool notify_end) {
        
        // Make sure we have been started
        if ( ! thread_equalid( thread->mTID, thread_zeroid() ) ) {
            
            // use exit()   if called from within this thread
            // use cancel() if called from a different thread
            if ( thread_equalid( thread_getid(), thread->mTID ) ) {
                
                // Destroy the object
                print_to_console("\n\nBYUN: terminate %p using pthread_exit()\n\n", thread);
                Settings_Destroy( thread );
                
                // Exit
                pthread_exit( NULL );
            } else {
                
                // Cancel
                pthread_cancel( thread->mTID );
                
                // Destroy the object only after killing the thread
                print_to_console("\n\nBYUN: terminate %p using pthread_cancel()\n\n", thread);
                Settings_Destroy( thread );
            }
            if(notify_end) Notify_Test_End();
        }
    } // end iOS_iPerf_thread_stop
    
    
    /* -------------------------------------------------------------------
     * Stop the specified object's thread execution (if any) immediately.
     * Decrements thread count and resets the thread ID.
     * ------------------------------------------------------------------- */
    void thread_stop( struct thread_Settings* thread ) {
        
#ifdef HAVE_THREAD
        // Make sure we have been started
        if ( ! thread_equalid( thread->mTID, thread_zeroid() ) ) {
            
            // decrement thread count
            Condition_Lock( thread_sNum_cond );
            thread_sNum--;
            Condition_Signal( &thread_sNum_cond );
            Condition_Unlock( thread_sNum_cond );
            
            // use exit()   if called from within this thread
            // use cancel() if called from a different thread
            if ( thread_equalid( thread_getid(), thread->mTID ) ) {
                
                // Destroy the object
                Settings_Destroy( thread );
                
                // Exit
#if   defined( HAVE_POSIX_THREAD )
                pthread_exit( NULL );
#else // Win32
                CloseHandle( thread->mHandle );
                ExitThread( 0 );
#endif
            } else {
                
                // Cancel
#if   defined( HAVE_POSIX_THREAD )
                // Cray J90 doesn't have pthread_cancel; Iperf works okay without
#ifdef HAVE_PTHREAD_CANCEL
                pthread_cancel( thread->mTID );
#endif
#else // Win32
                // this is a somewhat dangerous function; it's not
                // suggested to Stop() threads a lot.
                TerminateThread( thread->mHandle, 0 );
#endif
                
                // Destroy the object only after killing the thread
                Settings_Destroy( thread );
            }
        }
#endif
    } // end Stop
    
    /* -------------------------------------------------------------------
     * This function is the entry point for new threads created in
     * thread_start.
     * ------------------------------------------------------------------- */
#if   defined( HAVE_WIN32_THREAD )
    DWORD WINAPI
#else
    void*
#endif
    thread_run_wrapper( void* paramPtr ) {
        struct thread_Settings* thread = (struct thread_Settings*) paramPtr;
        
        // which type of object are we
        switch ( thread->mThreadMode ) {
            case kMode_Server:
            {
                /* Spawn a Server thread with these settings */
                print_to_console("BYUN: kMode_Server will be created\n\n");
                server_spawn( thread );
            } break;
                
            case kMode_Client:
            {
                /* Spawn a Client thread with these settings */
                print_to_console("BYUN: kMode_Client will be created\n\n");
                client_spawn( thread );
                
#ifdef HAVE_POSIX_THREAD
                // detach Thread. If someone already joined it will not do anything
                // If noone has then it will free resources upon return from this
                // function (Run_Wrapper)
                pthread_detach(thread->mTID);
#endif
                
                // decrement thread count and send condition signal
                Condition_Lock( thread_sNum_cond );
                
                // Byun: added at v0_9_3
                for (int i=0; i < 64; i++)
                {
                    if (thread == iOS_iPerf_thread_info[i]) {
                        iOS_iPerf_thread_info[i] = 0;
                        break;
                    }
                }
                
                thread_sNum--;
                Condition_Signal( &thread_sNum_cond );
                Condition_Unlock( thread_sNum_cond );
                
                // Check if we need to start up a thread after executing this one
                if ( thread->runNext != NULL ) {
                    print_to_console("BYUN: WARNING 110 - It shouldn't be invoked here!!!\n\n");
                    thread_start( thread->runNext );
                }
                
                // Destroy this thread object
                Settings_Destroy( thread );
                
                print_to_console("BYUN: Client thread will exit.\n\n");
                pthread_exit(NULL); // terminate the client thread
                return 0;
                
            } break;
            case kMode_Reporter:
            {
                /* Spawn a Reporter thread with these settings */
                print_to_console("BYUN: kMode_Reporter will be created\n\n");
                reporter_spawn( thread );
            } break;
            case kMode_Listener:
            {
                // Increment the non-terminating thread count
                thread_register_nonterm();
                print_to_console("BYUN: kMode_Listener will be created\n\n");
                /* Spawn a Listener thread with these settings */
                listener_spawn( thread );
                // Decrement the non-terminating thread count
                thread_unregister_nonterm();
            } break;
            default:
            {
                FAIL(1, "Unknown Thread Type!\n", thread);
            } break;
        }
        
#ifdef HAVE_POSIX_THREAD
        // detach Thread. If someone already joined it will not do anything
        // If noone has then it will free resources upon return from this
        // function (Run_Wrapper)
        pthread_detach(thread->mTID);
#endif
        
        // decrement thread count and send condition signal
        Condition_Lock( thread_sNum_cond );

        // Byun: added at v0_9_4
        for (int i=0; i < 64; i++)
        {
            if (thread == iOS_iPerf_thread_info[i]) {
                iOS_iPerf_thread_info[i] = 0;
                break;
            }
        }

        thread_sNum--;
        Condition_Signal( &thread_sNum_cond );
        Condition_Unlock( thread_sNum_cond );
        
        // Check if we need to start up a thread after executing this one
        if ( thread->runNext != NULL ) {
            thread_start( thread->runNext );
        }
        
        // Destroy this thread object
        Settings_Destroy( thread );
        
        return 0;
    } // end run_wrapper
    
    /* -------------------------------------------------------------------
     * Wait for all thread object's execution to complete. Depends on the
     * thread count being accurate and the threads sending a condition
     * signal when they terminate.
     * ------------------------------------------------------------------- */
    void thread_joinall( void )
    {
        Condition_Lock( thread_sNum_cond );
        while ( thread_sNum > 0 )
        {
            Condition_Wait( &thread_sNum_cond );
            // sleep(1);
        }
        Condition_Unlock( thread_sNum_cond );
    } // end Joinall
    
    
    // Byun: updated at v0_9_5
    void iOS_iPerf_thread_joinall( int isUDP )
    {
        Condition_Lock( thread_sNum_cond );
        
        // Byun: v0_9_4 - thread_sNum-1, not just thread_sNum
        while ( thread_sNum-1 > 0 )
        {
            printf("^^^DEBUG: VIDM.phase: %i \n\n", VIDM.phase);
            // Condition_Wait( &thread_sNum_cond );
            if (isUDP == 0 && VIDM.phase >= 0)  // TCP measurement
            {
                Condition_TimedWait (&thread_sNum_cond, TCP_TIMEOUT_PERIOD);
            }
            else if(isUDP == 0) // Preliminary TCP test timeout
            {
                Condition_TimedWait (&thread_sNum_cond, PRELIM_TCP_TIMEOUT_PERIOD);
            }
            else
            {
                Condition_TimedWait (&thread_sNum_cond, UDP_TIMEOUT_PERIOD);
            }
            
            if (iperf_timeout != 0) // Timeout, since iperf_timeout is set to 1
            {
                print_to_console("\n\nBYUN: iOS_iPerf_thread_joinall TIMEOUT!!! with %d thread_sNum.\n\n", thread_sNum);
                
                int last;                               //
                for(last = 63; last >= 0; last--)        //  Trying to find the last element that
                    if(iOS_iPerf_thread_info[last] != 0)//  has thread info and isn't just zero
                        break;                          //
                for (int i=0; i < 64; i++)
                {
                    if (iOS_iPerf_thread_info[i] != 0)
                    {
                        // print_to_console("\n\nBYUN: terminate %p.\n\n", iOS_iPerf_thread_info[i]);
                        iOS_iPerf_thread_stop(iOS_iPerf_thread_info[i], i == last); // for the last thread, send test end
                        iOS_iPerf_thread_info[i] = 0;
                    }
                }
                thread_sNum = 0;
                char array[20] = "0";
                tcp_to_UI(array, 0);
                // Byun: v0_9_5
                // iperf_timeout = 0;
                Condition_Unlock( thread_sNum_cond );
                return;
            }
            
        }
        
        print_to_console("\n\nBYUN: iOS_iPerf_thread_joinall STILL %d thread alive.\n\n", thread_sNum);
        
        for (int i=0; i < 64; i++)
        {
            if (iOS_iPerf_thread_info[i] != 0)
            {
                // print_to_console("\n\nBYUN: terminate explicitly %p.\n\n", iOS_iPerf_thread_info[i]);
                iOS_iPerf_thread_stop(iOS_iPerf_thread_info[i], true);
                iOS_iPerf_thread_info[i] = 0;
            }
        }
        thread_sNum = 0;
        // Byun: v0_9_5
        // iperf_timeout = 0;

        Condition_Unlock( thread_sNum_cond );
    } // end iOS_iPerf_thread_joinall
    
    
    /* -------------------------------------------------------------------
     * Compare the thread ID's (inLeft == inRight); return true if they
     * are equal. On some OS's nthread_t is a struct so == will not work.
     * TODO use pthread_equal. Any Win32 equivalent??
     * ------------------------------------------------------------------- */
    int thread_equalid( nthread_t inLeft, nthread_t inRight ) {
        return(memcmp( &inLeft, &inRight, sizeof(inLeft)) == 0);
    }
    
    /* -------------------------------------------------------------------
     * Return a zero'd out thread ID. On some OS's nthread_t is a struct
     * so == 0 will not work.
     * [static]
     * ------------------------------------------------------------------- */
    nthread_t thread_zeroid( void ) {
        nthread_t a;
        memset( &a, 0, sizeof(a));
        return a;
    }
    
    /* -------------------------------------------------------------------
     * set a thread to be ignorable, so joinall won't wait on it
     * this simply decrements the thread count that joinall uses.
     * This is utilized by the reporter thread which knows when it
     * is ok to quit (aka no pending reports).
     * ------------------------------------------------------------------- */
    void thread_setignore( ) {
        Condition_Lock( thread_sNum_cond );
        thread_sNum--;
        Condition_Signal( &thread_sNum_cond );
        Condition_Unlock( thread_sNum_cond );
    }
    
    /* -------------------------------------------------------------------
     * unset a thread from being ignorable, so joinall will wait on it
     * this simply increments the thread count that joinall uses.
     * This is utilized by the reporter thread which knows when it
     * is ok to quit (aka no pending reports).
     * ------------------------------------------------------------------- */
    void thread_unsetignore( void ) {
        Condition_Lock( thread_sNum_cond );
        thread_sNum++;
        Condition_Signal( &thread_sNum_cond );
        Condition_Unlock( thread_sNum_cond );
    }
    
    /* -------------------------------------------------------------------
     * set a thread to be non-terminating, so if you cancel through
     * Ctrl-C they can be ignored by the joinall.
     * ------------------------------------------------------------------- */
    void thread_register_nonterm( void ) {
        Condition_Lock( thread_sNum_cond );
        nonterminating_num++;
        Condition_Unlock( thread_sNum_cond );
    }
    
    /* -------------------------------------------------------------------
     * unset a thread from being non-terminating, so if you cancel through
     * Ctrl-C they can be ignored by the joinall.
     * ------------------------------------------------------------------- */
    void thread_unregister_nonterm( void ) {
        Condition_Lock( thread_sNum_cond );
        if ( nonterminating_num == 0 ) {
            // nonterminating has been released with release_nonterm
            // Add back to the threads to wait on
            thread_sNum++;
        } else {
            nonterminating_num--;
        }
        Condition_Unlock( thread_sNum_cond );
    }
    
    /* -------------------------------------------------------------------
     * this function releases all non-terminating threads from the list
     * of active threads, so that when all terminating threads quit
     * the joinall will complete. This is called on a Ctrl-C input. It is
     * also used by the -P usage on the server side
     * ------------------------------------------------------------------- */
    int thread_release_nonterm( int interrupt ) {
        Condition_Lock( thread_sNum_cond );
        thread_sNum -= nonterminating_num;
        if ( thread_sNum > 1 && nonterminating_num > 0 && interrupt != 0 ) {
            fprintf( stderr, "%s", wait_server_threads );
        }
        nonterminating_num = 0;
        Condition_Signal( &thread_sNum_cond );
        Condition_Unlock( thread_sNum_cond );
        return thread_sNum;
    }
    
    /* -------------------------------------------------------------------
     * Return the number of threads currently running (doesn't include
     * active threads that have called setdaemon (aka reporter thread))
     * ------------------------------------------------------------------- */
    int thread_numuserthreads( void ) {
        return thread_sNum;
    }
    
    /*
     * -------------------------------------------------------------------
     * Allow another thread to execute. If no other threads are runable this
     * is not guarenteed to actually rest.
     * ------------------------------------------------------------------- */
    void thread_rest ( void ) {
#if defined( HAVE_THREAD )
#if defined( HAVE_POSIX_THREAD )
        // TODO add checks for sched_yield or pthread_yield and call that
        // if available
        usleep( 0 );
#else // Win32
        SwitchToThread( );
#endif
#endif
    }
    
#ifdef __cplusplus
} /* end extern "C" */
#endif

