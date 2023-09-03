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
    uint8_t magic[8];        // Magic word signature
    uint8_t identifier[3];   // Identifier (SYS, DOS, NET, etc.)
    uint16_t msgnumber;      // Number of messages
    uint16_t firstmsgnumber; // Number of the first message
    int8_t offset16bit;      // Index table is 16-bit offsets 0 uint32_t / 1 uint16_t
    uint16_t version;        // File version 2 - New Version 0 - Old Version
    uint16_t indextaboffset; // pointer - Offset of index table - size of _MSGHEADER
    int8_t countryinfo;      // pointer - Offset of country info block
    int16_t nextcoutryinfo;
    uint8_t reserved[8]; // Must be 0 (zero)
} MSGHEADER, *PMSGHEADER;

// Header of message file
typedef struct _MSGHEADER1
{
    uint8_t magic_sig[8];  // Magic word signature
    uint8_t identifier[3]; // Identifier (SYS, DOS, NET, etc.)
    uint16_t numbermsg;    // Number of messages
    uint16_t firstmsg;     // Number of the first message
    int8_t offset16bit;    // Index table index uint16 == 1 or uint32 == 0
    uint16_t version;      // File version 2 - New Version 0 - Old Version
    uint16_t hdroffset;    // pointer - Offset of index table - size of _MSGHEADER
    uint16_t countryinfo;  // pointer - Offset of country info block (cp)
    uint32_t extenblock;   // pointer to ext block - 0 if none
    uint8_t reserved[5];   // Must be 0 (zero)
} MSGHEADER1, *PMSGHEADER1;

// Country Info block of message file
typedef struct _FILECOUNTRYINFO
{
    uint8_t bytesperchar;     // Bytes per char (1 - SBCS, 2 - DBCS)
    uint16_t reserved;        // Not known
    uint16_t langfamilyID;    // Language family ID (As in CPI Reference)
    uint16_t langversionID;   // Language version ID (As in CPI Reference)
    uint16_t codepagesnumber; // Number of codepages
    uint16_t codepages[16];   // Codepages list (Max 16)
    uint8_t filename[260];    // Name of file
    uint8_t filler;           // filler byte - not used
} FILECOUNTRYINFO, *PFILECOUNTRYINFO;

// Country Info block of message file
typedef struct _FILECOUNTRYINFO1
{
    uint8_t bytesperchar;         // Bytes per char (1 - SBCS, 2 - DBCS)
    uint16_t country;             // ID country
    uint16_t langfamilyID;        // Language family ID (As in CPI Reference)
    uint16_t langversionID;       // Language version ID (As in CPI Reference)
    uint16_t codepagesnumber;     // Number of codepages
    uint16_t codepages[16];       // Codepages list (Max 16)
    uint8_t filename[CCHMAXPATH]; // Name of file
    uint8_t filler;               // filler byte - not used
} FILECOUNTRYINFO1, *PFILECOUNTRYINFO1;

// extended header block
typedef struct _EXTHDR
{
    uint16_t hdrlen;    // length of ???
    uint16_t numblocks; // number of additional FILECOUNTRYINFO blocks
} EXTHDR, *PEXTHDR;

typedef struct _MSGINFO
{
    uint16_t msgnum;   // message number
    uint16_t msgindex; // offset from begin of file
} MSGINFO, *PMSGINFO;

typedef struct _MSGINFOL
{
    uint16_t msgnum;   // message number
    uint32_t msgindex; // offset from begin of file
} MSGINFOL, *PMSGINFOL;

#pragma pack(pop)

// Header of message file
typedef struct _MESSAGEINFO
{
    // mkmsgd options
    char infile[_MAX_PATH]; // input filename
    char indrive[_MAX_DRIVE];
    char indir[_MAX_DIR];
    char infname[_MAX_FNAME];
    char inext[_MAX_EXT];

    char outfile[_MAX_PATH]; // output filename

    uint8_t verbose; // how much to see?
    // compile/decompile info
    uint8_t identifier[3];        // Identifier (SYS, DOS, NET, etc.)
    uint16_t numbermsg;           // Number of messages
    uint16_t firstmsg;            // Number of the first message
    int8_t offsetid;              // Index table index uint16 == 1 or uint32 == 0
    uint16_t version;             // File version 2 - New Version 0 - Old Version
    uint16_t hdroffset;           // pointer - Offset of index table - size of _MSGHEADER
    uint16_t countryinfo;         // pointer - Offset of country info block (cp)
    uint32_t extenblock;          // better desc?
    uint8_t reserved[5];          // blank bytes?
    uint8_t bytesperchar;         // Bytes per char (1 - SBCS, 2 - DBCS)
    uint16_t country;             // ID country
    uint16_t langfamilyID;        // Language family ID (As in CPI Reference)
    uint16_t langversionID;       // Language version ID (As in CPI Reference)
    uint16_t codepagesnumber;     // Number of codepages
    uint16_t codepages[16];       // Codepages list (Max 16)
    uint8_t filename[CCHMAXPATH]; // Name of file
    uint16_t extlength;           // length of ???
    uint16_t extnumblocks;        // number of additional sub FILECOUNTRYINFO blocks
    uint16_t indexoffset;         // okay dup of hdroffset
    uint16_t indexsize;           // size in bytes of index
    uint32_t msgoffset;           // offset to start of messages
    uint32_t msgfinalindex;       // offset to end of messages
    uint16_t msgstartline;        // start line for compile

} MESSAGEINFO;

// mkmsgf header signature - a valid MSG file alway starts with
// these 8 bytes 0xFF MKMSGF 0x00
char signature[] = {0xFF, 0x4D, 0x4B, 0x4D, 0x53, 0x47, 0x46, 0x00};

#endif
