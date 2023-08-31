
#include <stdio.h>

#include <malloc.h>

void main()
{

    unsigned long msglenbuffer = 80;      // track size of message read buffer
    unsigned long current_msg_len = 1007; // current msg length

    // write write len: 1007   buff size: 892

    msglenbuffer = 1007;

    // write buffer early to msglenbuffer bytes - realloc later
    char *write_buffer = (char *)calloc(msglenbuffer, sizeof(char));
    if (write_buffer == NULL)
        return;

    // check write buffer size -- Do we need a bigger buffer?
    if ((current_msg_len + 10) > _msize(write_buffer))
    {
        write_buffer = (char *)realloc(write_buffer, (current_msg_len + 10));
        if (write_buffer == NULL)
            return;
    }
}