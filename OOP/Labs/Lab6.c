#include <stdio.h>
#include <stdlib.h>

int counter (void)
{
    static int count = 0;
    count++;
    return count;
}

int main()
{
    int c;
    c = counter();
    printf("Counter value: %d\n", c);
    c = counter();
    printf("Counter value: %d\n", c);
    c = counter();
    printf("Counter value: %d\n", c);
    return 0;
}