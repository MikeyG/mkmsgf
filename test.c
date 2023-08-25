
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
    if (argc < 2 || argc > 2)
    {
        printf("no args\n");
        return 1;
    }

    return (readheader(argv[1]));
}

int readheader(char *filename)
{
    FILE *fp;

    // check the input msg file exists
    if (access(filename, F_OK) != 0)
        return (100);

    MSGHEADER1 *newheader = (MSGHEADER1 *)calloc(sizeof(MSGHEADER1), sizeof(uint8_t));

    fp = fopen(filename, "r");

    fread(newheader, 1, sizeof(*newheader), fp);

    printf("File: %s\n", filename);
    printf("magic_sign   %d %c%c%c%c%c%c %d\n", newheader->magic_sign[0],
           newheader->magic_sign[1],
           newheader->magic_sign[2],
           newheader->magic_sign[3],
           newheader->magic_sign[4],
           newheader->magic_sign[5],
           newheader->magic_sign[6],
           newheader->magic_sign[7]);
    printf("identifier    %c%c%c\n", newheader->identifier[0], newheader->identifier[1], newheader->identifier[2]);
    printf("numbermsg     %d\n", newheader->numbermsg);
    printf("firstmsg      %d\n", newheader->firstmsg);
    printf("offset16bit   %d\n", newheader->offset16bit);
    printf("version       %d\n", newheader->version);
    printf("hdroffset     %d\n", newheader->hdroffset);
    printf("countryinfo   %d\n", newheader->countryinfo);
    printf("extenblock    %d\n", newheader->extenblock);


    fclose(fp);
    free(newheader);

    printf("End run\n");
    return 0;
}

/*
magic_sign   255 MKMSGF 0
identifier    SYS
numbermsg     179
firstmsg      0
offset16bit   2
version       7936

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
*/