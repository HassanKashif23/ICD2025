#include <stdio.h>
#include <stdlib.h>

unsigned int modify (unsigned int num, unsigned int val)
{
    unsigned int val_shifted;
    unsigned int modified_num;
    num = num & 0x3fffffff;
    val_shifted = val << 30;
    modified_num = num | val_shifted;
    return modified_num;
}

int main()
{
    unsigned n=35;
    unsigned v=3;
    printf("Num= %u\n",n);
    printf("Val= %u\n",v);
    unsigned int m = modify(n,v);
    printf("Original Num = %u (0x%08X)\n", n, n);
    printf("Val = %u\n", v);
    printf("Modified Num = %u (0x%08X)\n", m, m);
    return 0;
}