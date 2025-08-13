#ifndef EthernetHeader_h
#define EthernetHeader_h

#include <stdint.h>

// Ethernet header structure
// Ethernet header structure
typedef struct {
    uint8_t dest_mac[6];
    uint8_t src_mac[6];
    uint16_t ethertype;
} EthernetHeader;

EthernetHeader packet_parser(const uint8_t *packet);
void print_header(EthernetHeader eth);

#endif