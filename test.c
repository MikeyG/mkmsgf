
#include <os2.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "msh.h"


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

    /*
     * The following is to just keep the input options getopt and IBM mkmsgf
     * compatable
     */

    // is the input file first? yes, make compatable with IBM program
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
    printf("%s", argv[0][1]);

    return 1;
}