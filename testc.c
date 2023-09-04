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
       - dword index values
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

// ouput display functions
void usagelong(void);
void prgheading(void);
void helpshort(void);
void helplong(void);

int main(int argc, char *argv[])
{
    int rc = 0;

    uint8_t procinfile = 0;  // keep track getopt - IBM compatabile

    char *filename = ".\\w\\testpp.txt";

    MESSAGEINFO messageinfo; // holds all the info

    // these I found in the code, here for reference but not used
    uint8_t *includepath = getenv("INCLUDE");
    uint8_t *mkmsgfprog = getenv("MKMSGF_PROG");
    if (mkmsgfprog != NULL)
        if (!strncmp(mkmsgfprog, "OS2LDR", 6))
            os2ldr = 1;

    
    printf("%s\n",*argv[1]);

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
    if ((*argv[1] != '-') && (*argv[1] != '/'))
    {                              // first arg prefix - or / ?
        char *ptmp = argv[optind]; // scratch pointer
        ++procinfile;              // no - set process infile true

        for (int i = 0; i < strlen(argv[optind]); i++)
            inputfile[i] = *ptmp++;
        // GetInputFile();
        optind++;
        if (argc > 2)
        {
            if ((*argv[2] != '-') && (*argv[2] != '/'))
                strcpy(outputfile, argv[optind++]); // have output file
            else
                GetOutputFile(); // no output file
        }
        // else
        //    GetOutputFile(); // only have input and no args, make output
    }



    strncpy(messageinfo.infile, filename, strlen(filename));

    rc = setupheader(&messageinfo);
    if (rc != 0)
    {
        printf("RC: %d\n\n", rc);
        exit(rc);
    }

    displayinfo(&messageinfo);

    exit(0);
}

/*************************************************************************
 * Function:  setupheader( )
 *
 * Gets and stores header info in MESSAGEINFO structure
 *
 * 1.
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

    // get input file path info into MESSAGEINFO
    _splitpath(messageinfo->infile,
               messageinfo->indrive,
               messageinfo->indir,
               messageinfo->infname,
               messageinfo->inext);

    // get identifer and save
    while (TRUE)
    {
        size_t n = 0;
        char *line = NULL;

        getline(&line, &n, fpi);

        if (line[0] != ';')
        {
            messageinfo->msgstartline++;

            if (strlen(line) > 5) // identifer (3) + 0x0D 0x0A (2)
                exit(99);
            messageinfo->identifier[0] = line[0];
            messageinfo->identifier[1] = line[1];
            messageinfo->identifier[2] = line[2];
            break;
        }
        else
            messageinfo->msgstartline++;
    }

    // make sure number of messages is 0
    messageinfo->numbermsg = 0;

    // first run through file to get:
    // 1. start message number
    // 2. get number of messages
    // 3. determine index pointer and size
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

    messageinfo->version = 0x0002;                     // set version
    messageinfo->hdroffset = 0x001F;                   // header offset
    messageinfo->indexoffset = messageinfo->hdroffset; // okay dup of hdroffset
    messageinfo->reserved[0] = 0x4D;                   // put this in to mark MKD clone compiled
    messageinfo->reserved[1] = 0x4B;
    messageinfo->reserved[2] = 0x47;
    messageinfo->reserved[3] = 0x00;
    messageinfo->reserved[4] = 0x00;

    // hdrsize/offset + the size of index will locate the country info
    messageinfo->countryinfo = messageinfo->hdroffset +
                               messageinfo->indexsize;

    // messages start after the FILECOUNTRYINFO block
    messageinfo->msgoffset = messageinfo->countryinfo +
                             sizeof(FILECOUNTRYINFO1);

    // remains 0 for now
    messageinfo->extenblock = 0;

    return (0);
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
    /*    printf("\n*********** Country Info  ***********\n\n");
        printf("Bytes per character:       %d\n", messageinfo->bytesperchar);
        printf("Country Code:              %d\n", messageinfo->country);
        printf("Language family ID:        %d\n", messageinfo->langfamilyID);
        printf("Language version ID:       %d\n", messageinfo->langversionID);
        printf("Number of codepages:       %d\n", messageinfo->codepagesnumber);
        for (int x = 0; x < messageinfo->codepagesnumber; x++)
            printf("0x%02X (%d)  ", messageinfo->codepages[x], messageinfo->codepages[x]);
        printf("\n");
        printf("File name:                 %s\n\n", messageinfo->filename);
    */
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
