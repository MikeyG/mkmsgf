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

int main()
{
    int rc = 0;

    char *filename = ".\\w\\OSO001.txt";

    MESSAGEINFO messageinfo; // holds all the info

    strncpy(messageinfo.infile, filename, strlen(filename));

    rc = setupheader(&messageinfo);
    if (rc != 0)
    {
        printf("RC: %d\n\n", rc);
        exit(rc);
    }

    printf("messageinfo.identifier    %s\n", messageinfo.identifier);
    printf("messageinfo.firstmsg      %d\n", messageinfo.firstmsg);
    printf("messageinfo.numbermsg     %d\n", messageinfo.numbermsg);
    printf("messageinfo.msgstartline  %d\n", messageinfo.msgstartline);

    exit(0);
}

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
        if (_filelength(handle) <= 50000)
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
    messageinfo->reserved[0] = 0x00;                   // put this in to mark MKD clone compiled
    messageinfo->reserved[1] = 0x00;
    messageinfo->reserved[2] = 0x4D;
    messageinfo->reserved[3] = 0x4B;
    messageinfo->reserved[4] = 0x47;

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

void prgheading(void)
{
    printf("\nOperating System/2 Make Message File Decompiler (MKMSGD)\n");
    printf("Version %s  Michael Greene <mikeos2@gmail.com>\n", SYSLVERSION);
    printf("Compiled with Open Watcom %d.%d  %s\n", OWMAJOR, OWMINOR, __DATE__);
}

void helpshort(void)
{
    printf("\nMKMSGD [-v] infile.msg [outfile.[txt | codepage] ]\n\n");
}

void helplong(void)
{
    printf("\nUse MKMSGD as follows:\n");
    printf("        [-v] infile.msg [outfile.[txt | codepage] ]\n");

    return;
}

