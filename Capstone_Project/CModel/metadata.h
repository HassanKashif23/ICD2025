// metadata.h

#ifndef METADATA_H
#define METADATA_H
#include "Ethernetheader.h"
#include "IPv4.h"
#include "IPv6.h"
#include <stdint.h>

typedef struct 
{
    uint8_t src_mac[6];         // Source MAC Address
    uint8_t dest_mac[6];        // Destination MAC Address
    uint16_t ethertype;        // Ethertype
    //uint8_t protocol;
    uint32_t src_ip4;
    uint32_t dest_ip4;
    //uint16_t total_length;
    uint8_t src_ip6[16];       // Source IPv6 Address
    uint8_t dest_ip6[16];      // Destination IPv6 Address
} Metadata;


Metadata extract_metadata(EthernetHeader eth, const uint8_t *packet);
void print_metadata(Metadata meta);

#endif
