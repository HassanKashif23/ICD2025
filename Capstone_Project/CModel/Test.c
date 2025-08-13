#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

int main()
{
    uint8_t packet[] = {
    //Ethernet header
    0x00, 0x0A, 0x35, 0x22, 0x33, 0x44,     // Dest MAC
    0x00, 0x0B, 0x6C, 0x12, 0x34, 0x56,     // Source MAC
    0x08, 0x00,

     // IPv4 Header (20 bytes)
    0x45, 0x00, 0x00, 0x3C,                 // Version/IHL, DSCP, Total Length = 0x003C
    0x00, 0x00, 0x40, 0x00,                 // Identification, Flags, Fragment Offset
    0x40, 0x06, 0xB1, 0xE6,                 // TTL, Protocol = 0x06 (TCP), Header checksum
    0xC0, 0xA8, 0x01, 0x01,                 // Source IP = 192.168.1.1
    0xC0, 0xA8, 0x01, 0x02,                 // Destination IP = 192.168.1.2

    // Payload...
    0x48, 0x65, 0x6C, 0x6C, 0x6F            // "Hello"
};

printf("Destination MAC: ");
for (int i = 0; i < 6; i++)
{
    printf("%02X", packet[i]); // Print Ethernet header
    //printf("\n");
    if(i<5) printf(":");
}
printf("Source MAC: ");
for (int i = 6; i < 12; i++)
{
    printf("%02X", packet[i]); // Print Ethernet header
    //printf("\n");
    if(i<11) printf(":");
}

printf("\n");

uint16_t ethertype = (packet[12] << 8) | packet[13];
printf("Ethertype: 0x%04X\n", ethertype);

if (ethertype == 0x0800) // Check if Ethertype is IPv4
{
    printf("Ethertype: IPv4 (0x0800)\n");
}
else if (ethertype == 0x86DD) // Check if Ethertype is IPv6
{
    printf("Ethertype: IPv6 (0x86DD)\n");
}
else
{
    printf("Ethertype: Unknown (0x%04X)\n", ethertype);
}


return 0;
}