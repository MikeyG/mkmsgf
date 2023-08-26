
#define INCL_DOSNLS /* National Language Support values */

#include <os2.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <io.h>
#include <sys\stat.h>
#include <unistd.h>
#include "mkmsgf.h"
#include "version.h"

#include <io.h>

int readheader(char *filename);

/* main( )
 *
 * Entry into the program
 */
int main(int argc, char *argv[])
{

    // DECOMPINFO *headerinfo;

    if (argc < 2 || argc > 2)
    {
        printf("no args\n");
        return 1;
    }

    return (readheader(argv[1]));
}

/*
 * 1. Prints filename if input file exists.
 * 2.
 */

int readheader(char *filename)
{
    FILE *fp;
    int read;

    uint8_t identifier[4] = {0};
    uint16_t numbermsg;
    uint16_t firstmsg;
    uint8_t offsetid;
    uint16_t version;
    uint16_t hdroffset;
    uint16_t countryinfo;
    uint32_t extenblock;

    MSGHEADER1 *newheader;

    // check the input msg file exists
    if (access(filename, F_OK) != 0)
        return (100);
    else
        printf("\nInput Filename:   %s\n\n", filename);

    // open input file
    fp = fopen(filename, "rb");
    if (fp == NULL)
        return (101);

    // buffer to read in header
    uint8_t *header = (uint8_t *)calloc(sizeof(MSGHEADER1), sizeof(uint8_t));
    if (header == NULL)
        return 102;

    // read header
    read = fread(header, sizeof(MSGHEADER1), sizeof(MSGHEADER1), fp);

    newheader = (MSGHEADER1 *)header;

    // check header signature
    for (int x = 0; x < sizeof(signature); x++)
        if (signature[x] != newheader->magic_sig[x])
            return 103;

    // made it to here because signature was good
    printf("Header signature was good.\n\n");

    // get component ID
    for (int x = 0; x < 3; x++)
        identifier[x] = newheader->identifier[x];
    identifier[3] = 0x00;

    numbermsg = newheader->numbermsg;
    firstmsg = newheader->firstmsg;
    offsetid = newheader->offset16bit;
    version = newheader->version;
    countryinfo = newheader->countryinfo;
    extenblock = newheader->extenblock;

    printf("Component Identifier:  %s\n", identifier);
    printf("Number of messages:    %d\n", numbermsg);
    printf("First message number:  %d\n", firstmsg);
    printf("OffsetID:              %d\n", offsetid);
    printf("MSG File Version:      %d\n\n", version);
    printf("Header offset:     0x%02X (%d)\n\n",
           newheader->hdroffset,
           newheader->hdroffset);
    printf("Country Info Offset:   %d\n", countryinfo);
    printf("Ext Block Offset:     %lu\n\n", extenblock);

    // display reseved area for fun
    printf("Reserved area:\n");
    for (int x = 0; x < 5; x++)
        printf("%02X ", newheader->reserved[x]);
    printf("\n");

    fclose(fp);
    free(newheader);

    printf("End run\n");
    return 0;
}
