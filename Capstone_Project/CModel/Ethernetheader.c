#include <stdio.h>
#include <string.h>
#include "EthernetHeader.h"

// Function to parse Ethernet header from packet
EthernetHeader packet_parser(const uint8_t *packet)
{
    EthernetHeader header;
    for (int i = 0; i<6; i++)
    {
        header.dest_mac[i] = packet[i]; // Copy destination MAC
        header.src_mac[i] = packet[i+6]; // Copy source MAC
    }
    header.ethertype = (packet[12] << 8) | packet[13]; // Combine bytes for Ethertype
    return header;
}

// Function to print Ethernet header information
void print_header(EthernetHeader eth)
{
    printf("=========Ethernet Header=======\n");
    printf("Destination MAC: ");
    for(int i = 0; i<6; i++)
    {
        printf("%02x",eth.dest_mac[i]);
        if(i < 5) printf(":");
    }
    printf("\nSource MAC: ");
    for(int i = 0; i<6; i++)
    {
        printf("%02x",eth.src_mac[i]);
        if(i < 5) printf(":");
    }
    printf("\n");
    
    if (eth.ethertype == 0x0800) // Check if Ethertype is IPv4
    {
        printf("Ethertype: IPv4 (0x0800)\n");
    }
    else if (eth.ethertype == 0x86DD) // Check if Ethertype is IPv6
    {
        printf("Ethertype: IPv6 (0x86DD)\n");
    }
    else
    {
        printf("Ethertype: Unknown (0x%04X)\n", eth.ethertype);
    }
    printf("\n");
    printf("\n");
}