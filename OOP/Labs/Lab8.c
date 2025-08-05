#include <stdio.h>
#include <stdlib.h>

void binaryprint (unsigned int num)
{
    for (int i = 31; i >= 0; i--)
    {
        unsigned int mask = 1 << i;
        if (num & mask)
            printf("1");
        else
            printf("0");
    }
    printf("\n");
    
}

int main()
{
    unsigned int n = 5;
    binaryprint(n);
    printf("Binary representation of %u is: ", n);
    return 0;
}