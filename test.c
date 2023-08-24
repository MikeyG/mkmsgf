
#define INCL_DOSNLS     /* National Language Support values */

#include <os2.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <io.h>
#include <sys\stat.h>
#include <unistd.h>
//#include "mkmsgf.h"
#include "version.h"


#define READBUFFSIZE    1024

#include "msh.h"


/* main( )
 *
 * Entry into the program
 */
int main(int argc, char *argv[ ])
{
    int  ch          = 0;               // getopt variable
 
    // Get program arguments using getopt()
    while ((ch = getopt(argc, argv, "d:D:p:P:l:L:VvHhI:i:AaCcq")) != -1) {

        switch (ch) {

        case 'd':
        case 'D':
            // ProgError(1, "MKMSGF: DBCS not supported");
            break;

        case 'p':
        case 'P':
            //if(countryinfo.codepagesnumber < 16) {
            //    countryinfo.codepages[countryinfo.codepagesnumber++] = atoi(optarg);
            //} else ProgError(1, "MKMSGF: More than 16 codepages entered");
            break;

        case 'l':
        case 'L':
            //if(proclang) ProgError(1, "MKMSGF: Syntax error L option");
            //proclang = DecodeLangOpt(optarg);
            break;

        case 'v':
        case 'V':
            //if(!verbose) ++verbose;
            break;

        case 'h':
        case 'H':
            //prgheading( );
            //usagelong( );
            exit(0);
            break;

        // Undocumented IBM flags - here but not used

        case 'i':                   // change used include path, I think for A and C
        case 'I':
            //includepath = optarg;
            break;

        case 'a':                   // the real mkmsgf outputs asm file
        case 'A':
            //if(!_UnknOpt1) _UnknOpt1++;
            break;

        case 'c':                   // the real mkmsgf outputs C file
        case 'C':
            //if(!_UnknOpt2) _UnknOpt2++;
            break;

        // my added option
        case 'q':
        case 'Q':
            //if(!dispquiet) ++dispquiet;
            break;

        default:
            //ProgError(1, "MKMSGF: Syntax error unknown option");
            break;
        }
    }

    // quiet flag
    //if(dispquiet) --verbose;

    // check for input file - getopt compatable cmd line
    if ((argc == optind) && !procinfile) exit(1); //ProgError(1, "MKMSGF: no input file");
/*
    if (!procinfile) {
        char *ptmp = argv[optind];

        for( int i=0; i<strlen(argv[optind]); i++) inputfile[i] = *ptmp++;
        GetInputFile( );
        optind++;
        if(argc == optind) GetOutputFile( );
        else strcpy(outputfile, argv[optind]);
    }
*/
    // ************ done with args ************
    //printf("%s", argv[0][1]);

    return 1;
}
