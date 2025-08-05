#include <stdio.h>

//#define IS_SIGNED(a,b) ((a) > (b) ? (a) : (b))
#define IS_SIGNED(type) (((type)-1) < 0)

int num1 = 10;
signed int num2 = -20;
unsigned int num3 = 30;

int main() {
    printf("Num = %d\n",IS_SIGNED(0));
    printf("Num1 = %d\n",num1);
    printf("Num2 = %d\n",num2);
    printf("Num3 = %u\n",num3);
    

    printf("Size of num1 = %d bytes\n", sizeof(num1));
    printf("Size of num2 = %d bytes\n", sizeof(num2));
    printf("Size of num3 = %d bytes\n", sizeof(num3));
    return 0;
}

