/****************************************************************************
 *
 *  mkmsgf.h -- Make Message File Utility (MKMSGF) Clone
 *
 *  ========================================================================
 *
 *    Version 1.0       Michael K Greene <mike@mgreene.org>
 *                      July 2008
 *
 *  ========================================================================
 *
 *  Description: Header containing message file structures
 *
 *  Based on previous work:
 *      (C) 2002-2008 by Yuri Prokushev
 *      (C) 2001 Veit Kannegieser
 *
 *  ========================================================================
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, write to the Free Software
 *   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 ***************************************************************************/

#ifndef MKMSGF_H
#define MKMSGF_H

#include <stdint.h>

/* Basic msg file layout:

               ^
               |  Messages
               |  FILECOUNTRYINFO
               |
               |  Index to messages, each message uint16_t offset from
               |  start of file to beginning of mesasge
               |
               |  MSGHEADER
  --> start file
 */

#pragma pack(push, 1)

// Header of message file
typedef struct _MSGHEADER
{
    uint8_t magic_sign[8]; // Magic word signature
    uint8_t identifier[3]; // Identifier (SYS, DOS, NET, etc.)
    uint16_t numbermsg;    // Number of messages
    uint16_t firstmsg;     // Number of the first message
    int8_t offset16bit;    // Index table is 16-bit offsets 0 dword 1 word
    uint16_t version;      // File version 2 - New Version 0 - Old Version
    uint16_t hdroffset;    // pointer - Offset of index table - size of _MSGHEADER
    uint16_t countryinfo;  // pointer - Offset of country info block (cp)
    uint32_t extenblock;   // better desc?
    uint8_t reserved[5];   // Must be 0 (zero)
} MSGHEADER, *PMSGHEADER;

// Country Info block of message file
typedef struct _FILECOUNTRYINFO
{
    uint8_t bytesperchar;     // Bytes per char (1 - SBCS, 2 - DBCS)
    uint16_t cntyid;          // country
    uint16_t langfamilyID;    // Language family ID (As in CPI Reference)
    uint16_t langversionID;   // Language version ID (As in CPI Reference)
    uint16_t codepagesnumber; // Number of codepages - can have up to 16 cp
    uint16_t codepages[16];   // Codepages list (Max 16)
    uint8_t filename[260];    // Name of file -- CCHMAXPATH?
    uint8_t filler;           // filler byte - not used
} FILECOUNTRYINFO, *PFILECOUNTRYINFO;

// extenblocks (MSGHEADER extenblock >0)
typedef struct _EXTENBLOCKS
{
    uint8_t hdrsize;
    uint8_t numblocks;
} EXTENBLOCKS, *PEXTENBLOCKS;

// old struc
typedef struct _MSGINFO
{
    uint16_t msgnum;   // message number
    uint16_t msgindex; // offset from begin of file
} MSGINFO, *PMSGINFO;

#pragma pack(pop)

#endif
