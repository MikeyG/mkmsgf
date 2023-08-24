/****************************************************************************
 *
 *  mkmsgf.c -- Make Message File Utility (MKMSGF) Clone
 *
 *  ========================================================================
 *
 *    Version 1.0       Michael K Greene <mike@mgreene.org>
 *                      July 2008
 *
 *  ========================================================================
 *
 *  Description: Simple clone of the mkmsgf tool.
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


#define INCL_DOSNLS     /* National Language Support values */

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


#define READBUFFSIZE    1024


// setup default structures
MSGHEADER msgheader = {
    0xFF, 0x4D, 0x4B, 0x4D, 0x53, 0x47, 0x46, 0x00,     /* magic = 0xFF MKMSGF 0x00 */
    0x53, 0x59, 0x53,                                   /* identifer = SYS          */
    0x0000,                                             /* msgnumber                */
    0x0000,                                             /* firstmsgnumber           */
    0x01,                                               /* offset16bit              */
    0x0002,                                             /* version                  */
    0x001F,                                             /* offset to index          */
    0x00,                                               /* coutryinfo               */
    0x0000,                                             /* nextcoutryinfo           */
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00      /* reserved                 */
};

FILECOUNTRYINFO countryinfo;

typedef struct suppinfo {
    char langcode[4];
    int  langfam;
    int  langsub;
    char lang[20];
    char country[15];
};

struct suppinfo langinfo[ ] = {
    {"ARA",  1, 2, "Arabic",                "Arab Countries"},
    {"BGR",  2, 1, "Bulgarian",             "Bulgaria"},
    {"CAT",  3, 1, "Catalan",               "Spain"},
    {"CHT",  4, 1, "Traditional Chinese",   "R.O.C."},
    {"CHS",  4, 2, "Simplified Chinese",    "P.R.C."},
    {"CSY",  5, 1, "Czech",                 "Czechoslovakia"},
    {"DAN",  6, 1, "Danish",                "Denmark"},
    {"DEU",  7, 1, "German",                "Germany"},
    {"DES",  7, 2, "Swiss German",          "Switzerland"},
    {"EEL",  8, 1, "Greek",                 "Greece"},
    {"ENU",  9, 1, "US English",            "United States"},
    {"ENG",  9, 2, "UK English",            "United Kingdom"},
    {"ESP", 10, 1, "Castilian Spanish",     "Spain"},
    {"ESM", 10, 2, "Mexican Spanish",       "Mexico"},
    {"FIN", 11, 1, "Finnish",               "Finland"},
    {"FRA", 12, 1, "French",                "France"},
    {"FRB", 12, 2, "Belgian French",        "Belgium"},
    {"FRC", 12, 3, "Canadian French",       "Canada"},
    {"FRS", 12, 4, "Swiss French",          "Switzerland"},
    {"HEB", 13, 1, "Hebrew",                "Israel"},
    {"HUN", 14, 1, "Hungarian",             "Hungary"},
    {"ISL", 15, 1, "Icelandic",             "Iceland"},
    {"ITA", 16, 1, "Italian",               "Italy"},
    {"ITS", 16, 2, "Swiss Italian",         "Switzerland"},
    {"JPN", 17, 1, "Japanese",              "Japan"},
    {"KOR", 18, 1, "Korean",                "Korea"},
    {"NLD", 19, 1, "Dutch",                 "Netherlands"},
    {"NLB", 19, 2, "Belgian Dutch",         "Belgium"},
    {"NOR", 20, 1, "Norwegian - Bokmal",    "Norway"},
    {"NON", 20, 2, "Norwegian - Nynorsk",   "Norway"},
    {"PLK", 21, 1, "Polish",                "Poland"},
    {"PTB", 22, 1, "Brazilian Portugues",   "Brazil"},
    {"PTG", 22, 2, "Portuguese",            "Portugal"},
    {"RMS", 23, 1, "Rhaeto-Romanic",        "Switzerland"},
    {"ROM", 24, 1, "Romanian",              "Romania"},
    {"RUS", 25, 1, "Russian",               "U.S.S.R."},
    {"SHL", 26, 1, "Croato-Serbian",        "Yugoslavia"},
    {"SHC", 26, 2, "Serbo-Croatian",        "Yugoslavia"},
    {"SKY", 27, 1, "Slovakian",             "Czechoslovakia"},
    {"SQI", 28, 1, "Albanian",              "Albania"},
    {"SVE", 29, 1, "Swedish",               "Sweden"},
    {"THA", 30, 1, "Thai",                  "Thailand"},
    {"TRK", 31, 1, "Turkish",               "Turkey"},
    {"URD", 32, 1, "Urdu",                  "Pakistan"},
    {"BAH", 33, 1, "Bahasa",                "Indonesia"},
    {"SLO", 34, 1, "Slovene",               "Slovenia"},
    {"",     0, 0, NULL,                    NULL}
};

// helper functions
void GetInputFile(void);
void GetOutputFile(void);
int  StartMessage(unsigned char *buffer);
void GetDefaultCodePages(void);
int  DecodeLangOpt(char *dargs);
void ProgError(int exnum, char *dispmsg);

// ouput display functions
void usagelong( void );
void prgheading( void );
void helpshort( void );
void helplong( void );


// input/output file names
unsigned char inputfile[_MAX_PATH]  = {0};
unsigned char outputfile[_MAX_PATH] = {0};
unsigned char prgheaddisp = 0;


/* main( )
 *
 * Entry into the program
 */
int main(int argc, char *argv[ ])
{
    int  ch          = 0;               // getopt variable
    int  os2ldr      = 0;               // here but not used
    int  infileline  = 0;               // input line
    int  msgcounter  = 0;               // message counter
    int  lastmsgnum  = 0;               // calclated last msg number

    // flags
    unsigned char firstmsgflg = 0;      // first message found
    unsigned char procinfile  = 0;      // keep track getopt - IBM compatabile
    unsigned char foundID     = 0;      // identifier found
    unsigned char proclang    = 0;      // lang opt processed

    // getopt options
    unsigned char verbose   = 0;        // verbose output
    unsigned char dispquiet = 0;        // quiet all display - unless error
    unsigned char _UnknOpt1 = 0;        // asm option
    unsigned char _UnknOpt2 = 0;        // C option
    unsigned char *includepath;         // unsupported option
    unsigned char *mkmsgfprog;          // unsupported option

    FILE *fp;                           // file stream pointer
    fpos_t fpos1;                       // file position pionter
    fpos_t fpos2;                       // file position pionter

    struct stat infilestats;            // stat to find in file size
    unsigned int  inputsize = 0;        // hold input file size

    // input buffer pointers
    unsigned char  *buffptr = NULL;
    unsigned char  *buffer  = NULL;

    // index buffer pointers
    unsigned short *indexbufptr = NULL;
    unsigned short *indexbuffer = NULL;

    // message area buffer pointers
    unsigned char  *msgbuffptr = NULL;
    unsigned char  *msgbuffer  = NULL;
    unsigned int   msgareasize = 0;     // size required for msg memory
    unsigned short msgareaoff  = 0;     // calculated offset of msg area
    unsigned char  *msgrefptr  = NULL;  // msg area scratch ref pointer
    unsigned int   msgsizechk  = 0;


    // clear countryifo structures
    memset(&countryinfo, 0, sizeof(FILECOUNTRYINFO));

    // these I found in the code, here for reference but not used
    includepath = getenv( "INCLUDE" );
    mkmsgfprog  = getenv( "MKMSGF_PROG" );
    if(mkmsgfprog != NULL) if(!strncmp(mkmsgfprog, "OS2LDR", 6)) os2ldr = 1;

    // no args - print usage and exit
    if(argc == 1) {
        prgheading( );  // display program heading
        helpshort( );
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
    if((*argv[1] != '-')&&(*argv[1] != '/')) {                  // first arg prefix - or / ?
        char *ptmp = argv[optind];                              // scratch pointer
        ++procinfile;                                           // no - set process infile true


        for( int i=0; i<strlen(argv[optind]); i++) inputfile[i] = *ptmp++;
        GetInputFile( );
        optind++;
        if(argc > 2) {
            if((*argv[2] != '-')&&(*argv[2] != '/'))
                            strcpy(outputfile, argv[optind++]); // have output file
            else GetOutputFile( );                              // no output file
        } else GetOutputFile( );                                // only have input and no args, make output
    }

    // Get program arguments using getopt()
    while ((ch = getopt(argc, argv, "d:D:p:P:l:L:VvHhI:i:AaCcq")) != -1) {

        switch (ch) {

        case 'd':
        case 'D':
            ProgError(1, "MKMSGF: DBCS not supported");
            break;

        case 'p':
        case 'P':
            if(countryinfo.codepagesnumber < 16) {
                countryinfo.codepages[countryinfo.codepagesnumber++] = atoi(optarg);
            } else ProgError(1, "MKMSGF: More than 16 codepages entered");
            break;

        case 'l':
        case 'L':
            if(proclang) ProgError(1, "MKMSGF: Syntax error L option");
            proclang = DecodeLangOpt(optarg);
            break;

        case 'v':
        case 'V':
            if(!verbose) ++verbose;
            break;

        case 'h':
        case 'H':
            prgheading( );
            usagelong( );
            exit(0);
            break;

        // Undocumented IBM flags - here but not used

        case 'i':                   // change used include path, I think for A and C
        case 'I':
            includepath = optarg;
            break;

        case 'a':                   // the real mkmsgf outputs asm file
        case 'A':
            if(!_UnknOpt1) _UnknOpt1++;
            break;

        case 'c':                   // the real mkmsgf outputs C file
        case 'C':
            if(!_UnknOpt2) _UnknOpt2++;
            break;

        // my added option
        case 'q':
        case 'Q':
            if(!dispquiet) ++dispquiet;
            break;

        default:
            ProgError(1, "MKMSGF: Syntax error unknown option");
            break;
        }
    }

    // quiet flag
    if(dispquiet) --verbose;

    // check for input file - getopt compatable cmd line
    if ((argc == optind) && !procinfile) ProgError(1, "MKMSGF: no input file");

    if (!procinfile) {
        char *ptmp = argv[optind];

        for( int i=0; i<strlen(argv[optind]); i++) inputfile[i] = *ptmp++;
        GetInputFile( );
        optind++;
        if(argc == optind) GetOutputFile( );
        else strcpy(outputfile, argv[optind]);
    }

    // ************ done with args ************

    if(countryinfo.codepages[0] == 0) GetDefaultCodePages( );

    strcpy(countryinfo.filename, outputfile);

    // defaults for this version
    countryinfo.bytesperchar = 1;
    msgheader.offset16bit  = 1;

    // check input == output file
    if(!strcmp(inputfile, outputfile)) ProgError(1, "MKMSGF: Input file same as output file");

    // inputfile size
    stat(inputfile, &infilestats );
    inputsize = infilestats.st_size;

    // open input file
    fp = fopen(inputfile, "rb");

    // seek end of file, save, and rewind
    fseek( fp, 0L, SEEK_END );
    fgetpos( fp, &fpos2 );
    fseek( fp, 0L, SEEK_SET);

    // allocate read buffer
    buffer = (unsigned char *)malloc(READBUFFSIZE);    // past here free(buffer) for exit

    // bad malloc read buffer -- get out
    if(buffer == NULL) {
        fclose(fp);
        free(buffer);
        ProgError(1, "MKMSGF: Buffer memory error.");
    } else {
        buffptr = buffer;
        memset(buffer, 0, READBUFFSIZE);
    }

    // get the identifer
    do {

        unsigned char *ptmp; // scratch pointer

        // get some input into the buffer
        fgets( buffer, READBUFFSIZE, fp );

        // my play - if user prefix with space which they should not!
        for(ptmp = buffer;(*ptmp == ' ');) ptmp++;

        infileline++;

        // skip comments, first none comment line is our ID
        if(*ptmp != ';') {

            for(int i=0; i<3; i++) {

                // gets upper cased here
                msgheader.identifier[i] = toupper(*ptmp++);

                // check just in case the user messed up -
                if(!isalpha(msgheader.identifier[i])) {
                    free(buffer);
                    ProgError(1, "MKMSGF: Invalid message file format");
                }
            }

            // last check - ptmp points to space after ID --
            if(isalnum(*ptmp)) {
                free(buffer);
                ProgError(1, "MKMSGF: Invalid message file format.");
            }

            ++foundID;  // found identifier
            break; // get out
        }
    } while (!feof(fp));

    // you got to the end of file and found no identifer
    if(!foundID) {
        free(buffer);
        ProgError(1, "MKMSGF: Invalid message file format - no ID");
    }

    // save infile position after ID
    fgetpos( fp, &fpos1 );

    // how many messages do we have? get message count
    do {
        memset(buffer, 0, READBUFFSIZE);

        fgets(buffer, READBUFFSIZE, fp );

        if(StartMessage(buffer)) {

            ++msgheader.msgnumber;

            // might as well get the first message number here
            if(!firstmsgflg) {
                char tmp[5] = {0};
                tmp[0] = buffer[3];
                tmp[1] = buffer[4];
                tmp[2] = buffer[5];
                tmp[3] = buffer[6];
                tmp[4] = '\0';

                msgheader.firstmsgnumber = strtol( tmp, NULL, 10 );
                msgcounter = (msgheader.firstmsgnumber - 1);

                ++firstmsgflg;

            } // end first message
        }
    } while (!feof(fp)); // end get message count

    // setup index past here free buffer and indexbuffer for exit
    indexbuffer = (unsigned short *)malloc((msgheader.msgnumber * sizeof(unsigned short)));

    lastmsgnum = (msgheader.firstmsgnumber-1) + msgheader.msgnumber;

    // bad malloc index buffer -- get out
    if(indexbuffer == NULL) {
        fclose(fp);
        free(buffer);
        ProgError(1, "MKMSGF: Index memory error.");
    } else {
        indexbufptr = indexbuffer;
        memset(indexbuffer, 0, msgheader.msgnumber);
    }

    // processed message buffer
    msgareasize = fpos2 - fpos1;
    msgsizechk  = msgareasize;

    // message buffer past here free buffer, indexbuffer, and msgbuffer for exit
    msgbuffer = (unsigned char *)malloc(msgareasize);

    // bad malloc message buffer -- get out
    if(msgbuffer == NULL) {
        fclose(fp);
        free(buffer);
        free(indexbuffer);
        ProgError(1, "MKMSGF: Msg buffer memory error.");
    } else {
        msgbuffptr = msgbuffer;
        msgrefptr  = msgbuffer;
        memset(msgbuffer, '\0', msgareasize);

        // reset msgareasize variable
        msgareasize = 0;
    }

    msgareaoff = sizeof(MSGHEADER) +
                 (sizeof(unsigned short) * msgheader.msgnumber) +
                 sizeof(FILECOUNTRYINFO);

    msgheader.countryinfo = sizeof(MSGHEADER) +
                 (sizeof(unsigned short) * msgheader.msgnumber);

    // reset file pointer to start of message area
    fseek( fp, fpos1, SEEK_SET );

    /*
       msgareasize  -- original size of input file message area
         (fpos2 - fpos1) where fpos1 is the postion in the file the message area
         starts and fpos2 is the end of file found with a seek. The processed buffer
         size is memalloc'd to this size and memset to 0. This will ensure the processed
         buffer is large enough and unused space at the end will be a NULL.
         After memalloc, I set this to 0 and keep track of characters handled

       msgsizechk intialized to msgareasize above and deincrement as charactes are processed
         and corrections until 0

       As the program runs:

       msgsizechk  should end up being zero
       msgareasize actual number processed

       -msgbuffptr pointer to the next space in RAM to store the processed character
       -buffptr pointer to the character being processed from the input file
     */

    do {
        memset(buffer, '\0', READBUFFSIZE);

        fgetpos(fp, &fpos1);

        fgets(buffer, READBUFFSIZE, fp );

        fgetpos(fp, &fpos2);

        // skip comments
        if(buffer[0] == ';') {
            int tmp = fpos2 - fpos1;
            // sub length of comment line
            msgsizechk  -= tmp;
            continue;
        }

        if(StartMessage(buffer)) {

            // here is another check
            if(  (toupper(buffer[7]) != 'E' ) &&
                 (toupper(buffer[7]) != 'H' ) &&
                 (toupper(buffer[7]) != 'I' ) &&
                 (toupper(buffer[7]) != 'P' ) &&
                 (toupper(buffer[7]) != 'W' ) &&
                 (buffer[7] != '?' ) )  {
                fclose(fp);
                free(buffer);
                free(indexbuffer);
                free(msgbuffer);
                ProgError(1, "MKMSGF: Bad message type.");
            }

            // here's a good one, the docs say the ':' is suppose to
            // be followed by a space -- however in a situation such as:
            // SYS0001E:       <-- ':' followed by 0x0D 0x0A
            // --message--
            // so I can't blindly eat the space
            if(buffer[9] == 0x0D) {
                buffptr   = &buffer[8];
                buffer[8] = buffer[7];
                msgsizechk -= 8; // sub msg id, num, etc...
            } else {
                buffptr   = &buffer[9];
                buffer[9] = buffer[7];
                msgsizechk -= 9; // sub msg id, num, etc...
            }

            // set the location in the index
            *indexbufptr++ = (msgbuffptr - msgrefptr) + msgareaoff;

            msgcounter++;

            if(msgcounter == lastmsgnum) {
                char tmp[5] = {0};

                tmp[0] = buffer[3];
                tmp[1] = buffer[4];
                tmp[2] = buffer[5];
                tmp[3] = buffer[6];
                tmp[4] = '\0';

                if(strtol( tmp, NULL, 10 ) != lastmsgnum) {
                    fclose(fp);
                    free(buffer);
                    free(indexbuffer);
                    free(msgbuffer);
                    ProgError(1, "MKMSGF: Message numbers out of sequence.");
                }
            }

        } else {
            buffptr = buffer;
        }

        // if I get NULL I probably screwed up
        for( ;*buffptr != NULL; ) {

            if(buffptr[0] == '%' && buffptr[1] == '0') {  // special %0
                buffptr += 4;
                msgsizechk -= 4;
            } else {
                *msgbuffptr = *buffptr;
                msgareasize++;
                msgbuffptr++;
                msgsizechk--;
                buffptr++;
            }
            if(msgsizechk == 0) break;  // if 0 then I sure hope I am done
        }

    } while (!feof(fp) || msgsizechk != 0);

    // close input file
    fclose(fp);

    // display verbose output
    if(verbose) {
        if(!prgheaddisp) prgheading( );  // display program heading
        printf("\n");
        printf("global variables\n");
        printf("  strIn     = %s\n", inputfile);
        printf("  strOut    = %s\n", outputfile);
        printf("  StrIncDir = ");
        if(_UnknOpt1 || _UnknOpt2) printf("%s\n", includepath);
        else printf("\n");
        printf("  CodePages = ");
        for(int i=0; i<countryinfo.codepagesnumber; i++) printf("%d ", countryinfo.codepages[i]);
        printf("\n  Language family id = %d and sub id = %d\n",
                              countryinfo.langfamilyID, countryinfo.langversionID);
        if(countryinfo.langfamilyID==0 && countryinfo.langversionID==0)
                         printf("  Language family id and sub id = unspecified\n");
        else {
            for(int i=0; langinfo[i].langfam != 0; i++) {
                if(langinfo[i].langfam == countryinfo.langfamilyID &&
                   langinfo[i].langsub == countryinfo.langversionID) {
                    printf("  Language Code = %s\n", langinfo[i].langcode);
                    printf("  Language = %s\n", langinfo[i].lang);
                    printf("  Principal Country = %s\n", langinfo[i].country);
                }
            }
        }
        printf("  CP_type   = ");
        if(countryinfo.bytesperchar == 1) printf("SBCS\n");
        else if(countryinfo.bytesperchar == 2) printf("DBCS\n");
        else printf("unknown");
        printf("\"%s\": length = %d bytes.\n", inputfile, inputsize);
        printf("%d bytes processed\n", msgareasize);
        printf("%d messages scanned.  Writing output file...\n", msgheader.msgnumber);
        printf("Size of table entry: %s\n\n", (msgheader.offset16bit == 1)?"word":"unkn");
    }

    // done with buffer
    free(buffer);

    // write output file
    fp = fopen(outputfile, "wb");
    if(fp == NULL) {
        free(indexbuffer);
        free(msgbuffer);
        ProgError(1, "MKMSGF: Unable to open output file.");
    }
    fwrite(&msgheader, sizeof(MSGHEADER), 1, fp);
    fwrite(indexbuffer, sizeof(unsigned short), msgheader.msgnumber, fp);
    fwrite(&countryinfo, sizeof(FILECOUNTRYINFO), 1, fp);
    fwrite(msgbuffer, sizeof(unsigned char), msgareasize, fp );
    fclose(fp);

    // free memory
    free(buffer);
    free(indexbuffer);
    free(msgbuffer);

    return 0;
}


/* DecodeLangOpt( )
 *
 * get and check cmd line /L option
 */
int DecodeLangOpt(char *dargs)
{
    int verchk = 0;

    if(strchr(dargs, ',') == NULL) {
        ProgError(-1, "MKMSGF: No sub id using 1 default");
        countryinfo.langversionID = 1;
        countryinfo.langfamilyID = atoi(dargs);

    } else {
        char *ptmp = NULL;

        ptmp = strtok(dargs, ",");
        countryinfo.langfamilyID  = atoi(ptmp);

        ptmp = strtok(NULL, ",");
        countryinfo.langversionID = atoi(ptmp);
    }

    if(countryinfo.langfamilyID > 34 || countryinfo.langfamilyID < 1)
        ProgError(1, "MKMSGF: Language family is outside of valid codepage range");

    for(int i=0; langinfo[i].langfam != 0; i++) {
        if(langinfo[i].langfam == countryinfo.langfamilyID)
            if(langinfo[i].langsub == countryinfo.langversionID) verchk = 1;
    }

    if(!verchk) ProgError(1, "MKMSGF: Sub id is outside of valid codepage range");

    return 1;
}


/* GetInputFile( )
 *
 * get, check, and add ext if needed
 */
void GetInputFile( void )
{
    char ext[_MAX_EXT] = {0};

    _splitpath(inputfile, NULL, NULL, NULL, ext);   // lazy way to get ext

//    strcpy(inputfile, filename);

    // check access - if not found and no ext, add ext ".txt" - check
    // access again
    if(access(inputfile, F_OK ) != 0) {                   // access in file ?
        if(strlen(ext) == 0) strcat(inputfile, ".txt");   // no! try with txt ext
        if(access(inputfile, F_OK ) != 0) {
            ProgError(1, "MKMSGF: Input file not found"); // nope error & exit
        }
    }
}


/* GetOutputFile( )
 *
 * set up output file if not provided
 */
void GetOutputFile( void )
{
    char fname[ _MAX_FNAME ];

    _splitpath(inputfile, NULL, NULL, fname, NULL );

    strcpy(outputfile, fname);
    strcat(outputfile, ".msg");
}


/* StartMessage( )
 *
 * return true if this is start of message
 */
int StartMessage(unsigned char *buffer)
{
    unsigned char *ptmp;

    // my play - if user prefix with space which they should not!
    for(ptmp = buffer;(*ptmp == ' ');) ptmp++;

    // yep, we are going to make damn sure it is a valid Component-Message Line
    if( (toupper(buffer[0]) == msgheader.identifier[0]) &&
        (toupper(buffer[1]) == msgheader.identifier[1]) &&
        (toupper(buffer[2]) == msgheader.identifier[2]) &&
        (isdigit(buffer[3]) &&
         isdigit(buffer[4]) &&
         isdigit(buffer[5]) &&
         isdigit(buffer[6]))  && (buffer[8] == ':') )  return 1;

    return 0;
}


/* GetDefaultCodePages( )
 *
 * return default system pri and sec code pages in countryinfo
 */
void GetDefaultCodePages(void)
{
    unsigned long aulCpList[8]  = {0};                        /* Code page list        */
    unsigned long ulBufSize     = 8 * sizeof(unsigned long);  /* Size of output list   */
    unsigned long ulListSize    = 0;                          /* Size of list returned */
    unsigned long indx          = 0;                          /* Loop index            */
    unsigned long rc            = 0;                          /* Return code           */


    rc = DosQueryCp(ulBufSize,      /* Length of output code page list  */
                    aulCpList,      /* List of code pages               */
                    &ulListSize);   /* Length of list returned          */

    // return if error
    if (rc != 0) {
        ProgError(-1, "MKMSGF: DosQueryCp error.");
        return;
    }

    for (indx=0; indx < ulListSize/sizeof(ULONG); indx++)
                                   countryinfo.codepages[indx] = aulCpList[indx + 1];
    countryinfo.codepagesnumber = indx - 1;
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
    if(!prgheaddisp) {
        prgheading( );  // display program heading
        prgheaddisp = 1;
    }

    printf("\n%s\n", dispmsg);

    if(exnum < 0) return;
    else {
        helpshort( );
        exit(exnum);
    }
}


/*
 * User message functions
 */
void usagelong( void )
{
    helpshort( );
    helplong( );
}


void prgheading( void )
{
    printf("\nOperating System/2 Make Message File Utility (MKMSGF) Clone\n");
    printf("Version %s  Michael Greene <mike@mgreene.org>\n", SYSLVERSION);
    printf("Compiled with Open Watcom %d.%d  %s\n", OWMAJOR, OWMINOR, __DATE__);
}


void helpshort( void )
{
    printf("\nMKMSGF infile[.ext] outfile[.ext] [-V]\n");
    printf("[-D <DBCS range or country>] [-P <code page>] [-L <language id,sub id>]\n");
}


void helplong( void )
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
    for(int i=0; langinfo[i].langfam != 0; i++)
        printf("\t%s\t%d\t%d\t%-20s\t%s\n", langinfo[i].langcode,
              langinfo[i].langfam, langinfo[i].langsub, langinfo[i].lang, langinfo[i].country);
}


