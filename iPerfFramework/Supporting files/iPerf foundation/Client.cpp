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
 * Client.cpp
 * by Mark Gates <mgates@nlanr.net>
 * -------------------------------------------------------------------
 * A client thread initiates a connect to the server and handles
 * sending and receiving data, then closes the socket.
 * ------------------------------------------------------------------- */

#include "headers.h"
#include "Client.hpp"
#include "Thread.h"
#include "SocketAddr.h"
#include "PerfSocket.hpp"
#include "Extractor.h"
#include "delay.hpp"
#include "util.h"
#include "Locale.h"
#include "Settings.hpp"
#define SAME_TCP

extern int cnx_error;



/* -------------------------------------------------------------------
 * Store server hostname, optionally local hostname, and socket info.
 * ------------------------------------------------------------------- */

Client::Client( thread_Settings *inSettings ) {
    mSettings = inSettings;
    mBuf = NULL;

    // initialize buffer
    mBuf = new char[ mSettings->mBufLen ];
    pattern( mBuf, mSettings->mBufLen );
    if ( isFileInput( mSettings ) ) {
        if ( !isSTDIN( mSettings ) )
            Extractor_Initialize( mSettings->mFileName, mSettings->mBufLen, mSettings );
        else
            Extractor_InitializeFile( stdin, mSettings->mBufLen, mSettings );

        if ( !Extractor_canRead( mSettings ) ) {
            unsetFileInput( mSettings );
        }
    }

    // connect
	    Connect( );

    if ( isReport( inSettings ) ) {
        ReportSettings( inSettings );
        if ( mSettings->multihdr && isMultipleReport( inSettings ) ) {
            mSettings->multihdr->report->connection.peer = mSettings->peer;
            mSettings->multihdr->report->connection.size_peer = mSettings->size_peer;
            mSettings->multihdr->report->connection.local = mSettings->local;
            SockAddr_setPortAny( &mSettings->multihdr->report->connection.local );
            mSettings->multihdr->report->connection.size_local = mSettings->size_local;
        }
    }

} // end Client

/* -------------------------------------------------------------------
 * Delete memory (hostname strings).
 * ------------------------------------------------------------------- */

Client::~Client() {
    if ( mSettings->mSock != INVALID_SOCKET ) {
        int rc = close( mSettings->mSock );
        WARN_errno( rc == SOCKET_ERROR, "close" );
        mSettings->mSock = INVALID_SOCKET;
    }
#ifdef SAME_TCP
	if (mSettings-> mMode == kTest_SameTCP_TradeOff_ClientSide)
    {
        //Alex Hauser: changed timeout's tv_usec value to 1/10 of it's original value in an attempt to
        //fix the Interval Problem
        //	fprintf (stderr, "Initiating connection with server to do downstream testing\n");
        Connect();
        InitiateServer();
	}
#endif
    DELETE_ARRAY( mBuf );
} // end ~Client

const double kSecs_to_usecs = 1e6; 
const int    kBytes_to_Bits = 8; 

/* ------------------------------------------------------------------- 
 * Send data using the connected UDP/TCP socket, 
 * until a termination flag is reached. 
 * Does not close the socket. 
 * ------------------------------------------------------------------- */ 

void Client::Run( void ) {
    struct UDP_datagram* mBuf_UDP = (struct UDP_datagram*) mBuf; 
    long currLen = 0; 

    int delay_target = 0; 
    int delay = 0; 
    int adjust = 0; 

    char* readAt = mBuf;
    
    // Indicates if the stream is readable 
    bool canRead = true, mMode_Time = isModeTime( mSettings ); 

#ifdef SAME_TCP
//	fprintf (stderr,"Client side testing begins ... \n");
#endif
    // setup termination variables
    if ( mMode_Time )
    {
        //Alex Hauser: debug statement to test if mMode_Time is true
        // printf("\n is mMode_Time == true\n");
        
        mEndTime.setnow();
        mEndTime.add( mSettings->mAmount / 100.0 );
        
        //Alex Hauser: debug statement to ascertain the value of End Time in order
        //to try to further diagnose the Interval problem
        // printf("\nEnd Time: %f\n",mEndTime.get());
        
       // mEndTime.add( 1000.0);
    }

    if ( isUDP( mSettings ) )
    {
        // printf("is UPD(mSettings)");
        
        // Due to the UDP timestamps etc, included 
        // reduce the read size by an amount 
        // equal to the header size
    
        // compute delay for bandwidth restriction, constrained to [0,1] seconds 
        #ifdef SAME_TCP
        //	fprintf (stderr,"Client in UDP mode???? ... \n");
        #endif
        delay_target = (int) ( mSettings->mBufLen * ((kSecs_to_usecs * kBytes_to_Bits) 
                                                     / mSettings->mUDPRate) ); 
        if ( delay_target < 0  || 
             delay_target > (int) 1 * kSecs_to_usecs )
        {
            //Alex Hauser: changed timeout's tv_usec value to 1/10 of it's original value in an attempt to
            //fix the Interval Problem
            fprintf( stderr, warn_delay_large, delay_target / kSecs_to_usecs );
            delay_target = (int) kSecs_to_usecs * 1; 
        }
        if ( isFileInput( mSettings ) )
        {
            if ( isCompat( mSettings ) )
            {
                Extractor_reduceReadSize( sizeof(struct UDP_datagram), mSettings );
                readAt += sizeof(struct UDP_datagram);
            }
            else
            {
                Extractor_reduceReadSize( sizeof(struct UDP_datagram) +
                                          sizeof(struct client_hdr), mSettings );
                readAt += sizeof(struct UDP_datagram) +
                          sizeof(struct client_hdr);
            }
        }
    }

    ReportStruct *reportstruct = NULL;

    // InitReport handles Barrier for multiple Streams
    mSettings->reporthdr = InitReport( mSettings );
    reportstruct = new ReportStruct;
    reportstruct->packetID = 0;

    lastPacketTime.setnow();
    
    do
    {

        // Test case: drop 17 packets and send 2 out-of-order: 
        // sequence 51, 52, 70, 53, 54, 71, 72 
        //switch( datagramID ) { 
        //  case 53: datagramID = 70; break; 
        //  case 71: datagramID = 53; break; 
        //  case 55: datagramID = 71; break; 
        //  default: break; 
        //} 
        gettimeofday( &(reportstruct->packetTime), NULL );

        if ( isUDP( mSettings ) )
        {
            // printf("Got past '(isUDP(mSettings))' check");  // Comment by Byun
            // store datagram ID into buffer 
            mBuf_UDP->id      = htonl( (reportstruct->packetID)++ ); 
            mBuf_UDP->tv_sec  = htonl( reportstruct->packetTime.tv_sec ); 
            mBuf_UDP->tv_usec = htonl( reportstruct->packetTime.tv_usec );

            // delay between writes 
            // make an adjustment for how long the last loop iteration took 
            // TODO this doesn't work well in certain cases, like 2 parallel streams
            // Jack: Changed the long cast to an integer cast, to silence the conversion precision loss warning
            adjust = delay_target + (int)lastPacketTime.subUsec( reportstruct->packetTime );
            lastPacketTime.set( reportstruct->packetTime.tv_sec, 
                                reportstruct->packetTime.tv_usec ); 

            if ( adjust > 0  ||  delay > 0 )
            {
                delay += adjust;
            }
        }

        // Read the next data block from 
        // the file if it's file input 
        if ( isFileInput( mSettings ) ) {
            Extractor_getNextDataBlock( readAt, mSettings ); 
            canRead = Extractor_canRead( mSettings ) != 0; 
        } else
            canRead = true; 

        // perform write 
        currLen = write( mSettings->mSock, mBuf, mSettings->mBufLen ); 
        if ( currLen < 0 )
        {
            //Alex Hauser: debug statement to test when currLen is less than 0,
            //which suggests a serious error if present.
            // printf("currLen is less than 0");
            WARN_errno( currLen < 0, "write2" );
            cnx_error = 1;
            break;

        }

        // report packets
        // Jack: Changed the long cast to an integer cast, to silence the conversion precision loss warning
        reportstruct->packetLen = (int)currLen;
        
        
        //reportstruct->packetTime.tv_sec+=delay;
        
        //Alex Hauser: these two statements are an attempt to fix the
        //Interval problem by hardcoding a delay into the system, since
        //the source of the problem appears to be a negative or near-zero end-time
        //for each packet.
        //Does not currently fully fix the problem, but stops the infinite flood of erronous messages if the
        //interval system is enabled, instead sending a single report.
        //Currently planning to experiment further with the packetTime data within reportstruct to attempt
        //to fix the problem
       // reportstruct->packetTime.tv_sec=delay;
       // reportstruct->packetTime.tv_usec = delay * kSecs_to_usecs;
        
        ReportPacket( mSettings->reporthdr, reportstruct );
        
        if ( delay > 0 )
        {
            //Alex Hauser: this was initially disabled in the original version of
            //SolisiPerf but has been fixed and reenabled.
            delay_loop(delay);
        }
        
        if ( !mMode_Time )
        {
            mSettings->mAmount -= currLen;
        }

    } while(!(sInterupted  ||
                 (mMode_Time   &&  mEndTime.before( reportstruct->packetTime ))  ||
                 (!mMode_Time  &&  0 >= mSettings->mAmount)) && canRead);

    // stop timing
    gettimeofday( &(reportstruct->packetTime), NULL );
    CloseReport( mSettings->reporthdr, reportstruct );

    if ( isUDP( mSettings ))
    {
        // printf("is UDP");
        
        
        // send a final terminating datagram
        // Don't count in the mTotalLen. The server counts this one, 
        // but didn't count our first datagram, so we're even now. 
        // The negative datagram ID signifies termination to the server. 
    
        // store datagram ID into buffer 
        mBuf_UDP->id      = htonl( -(reportstruct->packetID)  ); 
        mBuf_UDP->tv_sec  = htonl( reportstruct->packetTime.tv_sec ); 
        mBuf_UDP->tv_usec = htonl( reportstruct->packetTime.tv_usec ); 

        if(isMulticast(mSettings))
        {
            write( mSettings->mSock, mBuf, mSettings->mBufLen ); 
        }
        else
        {
            write_UDP_FIN();
        }
    }
    DELETE_PTR(reportstruct);
    EndReport( mSettings->reporthdr );
} 
// end Run

void Client::InitiateServer() {
    if ( !isCompat( mSettings ) ) {
        int currLen;
        client_hdr* temp_hdr;
        if ( isUDP( mSettings ) ) {
            UDP_datagram *UDPhdr = (UDP_datagram *)mBuf;
            temp_hdr = (client_hdr*)(UDPhdr + 1);
        } else {
            temp_hdr = (client_hdr*)mBuf;
        }
        Settings_GenerateClientHdr( mSettings, temp_hdr );
#ifdef SAME_TCP
	if (mSettings -> mMode == kTest_SameTCP_TradeOff)
	{
		mSettings -> mMode = kTest_SameTCP_TradeOff_ClientSide;
        
        //Alex Hauser: Disabled fprintf as this statement glitches on iOS operating system
		//fprintf (stderr,"Changing mMode to ClientSide\n");
	}
#endif
        if ( !isUDP( mSettings ) ) {
            // Jack: Changed the long cast to an integer cast, to silence the conversion precision loss warning
            currLen = (int)send( mSettings->mSock, mBuf, sizeof(client_hdr), 0 );
            if ( currLen < 0 )
            {
                //Alex Hauser: Disabled fprintf as this statement glitches on iOS operating system
                //fprintf (stderr,"currLen is less than 0\n");
                WARN_errno( currLen < 0, "write1" );
                cnx_error = 1;
            }
        }
    }
}

/* -------------------------------------------------------------------
 * Setup a socket connected to a server.
 * If inLocalhost is not null, bind to that address, specifying
 * which outgoing interface to use.
 * ------------------------------------------------------------------- */

void Client::Connect( ) {
    int rc;
    SockAddr_remoteAddr( mSettings );

    assert( mSettings->inHostname != NULL );

    // create an internet socket
    int type = ( isUDP( mSettings )  ?  SOCK_DGRAM : SOCK_STREAM);

    int domain = (SockAddr_isIPv6( &mSettings->peer ) ? 
#ifdef HAVE_IPV6
                  AF_INET6
#else
                  AF_INET
#endif
                  : AF_INET);
#ifdef SAME_TCP
if (mSettings-> mMode != kTest_SameTCP_TradeOff_ServerSide) {
#endif
    mSettings->mSock = socket( domain, type, 0 );
    WARN_errno( mSettings->mSock == INVALID_SOCKET, "socket" );
#ifdef SAME_TCP
}
#endif

    SetSocketOptions( mSettings );


    SockAddr_localAddr( mSettings );
    if ( mSettings->mLocalhost != NULL ) {
        // bind socket to local address
        rc = bind( mSettings->mSock, (sockaddr*) &mSettings->local, 
                   SockAddr_get_sizeof_sockaddr( &mSettings->local ) );
        WARN_errno( rc == SOCKET_ERROR, "bind" );
    }

#ifdef SAME_TCP
if (mSettings-> mMode != kTest_SameTCP_TradeOff_ServerSide) {
#endif
    // connect socket
    rc = connect( mSettings->mSock, (sockaddr*) &mSettings->peer, 
                  SockAddr_get_sizeof_sockaddr( &mSettings->peer ));
    

    if((rc == SOCKET_ERROR) && (isUDP( mSettings ))) {
        WARN_errno( rc == SOCKET_ERROR, "connect" );
        cnx_error = 1;
    }
    else if((rc == SOCKET_ERROR) && (!isUDP( mSettings ))) {
        WARN_errno( rc == SOCKET_ERROR, "connect" );
        cnx_error = 1;
    }
    
#ifdef SAME_TCP
} else {
//	fprintf (stderr, "Connecting to the same TCP pipe left by the Listener thread without using connect\n");
}
#endif

    getsockname( mSettings->mSock, (sockaddr*) &mSettings->local, 
                 &mSettings->size_local );
    getpeername( mSettings->mSock, (sockaddr*) &mSettings->peer,
                 &mSettings->size_peer );
} // end Connect

/* ------------------------------------------------------------------- 
 * Send a datagram on the socket. The datagram's contents should signify 
 * a FIN to the application. Keep re-transmitting until an 
 * acknowledgement datagram is received. 
 * ------------------------------------------------------------------- */ 

void Client::write_UDP_FIN( )
{
    // printf("write_UDP_FIN()");
    int rc; 
    fd_set readSet; 
    struct timeval timeout; 

    int count = 0; 
    while ( count < 10 )
    {
        count++; 

        // write data 
        write( mSettings->mSock, mBuf, mSettings->mBufLen ); 

        // wait until the socket is readable, or our timeout expires 
        FD_ZERO( &readSet ); 
        FD_SET( mSettings->mSock, &readSet ); 
        timeout.tv_sec = 2;
		//timeout.tv_usec = 250000; // quarter second, 250 ms
		timeout.tv_usec = 2500; // 2.5 sec, 2500 ms--by CalSPEED
        

        rc = select( mSettings->mSock+1, &readSet, NULL, NULL, &timeout ); 
        FAIL_errno( rc == SOCKET_ERROR, "select", mSettings ); 

        if ( rc == 0 )
        {
            // select timed out 
            continue; 
        }
        else
        {
            // socket ready to read
            // Jack: Changed the long cast to an integer cast, to silence the conversion precision loss warning
            rc = (int)read( mSettings->mSock, mBuf, mSettings->mBufLen );
            WARN_errno( rc < 0, "read" );
    	    if ( rc < 0 )
            {
                break;
            }
            else if ( rc >= (int) (sizeof(UDP_datagram) + sizeof(server_hdr)) )
            {
                ReportServerUDP( mSettings, (server_hdr*) ((UDP_datagram*)mBuf + 1) );
            }

            return; 
        } 
    } 

    //Alex Hauser: changed timeout's tv_usec value to 1/10 of it's original value in an attempt to
    //fix the Interval Problem
    fprintf( stderr, warn_no_ack, mSettings->mSock, count );
    
    // Byun: v0_9_6 - Put a UDP no ack warning message on the test file
    warn_UDP_ack( mSettings->mSock, count );
    
    udp_result_to_LoggingWrapper(0.0, 100);//no jitter, and 100% loss
    
} 
// end write_UDP_FIN 
