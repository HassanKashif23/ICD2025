#include <stdio.h>
#include <stdint.h>

// Function to convert little-endian to big-endian
uint32_t convert_endian(uint32_t num) {
    return ((num >> 24) & 0x000000FF) |  // byte 3 to byte 0
           ((num >> 8)  & 0x0000FF00) |  // byte 2 to byte 1
           ((num << 8)  & 0x00FF0000) |  // byte 1 to byte 2
           ((num << 24) & 0xFF000000);   // byte 0 to byte 3
}

int main() {
    uint32_t num = 0x45671234;
    uint32_t result = convert_endian(num);

    printf("Original: 0x%08X\n", num);
    printf("Converted: 0x%08X\n", result);

    return 0;
}
