/****************************************************************************
 *
 *  mkmsgf.c -- Make Message File Utility (MKMSGF) Clone
 *
 *  ========================================================================
 *
 *    Version 1.1       Michael K Greene <mikeos2@gmail.com>
 *                      September 2023
 *
 *  ========================================================================
 *
 *  Description: Simple clone of the mkmsgf tool.
 *
 *  July 2008 Version 1.0 : Michael K Greene
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

/*
   26 July 2008  Things not supported:
       - DBCS
       - options A and C 
*/

#define INCL_DOSNLS /* National Language Support values */

#include <os2.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <io.h>
#include <fcntl.h>
#include <sys\stat.h>
#include <unistd.h>
#include <malloc.h>
#include "mkmsgf.h"
#include "mkmsgerr.h"
#include "version.h"

int setupheader(MESSAGEINFO *messageinfo);
void displayinfo(MESSAGEINFO *messageinfo);
int writefile(MESSAGEINFO *messageinfo);
int writeheader(MESSAGEINFO *messageinfo);
int DecodeLangOpt(char *dargs, MESSAGEINFO *messageinfo);

// ouput display/helper functions
void usagelong(void);
void prgheading(void);
void helpshort(void);
void helplong(void);
void ProgError(int exnum, char *dispmsg);
void DumpMsgInfo(MESSAGEINFO *messageinfo);

// keeping this global so I don't have
// to change more
uint8_t prgheaddisp = 0;

int main(int argc, char *argv[])
{
    int rc = 0;
    int ch = 0; // getopt variable

    // input/output file names and options
    // uint8_t os2ldr = 0;           // here but not used
    uint8_t ibm_format_input = 0; // 1= IBM compatabile input args
    uint8_t outfile_provided = 0; // output file in args

    // getopt options
    uint8_t verbose = 0;   // verbose output
    uint8_t dispquiet = 0; // quiet all display - unless error
    uint8_t proclang = 0;  // lang opt processed

    MESSAGEINFO messageinfo; // holds all the info
    messageinfo.langfamilyID = 0;
    messageinfo.langversionID = 0;
    messageinfo.bytesperchar = 1;

    // these I found in the disassembled code, here for reference 
    // but not used - just for reference
    // uint8_t *includepath = getenv("INCLUDE");
    // uint8_t *mkmsgfprog = getenv("MKMSGF_PROG");
    // if (mkmsgfprog != NULL)
    //    if (!strncmp(mkmsgfprog, "OS2LDR", 6))
    //        os2ldr = 1;

    // no args - print usage and exit
    if (argc == 1)
    {
        prgheading(); // display program heading
        helpshort();
        exit(0);
    }

    /* *********************************************************************
     * The following is to just keep the input options getopt and IBM mkmsgf
     * compatable : MKMSGF infile[.ext] outfile[.ext] [/V]
     * why? Because using getopt so it does not have to match old format
     */

    // is the input file first? yes, make compatable with IBM program
    // so if the first option does not start with / or - then assume it
    // is a filename
    if ((*argv[1] != '-') && (*argv[1] != '/')) // first arg prefix - or / ?
    {
        strncpy(messageinfo.infile, argv[optind], strlen(argv[optind]));
        optind++;

        ++ibm_format_input; // set ibm format

        // we know IBM format so check for output file
        if (argc > 2)
        {
            if ((*argv[2] != '-') && (*argv[2] != '/')) // first arg prefix - or / ?
            {
                strncpy(messageinfo.outfile, argv[optind], strlen(argv[optind]));
                optind++;

                ++outfile_provided; // have output file
            }
        }
    }

    // just cuz - zero out a couple vars
    messageinfo.codepagesnumber = 0;

    // Get program arguments using getopt()
    while ((ch = getopt(argc, argv, "d:D:p:P:l:L:VvHhI:i:AaCcq")) != -1)
    {
        switch (ch)
        {
        case 'd':
        case 'D':
            ProgError(MKMSG_GETOPT_ERROR, "MKMSGF: Sorry, DBCS not supported");
            break;

        case 'p':
        case 'P':
            if (messageinfo.codepagesnumber < 16)
            {
                messageinfo.codepages[messageinfo.codepagesnumber++] = atoi(optarg);
            }
            else
                ProgError(MKMSG_GETOPT_ERROR, "MKMSGF: More than 16 codepages entered");
            break;

        case 'l':
        case 'L':
            // only going to process first L option - only one allowed
            if (proclang)
                ProgError(MKMSG_GETOPT_ERROR, "MKMSGF: Syntax error L option");
            proclang = DecodeLangOpt(optarg, &messageinfo);
            break;

        case 'v':
        case 'V':
            if (!verbose)
                ++verbose;
            break;

        case '?':
        case 'h':
        case 'H':
            prgheading();
            usagelong();
            exit(0);
            break;

            // Undocumented IBM flags - here but not used

        case 'i': // include path, I think only for A and C
        case 'I':
        case 'a': // the real mkmsgf outputs asm file
        case 'A':
        case 'c': // the real mkmsgf outputs C file
        case 'C':
            ProgError(MKMSG_GETOPT_ERROR, "MKMSGF: A, C, and I option not supported");
            break;

        // my added option
        case 'q':
        case 'Q':
            if (!dispquiet)
                ++dispquiet;
            break;

        default:
            ProgError(MKMSG_GETOPT_ERROR, "MKMSGF: Syntax error unknown option");
            break;
        }
    }

    // quiet flag - cancels verbose
    if (dispquiet)
        --verbose;

    // check for input file - getopt compatable cmd line
    // we either have in/out files or it is error
    if ((argc == optind) && !ibm_format_input)
        ProgError(MKMSG_NOINPUT_ERROR, "MKMSGF: no input file");

    // if ibm_format_input is false then using new format
    // so we need to get input file and maybe the output file
    if (!ibm_format_input)
    {
        strncpy(messageinfo.infile, argv[optind], strlen(argv[optind]));
        optind++;

        if (argc != optind)
        {
            strncpy(messageinfo.outfile, argv[optind], strlen(argv[optind]));
            optind++;

            ++outfile_provided; // have output file
        }
    }

    /* 1. Check exist input file
     * 2. Split the input file parts
     * 3. If out output file, generate out file name
     */

    // setup and check the input / output files
    if (access(messageinfo.infile, F_OK) != 0)
        ProgError(MKMSG_INPUT_ERROR, "MKMSGF: Input file not found");

    // splitup input file
    _splitpath(messageinfo.infile,
               messageinfo.indrive,
               messageinfo.indir,
               messageinfo.infname,
               messageinfo.inext);

    if (!outfile_provided)
    {
        for (int x = 0; x < _MAX_PATH; x++)
            messageinfo.outfile[x] = 0x00;
        sprintf(messageinfo.outfile, "%s%s", messageinfo.infname, ".msg");
    }
    // check input == output file
    if (!strcmp(messageinfo.infile, messageinfo.outfile))
        ProgError(1, "MKMSGF: Input file same as output file");

    // ************ done with args ************

    // decompile header/ input file info
    rc = setupheader(&messageinfo);
    if (rc != 0)
    {
        printf("RC: %d\n\n", rc);
        exit(rc);
    }

    DumpMsgInfo(&messageinfo);
    // displayinfo(&messageinfo);

    rc = writeheader(&messageinfo);
    if (rc != 0)
    {
        printf("RC: %d\n\n", rc);
        exit(rc);
    }

    rc = writefile(&messageinfo);
    if (rc != 0)
    {
        printf("RC: %d\n\n", rc);
        exit(rc);
    }

    exit(0);
}

/*************************************************************************
 * Function:  setupheader( )
 *
 * Gets and stores header info in MESSAGEINFO structure
 *
 * 1. Open input file
 * 2. Read past comments
 * 3. Get identifer and save file read position
 * 1. Get start message number
 * 2. Get number of messages
 * 3. determine index pointer and size uint8/uint32
 *
 * Return:    returns error code or 0 for all good
 *************************************************************************/

int setupheader(MESSAGEINFO *messageinfo)
{
    size_t buffer_size = 0;
    char *read_buffer = NULL;
    char msgnum[5] = {0};
    int first = 1;

    messageinfo->msgstartline = 0;

    // open input file
    FILE *fpi = fopen(messageinfo->infile, "rb");
    if (fpi == NULL)
        return (MKMSG_OPEN_ERROR);

    // get identifer and save, keep track of identifer line
    // number
    while (TRUE)
    {
        size_t n = 0;
        char *line = NULL;

        getline(&line, &n, fpi);

        if (line[0] != ';')
        {
            if (strlen(line) > 5) // identifer (3) + 0x0D 0x0A (2)
                exit(99);
            messageinfo->identifier[0] = line[0];
            messageinfo->identifier[1] = line[1];
            messageinfo->identifier[2] = line[2];

            fgetpos(fpi, &messageinfo->msgstartline);
            break;
        }
    }

    // make sure number of messages is 0
    messageinfo->numbermsg = 0;

    // Get message start number and number of messages
    while (TRUE)
    {
        // this should be the first message line
        getline(&read_buffer, &buffer_size, fpi);

        // if end of file get out of loop
        if (feof(fpi))
            break;

        if (strncmp(messageinfo->identifier, read_buffer, 3) == 0)
        {
            messageinfo->numbermsg++;

            if (first) // first message - get start number
            {
                first = 0;
                sprintf(msgnum, "%c%c%c%c",
                        read_buffer[3],
                        read_buffer[4],
                        read_buffer[5],
                        read_buffer[6]);

                messageinfo->firstmsg = atoi(msgnum);
            }
        }
    }

    fclose(fpi);
    free(read_buffer);

    // calculate whether to use uint16 or uint32 for index
    int handle = open(messageinfo->infile, O_RDONLY | O_TEXT);
    if (handle == -1)
        return (98);
    else
    {
        if (_filelength(handle) <= 50000) // using 50K as pointer tripwire
            messageinfo->offsetid = 1;
        else
            messageinfo->offsetid = 0;
        close(handle);
    }
    // size in bytes of index
    if (messageinfo->offsetid)
        messageinfo->indexsize = messageinfo->numbermsg * 2;
    else
        messageinfo->indexsize = messageinfo->numbermsg * 4;

    // assign header values for standard v2 MSG file
    messageinfo->version = 0x0002;                     // set version
    messageinfo->hdroffset = 0x001F;                   // header offset
    messageinfo->indexoffset = messageinfo->hdroffset; // okay dup of hdroffset
    messageinfo->reserved[0] = 0x4D;                   // put this in to mark MKG clone compiled
    messageinfo->reserved[1] = 0x4B;
    messageinfo->reserved[2] = 0x47;
    messageinfo->reserved[3] = 0x00;
    messageinfo->reserved[4] = 0x00;

    // hdrsize/offset + the size of index will locate the country info
    messageinfo->countryinfo = messageinfo->hdroffset +
                               messageinfo->indexsize;

    // messages start after the FILECOUNTRYINFO block
    messageinfo->msgoffset = messageinfo->countryinfo +
                             sizeof(FILECOUNTRYINFO);

    // remains 0 for now
    messageinfo->extenblock = 0;

    // TEMP stuff
    strncpy(messageinfo->filename,
            messageinfo->outfile,
            strlen(messageinfo->outfile));
    messageinfo->country = 0;

    return (0);
}

/*************************************************************************
 * Function:  writefile( )
 *
 * Reads in all the MSG file info and stores in MESSAGEINFO structure
 *
 * 1 Open input file in read and out put file in update mode
 * 2 Allocate index and read buffer
 * 3 Set input and output file positions
 * 4 Set index pointer based on uint8/uint32 sizes
 * 5 *** start main loop ***
 * 5.1 Clear read buffer
 * 5.2 Get current read poistion and store in index
 * 5.3 Read in message line
 * 5.4 Check for comment - if true read next line -> 5.1
 * 5.5 Line starts with msg ID? Yes new message else -> 5.9
 * 5.6 Check if valid msg type - E, I, W, H, P, ? --> error if not
 * 5.7 Increment message tracking number
 * 5.8.1 Check for ? message if true then generate full ? message to save
 *     time else process E, I, W, H, P msg types and set scratch pointer
 * 5.8.2.1 Check for the mandatory space after : exit if not present
 * 5.8.2.2 Move msg type to space and set scratch pointer 
 * 5.9 Continuation line -- set scratch pointer
 *
 * 6 Get message length
 * 7 Check/fix 0x0D 0x0A ending of line
 * 8 Check and fix for %0 lines
 * 9 Write message line to output file
 * ** end main loop
 * 10 Seek to index start and write index
 * 
 * 
 * Return:    returns error code or 0 for all good
 *************************************************************************/

int writefile(MESSAGEINFO *messageinfo)
{
    // open input file
    FILE *fpi = fopen(messageinfo->infile, "rb");
    if (fpi == NULL)
        return (MKMSG_OPEN_ERROR);

    // write output file open for append
    FILE *fpo = fopen(messageinfo->outfile, "r+b");
    if (fpo == NULL)
        return (MKMSG_OPEN_ERROR);

    // buffer to read in index - this reserves memory of the
    // size calculated earlier to hold the index which is
    // dumped to the file at end of message write
    char *index_buffer = (char *)calloc(messageinfo->indexsize, sizeof(char));
    if (index_buffer == NULL)
        return (MKMSG_MEM_ERROR5);

    // buffer to read in a message - use a 256 byte buffer which
    // is overkill but not a big deal - I do not expect lines >256
    // in length
    size_t read_buff_size = 0;
    char *read_buffer = (char *)calloc(256, sizeof(char));
    if (read_buffer == NULL)
        return (MKMSG_MEM_ERROR6);

    // return to previous position
    fsetpos(fpi, &messageinfo->msgstartline); // input after id line
    fsetpos(fpo, &messageinfo->msgoffset);    // move to start msg area

    int msg_num_check = 0;
    int current_msg_len = 0;
    char *readptr = NULL;
    fpos_t index_position;

    // index pointers
    uint16_t *small_index = NULL; // used if index pointers uint16
    uint32_t *large_index = NULL; // used if index pointers uint32

    // pick the pointer based on index uint16 or uint32
    if (messageinfo->offsetid)
        small_index = (uint16_t *)index_buffer;
    else
        large_index = (uint32_t *)index_buffer;

    while (TRUE)
    {
        // clear the read_buffer -- set all to 0x00 this will
        // give me a clean strlen return
        memset(read_buffer, 0x00, _msize(read_buffer));

        // get current position in outfile -- onentry will be
        // set to first message after fsetpos above
        fgetpos(fpo, &index_position);

        // handle the uint16 and uint32 index differences
        if (messageinfo->offsetid)
            small_index[msg_num_check] = (uint16_t)index_position;
        else
            large_index[msg_num_check] = (uint32_t)index_position;

        // here is the line read in
        getline(&read_buffer, &read_buff_size, fpi);
        if (feof(fpi))
            break;

        // find message start - skip comments
        // this is the main loop if not a comment line
        if (read_buffer[0] != ';')
        {
            // check if ID which indicates message start
            if (strncmp(messageinfo->identifier, read_buffer, 3) == 0)
            {
                // First check - is the message type valid
                if (read_buffer[7] != 'E' && read_buffer[7] != 'H' &&
                    read_buffer[7] != 'I' && read_buffer[7] != 'P' &&
                    read_buffer[7] != 'W' && read_buffer[7] != '?')
                {
                    fclose(fpi);
                    fclose(fpo);
                    free(read_buffer);
                    free(index_buffer);
                    ProgError(1, "MKMSGF: Bad message type."); // fix error
                }

                // keep track of messages processed
                msg_num_check += 1;

                // shortcut and make sure the format is correct
                // for ? messages
                if (read_buffer[7] == '?')
                {
                    memset(read_buffer, 0x00, _msize(read_buffer));
                    read_buffer[0] = '?';
                    read_buffer[1] = 0x0D;
                    read_buffer[2] = 0x0A;
                    read_buffer[3] = 0x00;

                    readptr = read_buffer;
                }
                else
                {
                    // check if followed instructions with a space after colon
                    // I assume this was why (maybe not) -- just copy the ID
                    // to the space position and change pointer to the new start
                    if (read_buffer[9] != 0x20)
                        ProgError(1, "MKMSGF: Bad message type."); // fix error
                    else
                    {
                        // move message type to front of message
                        // and set buffer position
                        read_buffer[9] = read_buffer[7];
                        readptr = &read_buffer[9];
                    }
                }
            }
            else // no ID - continues previous line
            {
                // this is a continuation line so just
                // set the readptr
                readptr = read_buffer;
            }

            current_msg_len = strlen(readptr);

            // Second check - check and setup correct message ending
            // - the message ending needs to be 0x0D 0x0A, if the text
            // input file was done in a modern text editor the ending
            // is probably just 0x0A so add 0x0D 0x0A 0x00

            if (readptr[(current_msg_len - 1)] != 0x0A &&
                readptr[(current_msg_len - 2)] != 0x0D)
            {
                readptr[(current_msg_len - 1)] = 0x0D;
                readptr[(current_msg_len)] = 0x0A;
                readptr[(current_msg_len + 1)] = 0x00;

                // new length
                current_msg_len = strlen(readptr);
            }

            // At this point the message is ready in reference to where
            // readptr points and each line ends 0x0D 0x0A 0x00

            // Third and final check - fix end if it is a %0 line
            // if ends in [ % 0 0x0D 0x0A 0x00] remove all four
            // poistions and make 0x00 - all four just as a easy
            // way to spot problems in a hex dump
            if (readptr[(current_msg_len - 3)] == '0' &&
                readptr[(current_msg_len - 4)] == '%')
            {
                readptr[(current_msg_len - 1)] = 0x00;
                readptr[(current_msg_len - 2)] = 0x00;
                readptr[(current_msg_len - 3)] = 0x00;
                readptr[(current_msg_len - 4)] = 0x00;

                // new length -- up to first 0x00
                current_msg_len = strlen(readptr);
            }

            // write out the current message
            fwrite(readptr, sizeof(char), current_msg_len, fpo);
        }
    }

    // position to index start and write index -- I could
    // used fwrite - just decided to write index like this:
    fseek(fpo, messageinfo->indexoffset, SEEK_SET);
    for (int x = 0; x < messageinfo->indexsize; x++)
        fputc(index_buffer[x], fpo);

    printf("Done\n");

    // close up and get out
    fclose(fpo);
    fclose(fpi);
    free(read_buffer);
    free(index_buffer);

    return (0);
}

/* writeheader( )
 *
 *
 */

int writeheader(MESSAGEINFO *messageinfo)
{
    MSGHEADER *msgheader = NULL;
    FILECOUNTRYINFO *cntryheader = NULL;

    // write output file open for append
    FILE *fpo = fopen(messageinfo->outfile, "wb");
    if (fpo == NULL)
        return (MKMSG_OPEN_ERROR);

    // buffer to write in a message - start with a 80 size buffer
    // if for some reason bigger is needed realloc latter
    char *write_buffer = (char *)calloc(messageinfo->hdroffset, sizeof(char));
    if (write_buffer == NULL)
        return (MKMSG_MEM_ERROR7); // fix

    msgheader = (MSGHEADER *)write_buffer;

    // load MKMSG signature
    for (int x = 0; x < 8; x++)
        msgheader->magic_sig[x] = signature[x];

    for (int x = 0; x < 3; x++)
        msgheader->identifier[x] = messageinfo->identifier[x];

    msgheader->numbermsg = messageinfo->numbermsg;
    msgheader->firstmsg = messageinfo->firstmsg;
    msgheader->offset16bit = messageinfo->offsetid;
    msgheader->version = messageinfo->version;
    msgheader->hdroffset = messageinfo->hdroffset;
    msgheader->countryinfo = messageinfo->countryinfo;
    msgheader->extenblock = messageinfo->extenblock;

    for (int x = 0; x < 3; x++)
        msgheader->reserved[x] = messageinfo->reserved[x];

    fwrite(msgheader, sizeof(char), messageinfo->hdroffset, fpo);

    // generate and write empty index
    write_buffer = (char *)realloc(write_buffer, messageinfo->indexsize);
    if (write_buffer == NULL)
        return (MKMSG_MEM_ERROR2);

    memset(write_buffer, 0x00, _msize(write_buffer));
    fwrite(write_buffer, sizeof(char), messageinfo->indexsize, fpo);

    // generate and write empty index
    write_buffer = (char *)realloc(write_buffer, sizeof(FILECOUNTRYINFO));
    if (write_buffer == NULL)
        return (MKMSG_MEM_ERROR2);

    memset(write_buffer, 0x00, _msize(write_buffer));
    cntryheader = (FILECOUNTRYINFO *)write_buffer;

    cntryheader->bytesperchar = messageinfo->bytesperchar;
    cntryheader->country = messageinfo->country;
    cntryheader->langfamilyID = messageinfo->langfamilyID;
    cntryheader->langversionID = messageinfo->langversionID;
    cntryheader->codepagesnumber = messageinfo->codepagesnumber;

    for (int x = 0; x < cntryheader->codepagesnumber; x++)
        cntryheader->codepages[x] = messageinfo->codepages[x];

    strncpy(cntryheader->filename,
            messageinfo->filename,
            strlen(messageinfo->filename));

    cntryheader->filler = 0x00;

    fwrite(cntryheader, sizeof(char), sizeof(FILECOUNTRYINFO), fpo);

    fclose(fpo);
    free(write_buffer);

    return (0);
}

/* DecodeLangOpt( )
 *
 * get and check cmd line /L option
 */
int DecodeLangOpt(char *dargs, MESSAGEINFO *messageinfo)
{
    messageinfo->langfamilyIDcode = 0;

    if (strchr(dargs, ',') == NULL)
    {
        ProgError(-1, "MKMSGF: No sub id using 1 default");
        messageinfo->langversionID = 1;
        messageinfo->langfamilyID = atoi(dargs);
    }
    else
    {
        messageinfo->langfamilyID = atoi(strtok(dargs, ","));
        messageinfo->langversionID = atoi(strtok(NULL, ","));
    }

    // Language family > 1 and < 35
    if (messageinfo->langfamilyID < 1 || messageinfo->langfamilyID > 34)
        ProgError(1, "MKMSGF: Language family is outside of valid range");

    for (int i = 1; i < 35; i++)
    {
        if (langinfo[i].langfam == messageinfo->langfamilyID)
            if (langinfo[i].langsub == messageinfo->langversionID)
                messageinfo->langfamilyIDcode = i;
    }

    if (!messageinfo->langfamilyIDcode)
        ProgError(1, "MKMSGF: Sub id is outside of valid codepage range");

    return 1;
}

/*************************************************************************
 * Function:  displayinfo()
 *
 * Display MESSAGEINFO data to screen
 *
 *************************************************************************/

void displayinfo(MESSAGEINFO *messageinfo)
{
    printf("\n*********** Header Info ***********\n\n");

    printf("Input filename         %s\n", messageinfo->infile);
    printf("Component Identifier:  %c%c%c\n", messageinfo->identifier[0],
           messageinfo->identifier[1], messageinfo->identifier[2]);
    printf("Number of messages:    %d\n", messageinfo->numbermsg);
    printf("First message number:  %d\n", messageinfo->firstmsg);
    printf("OffsetID:              %d  (Offset %s)\n", messageinfo->offsetid,
           (messageinfo->offsetid ? "uint16_t" : "uint32_t"));
    printf("MSG File Version:      %d\n", messageinfo->version);
    printf("Header offset:         0x%02X (%d)\n",
           messageinfo->hdroffset, messageinfo->hdroffset);
    printf("Country Info:          0x%02X (%d)\n",
           messageinfo->countryinfo, messageinfo->countryinfo);
    printf("Extended Header:       0x%02X (%lu)\n",
           messageinfo->extenblock, messageinfo->extenblock);
    printf("Reserved area:         ");
    for (int x = 0; x < 5; x++)
        printf("%02X ", messageinfo->reserved[x]);
    printf("\n");
    if (messageinfo->reserved)
        printf("Built with MKMSGF clone (signature):  %s\n", messageinfo->reserved);
        printf("\n*********** Country Info  ***********\n\n");
        printf("Bytes per character:       %d\n", messageinfo->bytesperchar);
        printf("Country Code:              %d\n", messageinfo->country);
        printf("Language family ID:        %d\n", messageinfo->langfamilyID);
        printf("Language version ID:       %d\n", messageinfo->langversionID);
        printf("Number of codepages:       %d\n", messageinfo->codepagesnumber);
        for (int x = 0; x < messageinfo->codepagesnumber; x++)
            printf("0x%02X (%d)  ", messageinfo->codepages[x], messageinfo->codepages[x]);
        printf("\n");
        printf("File name:                 %s\n\n", messageinfo->filename);

    if (messageinfo->extenblock)
    {
        printf("** Has an extended header **\n");
        printf("Ext header length:        %d\n", messageinfo->extlength);
        printf("Number ext blocks:        %d\n\n", messageinfo->extnumblocks);
    }
    else
        printf("** No an extended header **\n\n");

    return;
}

/* ProgError( )
 *
 * stardard message print
 *
 * if exnum < 0 then print heading (if not yet displayed) and
 * return.
 * else do the above and exit
 *
 */
void ProgError(int exnum, char *dispmsg)
{
    // if (!prgheaddisp)
    // {
    prgheading(); // display program heading
    //    prgheaddisp = 1;
    //}

    printf("\n%s\n", dispmsg);

    if (exnum < 0)
        return;
    else
    {
        helpshort();
        exit(exnum);
    }
}

/*
 * User message functions
 */
void usagelong(void)
{
    helpshort();
    helplong();
}

void prgheading(void)
{
    printf("\nOperating System/2 Make Message File Utility (MKMSGF) Clone\n");
    printf("Version %s  Michael Greene <mike@mgreene.org>\n", SYSLVERSION);
    printf("Compiled with Open Watcom %d.%d  %s\n", OWMAJOR, OWMINOR, __DATE__);
}

void helpshort(void)
{
    printf("\nMKMSGF infile[.ext] outfile[.ext] [-V]\n");
    printf("[-D <DBCS range or country>] [-P <code page>] [-L <language id,sub id>]\n");
}

void helplong(void)
{
    printf("\nUse MKMSGF as follows:\n");
    printf("        MKMSGF <inputfile> <outputfile> [/V]\n");
    printf("                [/D <DBCS range or country>] [/P <code page>]\n");
    printf("                [/L <language family id,sub id>]\n");
    printf("        where the default values are:\n");
    printf("           code page  -  none\n");
    printf("           DBCS range -  none\n");
    printf("        A valid DBCS range is: n10,n11,n20,n21,...,nn0,nn1\n");
    printf("        A single number is taken as a DBCS country code.\n");
    printf("        The valid OS/2 language/sublanguage ID values are:\n\n");
    printf("\tLanguage ID:\n");
    printf("\tCode\tFamily\tSub\tLanguage\tPrincipal country\n");
    printf("\t----\t------\t---\t--------\t-----------------\n");
    //    for (int i = 0; langinfo[i].langfam != 0; i++)
    //        printf("\t%s\t%d\t%d\t%-20s\t%s\n", langinfo[i].langcode,
    //               langinfo[i].langfam, langinfo[i].langsub, langinfo[i].lang, langinfo[i].country);
}

void DumpMsgInfo(MESSAGEINFO *messageinfo)
{
    printf("\n*********** Header Info ***********\n\n");

    printf("Input filename         %s\n", messageinfo->infile);
    printf("Component Identifier:  %c%c%c\n", messageinfo->identifier[0],
           messageinfo->identifier[1], messageinfo->identifier[2]);
    printf("Number of messages:    %d\n", messageinfo->numbermsg);
    printf("First message number:  %d\n", messageinfo->firstmsg);
    printf("OffsetID:              %d  (Offset %s)\n", messageinfo->offsetid,
           (messageinfo->offsetid ? "uint16_t" : "uint32_t"));
    printf("MSG File Version:      %d\n", messageinfo->version);
    printf("Header offset:         0x%02X (%d)\n",
           messageinfo->hdroffset, messageinfo->hdroffset);
    printf("Country Info:          0x%02X (%d)\n",
           messageinfo->countryinfo, messageinfo->countryinfo);
    //    printf("Extended Header:       0x%02X (%lu)\n",
    //           messageinfo->extenblock, messageinfo->extenblock);
    printf("Reserved area:         ");
    for (int x = 0; x < 5; x++)
        printf("%02X ", messageinfo->reserved[x]);
    printf("\n");

    printf("\n*********** Country Info  ***********\n\n");
    printf("Bytes per character:       %d\n", messageinfo->bytesperchar);
    printf("Country Code:              %d\n", messageinfo->country);
    printf("Language family ID:        %d\n", messageinfo->langfamilyID);
    printf("Language version ID:       %d\n", messageinfo->langversionID);
    printf("Number of codepages:       %d\n", messageinfo->codepagesnumber);
    for (int x = 0; x < messageinfo->codepagesnumber; x++)
        printf("0x%02X (%d)  ", messageinfo->codepages[x], messageinfo->codepages[x]);
    printf("\n");
    /*    printf("File name:                 %s\n\n", messageinfo->filename);
        if (messageinfo->extenblock)
        {
            printf("** Has an extended header **\n");
            printf("Ext header length:        %d\n", messageinfo->extlength);
            printf("Number ext blocks:        %d\n\n", messageinfo->extnumblocks);
        }
        else
            printf("** No an extended header **\n\n");
    */
    return;
}
