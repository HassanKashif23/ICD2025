#include <stdio.h>

int main() {
    // int x = 11;
    // int *ptr = &x; // pointer to x

    // printf("Value of x: %d\n", x);
    // printf("Address of x: %p\n", &x);
    // printf("Value of ptr (address of x): %p\n", ptr);
    // printf("Value pointed to by ptr: %d\n", *ptr);

    // int c = 5;
    // int *p = &c;

    // printf("Value of c: %d\n", c);
    // printf("Address pf c: %p\n", p);
    // printf("Value pointed by pointer p: %d\n", *p);

    int a = 15;
    int *p = &a;
    a = 1;
    printf("Value of a: %d\n", a);          // Output: 1
    printf("Value pointed to by p: %d\n", *p); // Output:

    return 0;
}