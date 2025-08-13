#include <stdio.h>
#include <string.h>
#include "IPv4.h"

// Function to parse ip4v4 header from packet
IPv4header ip4_parser(const uint8_t *packet)
{
    IPv4header ip4;

    ip4.version_ihl = packet[14]; // Version and IHL
    ip4.dscp_ecn = packet[15]; // DSCP and ECN
    ip4.total_length = (packet[16] << 8) | packet[17]; // Total Length
    ip4.identification = (packet[18] << 8) | packet[19]; // Identification
    ip4.flags_fragment_offset = (packet[20] << 8) | packet[21]; // Flags and Fragment Offset
    ip4.ttl = packet[22];
    ip4.protocol = packet[23]; // Protocol
    ip4.header_checksum = (packet[24] << 8) | packet[25]; // Header Checksum
    ip4.src_ip4 = (packet[26] << 24) | (packet[27] << 16) | (packet[28] << 8) | (packet[29]); // Source ip4
    ip4.dest_ip4 = (packet[30] << 24) | (packet[31] << 16) | (packet[32] << 8) | (packet[33]); // Destination ip4

    return ip4;
}

// Function to print ip4v4 header information
void print_ip4_header(IPv4header ip4)
{
    printf("============ip4 Header:============\n");
    uint8_t version = (ip4.version_ihl >> 4); // Extract version
    uint8_t ihl = (ip4.version_ihl & 0x0f); // Extract IHL
    uint8_t dscp = (ip4.dscp_ecn >> 2); // Extract DSCP
    uint8_t ecn = (ip4.dscp_ecn & 0x03); // Extract ECN

    printf("ip4 Header:\n");
    printf("Version: %d\n", version);
    printf("IHL: %d (in 32-bit words)\n", ihl);
    printf("DSCP: %d\n", dscp);
    printf("ECN: %d\n", ecn);
    printf("Total Length: %d bytes\n", ip4.total_length);
    printf("Identification: 0x%04X\n", ip4.identification);
    printf("Flags and Fragment Offset: 0x%04X\n", ip4.flags_fragment_offset);
    printf("TTL: %d\n", ip4.ttl);
    printf("Protocol: %d\n", ip4.protocol);
    printf("Header Checksum: 0x%04X\n", ip4.header_checksum);
    printf("Source ip4: %d.%d.%d.%d\n",
           (ip4.src_ip4 >> 24) & 0xFF, (ip4.src_ip4 >> 16) & 0xFF,
            (ip4.src_ip4 >> 8) & 0xFF, ip4.src_ip4 & 0xFF);
    printf("Destination ip4: %d.%d.%d.%d\n",
           (ip4.dest_ip4 >> 24) & 0xFF, (ip4.dest_ip4 >> 16) & 0xFF,
            (ip4.dest_ip4 >> 8) & 0xFF, ip4.dest_ip4 & 0xFF);
    printf("\n");
    printf("\n");
}