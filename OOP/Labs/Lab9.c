#include <stdio.h>
#include <stdlib.h>

unsigned int maxbyte (unsigned int num)
{
    unsigned b3 = (num >> 24) & 0xff;
    unsigned b2 = (num >> 16) & 0xff;
    unsigned b1 = (num >> 8) & 0xff;
    unsigned b0 = num & 0xff;

    unsigned int max = b0;
    if (max < b1) max = b1;
    if (max < b2) max = b2;
    if (max < b3) max = b3;
    
    return max;
    
}

int main()
{
    unsigned int n = 0x12FC3407;
    printf("Maximum byte in 0x%08X is: %u\n", n, maxbyte(n));
    return 0;
}