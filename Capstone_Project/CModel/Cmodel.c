#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "EthernetHeader.h"
#include "IPv4.h"
#include "metadata.h"
#include "IPv6.h"


int main()
{
    uint8_t packet[] = {
    //Ethernet header
    0xC2, 0x00, 0x68, 0xB3, 0x00, 0x01,     // Dest MAC
    0xC2, 0x01, 0x68, 0xB3, 0x00, 0x01,     // Source MAC
    0x08, 0x00, /*0x86, 0xDD,*/ 

     // IPv4 Header (20 bytes)
    0x45, 0x00, 0x00, 0x3C,                 // Version/IHL, DSCP, Total Length = 0x003C
    0x00, 0x00, 0x40, 0x00,                 // Identification, Flags, Fragment Offset
    0x40, 0x06, 0xB1, 0xE6,                 // TTL, Protocol = 0x06 (TCP), Header checksum
    0xC0, 0xA8, 0x01, 0x01,                 // Source IP = 192.168.1.1
    0xC0, 0xA8, 0x01, 0x02,                 // Destination IP = 192.168.1.2

    // IPv6 Header (40 bytes)
    // 0x6E, 0x00, 0x00, 0x00,         // Version, Traffic Class, Flow Label
    // 0x00, 0x34, 0x33, 0x01,     // Payload Length = 0x0034, Next Header = 0x33 (ICMPv6), Hop Limit = 0x01
    // 0xFE, 0x80, 0x00, 0x00,    // Source IPv6 Address
    // 0x00, 0x00, 0x00, 0x00,
    // 0x00, 0x00, 0x00, 0x00, 
    // 0x00, 0x00, 0x00, 0x02, 
    // 0xFE, 0x80, 0x00, 0x00,   // Destination IPv6 Address
    // 0x00, 0x00, 0x00, 0x00, 
    // 0x00, 0x00, 0x00, 0x00, 
    // 0x00, 0x00, 0x00, 0x01,

    // Payload...
    0x49, 0x20, 0x41, 0x4D, 0x20,            // "Hello"
    0x42, 0x41, 0x54, 0x4D, 0x41,// Padding
    0x4E, 0x20, 0x20, 0x20, 0x20,// Padding
    0x20, 0x20, 0x20, 0x20, 0x20, // Padding
};

uint8_t *payload;
size_t payload_size = 0;
uint8_t* saved_payload;

EthernetHeader eth = packet_parser(packet);
print_header(eth);
if (eth.ethertype == 0x0800) { // IPv4
    printf("Detected IPv4 packet\n");
    IPv4header ip4 = ip4_parser(packet);    // Parse IPv4 header
    print_ip4_header(ip4);
    Metadata meta = extract_metadata(eth, packet);  // Extract metadata
    print_metadata(meta);
    printf("\n");
    //Payload extraction
    uint8_t ip_header_length = (ip4.version_ihl & 0x0F) * 4; // IHL in bytes
    payload = (uint8_t *)(packet + 14 + ip_header_length); // Skip Ethernet and IPv4 headers
    payload_size = sizeof(packet) - (14 + ip_header_length); // Calculate payload size
    printf("IPv4 Payload size: %zu bytes\n", payload_size);
    printf("Payload: \n");
    for (size_t i = 0; i < payload_size; i++){
        printf("%02x ",payload[i]);
        if ((i + 1) % 16 == 0) printf("\n");
    }
    printf("\n");
    saved_payload = malloc(payload_size); // Save payload for further processing if needed
    memcpy(saved_payload, payload, payload_size);
    printf("%s", saved_payload);

}
else if (eth.ethertype == 0x86DD) { // IPv6
    printf("Detected IPv6 packet\n");
    IPv6header ip6 = ip6_parser(packet);    // Parse IPv6 header
    print_ip6_header(ip6);
    Metadata meta = extract_metadata(eth, packet);  // Extract metadata
    print_metadata(meta);
    //Payload extraction
    size_t ip6_header_length = 40;
    payload = (uint8_t *)(packet + 14 + ip6_header_length); // Skip Ethernet and IPv6 headers
    payload_size = sizeof(packet) - (14 + ip6_header_length); // Calculate payload size
    printf("IPv6 Payload size: %zu bytes\n", payload_size);
        for (size_t i = 0; i < payload_size; i++){
        printf("%02x ",payload[i]);
        if ((i + 1) % 16 == 0) printf("\n");
    }
    printf("\n");
    saved_payload = malloc(payload_size); // Save payload for further processing if needed
    memcpy(saved_payload, payload, payload_size);
    printf("%s", saved_payload);
}



return 0;
}

// gcc Cmodel.c EthernetHeader.c IPv4.c metadata.c -o output/output.exe
//./output/output.exe

//Ethernet = C2 00 68 B3 00 01 C2 01 68 B3 00 01 86 DD
//IPv4 = 45 C0 00 30 00 00 00 00 01 11 18 35 C0 A8 00 1E E0 00 00 02
//IPv6 = 6E 00 00 00 00 34 33 01 FE 80 00 00 00 00 00 00 
//00 00 00 00 00 00 00 02 FE 80 00 00 00 00 00 00 00 00 00 00 00 00 00 01