#include <stdio.h>

#define ABS(x) ((x) < 0 ? -(x) : (x))

int main() {
    int a = -10;
    int b = 5;

    printf("ABS(%d) = %d\n", a, ABS(a));  // ABS(-10) = 10
    printf("ABS(%d) = %d\n", b, ABS(b));  // ABS(5) = 5

    return 0;
}
