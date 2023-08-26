
#define INCL_DOSNLS /* National Language Support values */

#include <os2.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <io.h>
#include <sys\stat.h>
#include <unistd.h>
#include <malloc.h>
#include "mkmsgf.h"
#include "mkmsgerr.h"
#include "version.h"

#include <io.h>

int readheader(char *filename, MESSAGEINFO *messageinfo);

/* main( )
 *
 * Entry into the program
 */
int main(int argc, char *argv[])
{

    int rc;

    MESSAGEINFO messageinfo;

    if (argc < 2 || argc > 2)
    {
        printf("no args\n");
        return 1;
    }

    rc = readheader(argv[1], &messageinfo);

    if (rc != 0)
    {
        printf("RC: %d\n\n", rc);
        exit(rc);
    }

    printf("*********** Header Info ***********\n\n");

    printf("Input filename         %s\n", messageinfo.infile);
    printf("Component Identifier:  %s\n", messageinfo.identifier);
    printf("Number of messages:    %d\n", messageinfo.numbermsg);
    printf("First message number:  %d\n", messageinfo.firstmsg);
    printf("OffsetID:              %d\n", messageinfo.offsetid);
    printf("MSG File Version:      %d\n\n", messageinfo.version);
    printf("Header offset:     0x%02X (%d)\n\n",
           messageinfo.hdroffset, messageinfo.hdroffset);
    printf("Country Info Offset:     0x%02X (%d)\n",
           messageinfo.countryinfo, messageinfo.countryinfo);
    printf("Ext Block Offset:        0x%02X (%lu)\n\n",
           messageinfo.extenblock, messageinfo.extenblock);
    printf("Reserved area:\n");
    for (int x = 0; x < 5; x++)
        printf("%02X ", messageinfo.reserved[x]);
    printf("\n");
    printf("\n*********** Country Info  ***********\n\n");
    printf("Bytes per character:       %d\n", messageinfo.bytesperchar);
    printf("Country Code:              %d\n", messageinfo.country);
    printf("Language family ID:        %d\n", messageinfo.langfamilyID);
    printf("Language version ID:       %d\n", messageinfo.langversionID);
    printf("Number of codepages:       %d\n", messageinfo.codepagesnumber);
    for (int x = 0; x < messageinfo.codepagesnumber; x++)
        printf("%02X (%d)  ", messageinfo.codepages[x], messageinfo.codepages[x]);
    printf("\n");
    printf("File name:                 %s\n", messageinfo.filename);
    printf("\nEnd Decompile (%d)\n", rc);
    return (rc);
}

/*
 */

int readheader(char *filename, MESSAGEINFO *messageinfo)
{
    MSGHEADER1 *msgheader = NULL;
    FILECOUNTRYINFO1 *cpheader = NULL;

    // check the input msg file exists
    if (access(filename, F_OK) != 0)
        return (MKMSG_INPUT_ERROR);

    strcpy(messageinfo->infile, filename);

    // open input file
    FILE *fp = fopen(filename, "rb");
    if (fp == NULL)
        return (MKMSG_OPEN_ERROR);

    // buffer to read in header
    char *header = (char *)calloc(sizeof(MSGHEADER1), sizeof(char));
    if (header == NULL)
        return (MKMSG_MEM_ERROR);

    // read header
    int read = fread(header, sizeof(char), sizeof(MSGHEADER1), fp);
    if (ferror(fp))
        return (MKMSG_READ_ERROR);

    // MSGHEADER1 point to header buffer
    msgheader = (MSGHEADER1 *)header;

    // check header signature, return error no match
    for (int x = 0; x < sizeof(signature); x++)
        if (signature[x] != msgheader->magic_sig[x])
            return (MKMSG_HEADER_ERROR);

    // Pulls all header information into MESSAGEINFO
    for (int x = 0; x < 3; x++)
        messageinfo->identifier[x] = msgheader->identifier[x];
    messageinfo->identifier[3] = 0x00;

    messageinfo->numbermsg = msgheader->numbermsg;
    messageinfo->firstmsg = msgheader->firstmsg;
    messageinfo->offsetid = msgheader->offset16bit;
    messageinfo->version = msgheader->version;
    messageinfo->countryinfo = msgheader->countryinfo;
    messageinfo->extenblock = msgheader->extenblock;
    messageinfo->hdroffset = msgheader->hdroffset;
    for (int x = 0; x < 5; x++)
        messageinfo->reserved[x] = msgheader->reserved[x];

    // *** Get country info
    // re-allocate buffer to size of FILECOUNTRYINFO1
    header = (char *)realloc(header, sizeof(FILECOUNTRYINFO1));
    if (header == NULL)
        return (MKMSG_MEM_ERROR);

    // seek to the block for read
    fseek(fp, messageinfo->countryinfo, SEEK_SET);

    // read header
    read = fread(header, sizeof(char), sizeof(FILECOUNTRYINFO1), fp);
    if (ferror(fp))
        return (MKMSG_READ_ERROR);

    // FILECOUNTRYINFO1 point to header buffer
    cpheader = (FILECOUNTRYINFO1 *)header;

    // Pulls all country information into MESSAGEINFO
    messageinfo->bytesperchar = cpheader->bytesperchar;
    messageinfo->country = cpheader->country;
    messageinfo->langfamilyID = cpheader->langfamilyID;
    messageinfo->langversionID = cpheader->langversionID;
    messageinfo->codepagesnumber = cpheader->codepagesnumber;
    strcpy(messageinfo->filename, cpheader->filename);

    fclose(fp);
    free(header);

    printf("End run\n");

    return (0);
}
