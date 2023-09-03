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

int main()
{
    char *filename = ".\\w\\OSO001.txt";

    MESSAGEINFO messageinfo; // holds all the info

    // open input file
    FILE *fpi = fopen(filename, "rb");
    if (fpi == NULL)
        return (MKMSG_OPEN_ERROR);

    // buffer to read in a message r
    //    char *read_buffer = (char *)calloc(80, sizeof(char));
    //    if (read_buffer == NULL)
    //        return (MKMSG_MEM_ERROR);

    size_t buffer_size = 0;
    char *read_buffer = NULL;

    // get identifer and save
    while (TRUE)
    {
        size_t n = 0;
        char *line = NULL;

        getline(&line, &n, fpi);
        if (line[0] != ';')
        {
            if (strlen(line) > 5) // identifer (3) + 0x0D 0x0A (2)
                exit(99);
            messageinfo.identifier[0] = line[0];
            messageinfo.identifier[1] = line[1];
            messageinfo.identifier[2] = line[2];
            break;
        }
    }

    for (x = 0, first = 1;; x++)
    {
        // this should be the first message line
        getline(&read_buffer, &buffer_size, fpi);

        if (first) // first message - get start number
        {
            
        }
    }
    printf("%d  %s\n", strlen(messageinfo.identifier), messageinfo.identifier);
    printf("%s", read_buffer);

    fclose(fpi);
    free(read_buffer);
}
