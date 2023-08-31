

#include "mkmsgerr.h"

typedef struct ERRORMSG
{
    int  error_code;
    char *errormsg;
};

struct ERRORMSG mkmsgerr[] = {
    {MKMSG_INPUT_ERROR, "MKMSGD: Bad input file for decompile."},
    {MKMSG_OPEN_ERROR, "MKMSGD: Error open decompile input file."},
    {MKMSG_MEM_ERROR, "MKMSGD: Decompile mem allocate error."},
    {MKMSG_READ_ERROR, "MKMSGD: Decompile input read error."},
    {MKMSG_HEADER_ERROR, "MKMSGD: Decompile input signature error."},
    {MKMSG_INDEX_ERROR, "MKMSGD: Decompile index size != actual."}
};


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
    if (!prgheaddisp)
    {
        prgheading(); // display program heading
        prgheaddisp = 1;
    }

    printf("\n%s\n", dispmsg);

    if (exnum < 0)
        return;
    else
    {
        helpshort();
        exit(exnum);
    }
}