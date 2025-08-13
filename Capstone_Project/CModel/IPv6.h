#ifndef IPV6_h
#define IPV6_h

#include <stdint.h>

// IPv6 header structure
typedef struct{
    uint8_t version; // Version
    uint8_t traffic_class; // Traffic Class
    uint32_t flow_label; // Flow Label
    uint16_t payload_length; // Payload Length
    uint8_t next_header; // Next Header
    uint8_t hop_limit; // Hop Limit
    uint8_t src_ip6[16]; // Source IPv6 Address
    uint8_t dest_ip6[16]; // Destination IPv6 Address
} IPv6header;

IPv6header ip6_parser(const uint8_t *packet);
void print_ip6_header(IPv6header ip6);

#endif