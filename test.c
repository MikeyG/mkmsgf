
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
int setup_options(MESSAGEINFO *messageinfo);
int readmessages(MESSAGEINFO *messageinfo);
int getmessages(FILE *fp, unsigned long msgcurrent,
                unsigned long msg_next, unsigned long msgcount);

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
    printf("OffsetID:              %d  (Offset %s)\n", messageinfo.offsetid,
           (messageinfo.offsetid ? "uint16_t" : "uint32_t"));
    printf("MSG File Version:      %d\n", messageinfo.version);
    printf("Header offset:         0x%02X (%d)\n",
           messageinfo.hdroffset, messageinfo.hdroffset);
    printf("Country Info:          0x%02X (%d)\n",
           messageinfo.countryinfo, messageinfo.countryinfo);
    printf("Extended Header:       0x%02X (%lu)\n",
           messageinfo.extenblock, messageinfo.extenblock);
    printf("Reserved area:         ");
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
    printf("File name:                 %s\n\n", messageinfo.filename);
    if (messageinfo.extenblock)
    {
        printf("** Has an extended header **\n");
        printf("Ext header length:        %d\n", messageinfo.extlength);
        printf("Number ext blocks:        %d\n", messageinfo.extnumblocks);
    }
    else
        printf("** No an extended header **\n");

    printf("\n - Messages start:   0x%02X\n\n", messageinfo.msgoffset);

    rc = readmessages(&messageinfo);

    printf("\nEnd Decompile (%d)\n", rc);
    return (rc);
}

/*
 *
 */

int readheader(char *filename, MESSAGEINFO *messageinfo)
{
    MSGHEADER1 *msgheader = NULL;
    FILECOUNTRYINFO1 *cpheader = NULL;
    EXTHDR *extheader = NULL;

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
    messageinfo->hdroffset = msgheader->hdroffset;
    messageinfo->countryinfo = msgheader->countryinfo;
    messageinfo->extenblock = msgheader->extenblock;
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
    for (int x = 0; x < messageinfo->codepagesnumber; x++)
        messageinfo->codepages[x] = cpheader->codepages[x];

    // quick check of extended header, it's a small block but be
    // consistent. I do not have an example yet so this is kind of a stub
    if (messageinfo->extenblock == 0)
    {
        // No ext header so set to 0
        messageinfo->extlength = 0;
        messageinfo->extnumblocks = 0;
    }
    else
    {
        // re-allocate buffer to size of EXTHDR
        header = (char *)realloc(header, sizeof(EXTHDR));
        if (header == NULL)
            return (MKMSG_MEM_ERROR);

        // seek to the block for read
        fseek(fp, messageinfo->extenblock, SEEK_SET);

        // read header
        read = fread(header, sizeof(char), sizeof(EXTHDR), fp);
        if (ferror(fp))
            return (MKMSG_READ_ERROR);

        // FILECOUNTRYINFO1 point to header buffer
        extheader = (EXTHDR *)header;

        messageinfo->extlength = extheader->hdrlen;
        messageinfo->extnumblocks = extheader->numblocks;
    }

    // index starts after main header
    messageinfo->indexoffset = messageinfo->hdroffset;

    // start of message area
    messageinfo->msgoffset = messageinfo->countryinfo + sizeof(FILECOUNTRYINFO1);

    // get index size and do check based on offsetid and index size
    messageinfo->indexsize = messageinfo->countryinfo - messageinfo->hdroffset;
    if (messageinfo->offsetid)
    {
        if ((messageinfo->indexsize / 2) != messageinfo->numbermsg)
            return (MKMSG_INDEX_ERROR);
    }
    else if ((messageinfo->indexsize / 4) != messageinfo->numbermsg)
        return (MKMSG_INDEX_ERROR);

    // close up and get out
    fclose(fp);
    free(header);

    return (0);
}

/* setup_options(MESSAGEINFO *messageinfo)

Index location/size

1. messageinfo->hdroffset is the size of header and as an offset
the start of index.

2. messageinfo->countryinfo - 1 is the end of index.

3. Each index record points to a message using either a "uint16_t"
or "uint32_t" size. So the max uint16_t size is 65535 which would
somewhat determine

*/
int setup_options(MESSAGEINFO *messageinfo)
{

    return 0;
}

int readmessages(MESSAGEINFO *messageinfo)
{
    // index pointers
    uint16_t *small_index = NULL;
    uint32_t *large_index = NULL;

    // start of message area
    unsigned long msgcurrent = 0;
    unsigned long msg_next = 0;
    unsigned long msgcount = 0;

    // track size of message read buffer
    unsigned long msglenbuffer = 80;

    // open input file
    FILE *fp = fopen(messageinfo->filename, "rb");
    if (fp == NULL)
        return (MKMSG_OPEN_ERROR);

    // first thing to do is find the end of the message block
    // if messageinfo.extenblock holds an offset - that is the end
    // of our root message block else we will seek to the end of the
    // file to get the end
    if (messageinfo->extenblock)
        messageinfo->msgendofblock = messageinfo->extenblock;
    else
    {
        fseek(fp, 0L, SEEK_END);
        messageinfo->msgendofblock = ftell(fp);
    }

    // seek to the start of index for read
    fseek(fp, messageinfo->indexoffset, SEEK_SET);

    // buffer to read in index
    char *buffer = (char *)calloc(messageinfo->indexsize, sizeof(char));
    if (buffer == NULL)
        return (MKMSG_MEM_ERROR);

    // read index into buffer
    int read = fread(buffer, sizeof(char), messageinfo->indexsize, fp);
    if (ferror(fp))
        return (MKMSG_READ_ERROR);

    // buffer to read in a message - start with a 80 size buffer
    // if for some reason bigger is needed realloc latter
    char *msgbuffer = (char *)calloc(msglenbuffer, sizeof(char));
    if (msgbuffer == NULL)
        return (MKMSG_MEM_ERROR);

    if (messageinfo->offsetid)
        small_index = (uint16_t *)buffer;
    else
        large_index = (uint32_t *)buffer;

    for (int x = 0; x < messageinfo->numbermsg; x++)
    {
        // do the message number counting
        msgcount = messageinfo->firstmsg + x;

        // handle the uint16 and uint32 index differences
        if (messageinfo->offsetid)
        {
            msgcurrent = (unsigned long)*small_index++;
            msg_next = (unsigned long)*small_index;
        }
        else
        {
            msgcurrent = *large_index++;
            msg_next = *large_index;
        }

        // if we are on the last message then the msg_next
        // needs to be the end of the message block + 1 as calculated
        // with the fseek to end above.
        // As a note, I am going to use msgcurrent and msg_next to
        // get the message length.
        if (x == (messageinfo->numbermsg - 1))
            msg_next = messageinfo->msgendofblock;

        // seek to the start of message to read
        fseek(fp, msgcurrent, SEEK_SET);

        // check read buffer size
        if ((msg_next - msgcurrent) > msglenbuffer)
        {
            msglenbuffer = (msg_next - msgcurrent); // new buffer size
            msgbuffer = (char *)realloc(msgbuffer, msglenbuffer);
            if (msgbuffer == NULL)
            {
                fclose(fp);
                free(msgbuffer);
                free(buffer);
                return (MKMSG_MEM_ERROR);
            }
        }

        // clear the msgbuffer
        memset(msgbuffer, 0x00, msglenbuffer);

        // read in the message
        fread(msgbuffer, sizeof(char), (msg_next - msgcurrent), fp);

        
        printf("%s%04d%c %s", messageinfo->identifier, msgcount, msgbuffer[0], msgbuffer);

        // getmessages(fp, msgcurrent, msg_next, msgcount);
    }

    printf("\n");

    // close up and get out
    fclose(fp);
    free(msgbuffer);
    free(buffer);

    return (0);
}

int getmessages(FILE *fp, unsigned long msgcurrent,
                unsigned long msg_next, unsigned long msgcount)
{
    printf("%d  0x%02X  0x%02X    %lu\n", msgcount, msgcurrent, msg_next, (msg_next - msgcurrent));

    return (0);
}
