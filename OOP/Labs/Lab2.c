#include <stdio.h>

// Set the nth bit (0-indexed)
int set_bit(int num, int n) {
    return num | (1 << n);
}

// Clear the nth bit
int clear_bit(int num, int n) {
    return num & ~(1 << n);
}

// Toggle the nth bit
int toggle_bit(int num, int n) {
    return num ^ (1 << n);
}


// Example usage

int main() {
    int num = 0b00001010; // 10 in binary
    int bit = 1;

    printf("Original : %d\n", num);
    printf("Set bit %d : %d\n", bit, set_bit(num, bit));
    printf("Clear bit %d : %d\n", bit, clear_bit(num, bit));
    printf("Toggle bit %d : %d\n", bit, toggle_bit(num, bit));

    return 0;
}
