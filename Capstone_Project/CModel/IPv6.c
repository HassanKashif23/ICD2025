#include <stdio.h>
#include <string.h>
#include "IPv6.h"

// Function to parse ip6v4 header from packet
IPv6header ip6_parser(const uint8_t *packet)
{
    IPv6header ip6;

    ip6.version = (packet[14] >> 4); // Version
    ip6.traffic_class = ((packet[14] & 0x0F) << 4) |  (packet[15] >> 4); // Traffic Class
    ip6.flow_label = ((packet[15] & 0x0F) << 16) | (packet[16] << 8) | packet[17]; // Flow Label
    ip6.payload_length = (packet[18] << 8) | packet[19]; // Payload Length
    ip6.next_header = packet[20]; // Next Header
    ip6.hop_limit = packet[21]; // Hop Limit
    memcpy(ip6.src_ip6, &packet[22],16); // Source IPv6 Address
    memcpy(ip6.dest_ip6, &packet[38],16); // Destination IPv6 Address

    return ip6;
}

// Function to print ip6v4 header information
void print_ip6_header(IPv6header ip6)
{
    printf("============ip6v4 Header:============\n");
    printf("Version: %d\n", ip6.version);
    printf("Traffic Class: %d\n", ip6.traffic_class);
    printf("Flow Label: %d\n", ip6.flow_label);
    printf("Payload Length: %d bytes\n", ip6.payload_length);
    printf("Next Header: %d\n", ip6.next_header);
    printf("Hop Limit: %d\n", ip6.hop_limit);
    printf("Source IPv6 Address: ");
    for (int i = 0; i < 16; i++) {
        printf("%d", ip6.src_ip6[i]);
        if (i < 15) printf(":");
    }
    printf("\nDestination IPv6 Address: ");
    for (int i = 0; i < 16; i++) {
        printf("%d", ip6.dest_ip6[i]);
        if (i < 15) printf(":");
    }
    printf("\n==============================================\n");
    printf("\n");
}