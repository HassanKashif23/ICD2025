#ifndef IPV4_h
#define IPV4_h

#include <stdint.h>

// IPv4 header structure
typedef struct{
    uint8_t version_ihl; // Version and Internet Header Length
    uint8_t dscp_ecn;   // Differentiated Services Code Point and ECN
    uint16_t total_length; // Total Length
    uint16_t identification; // Identification
    uint16_t flags_fragment_offset; // Flags and Fragment Offset
    uint8_t ttl; // Time to Live
    uint8_t protocol; // Protocol
    uint16_t header_checksum; // Header Checksum
    uint32_t src_ip4; // Source IP Address
    uint32_t dest_ip4; // Destination IP Address
 } IPv4header;

IPv4header ip4_parser(const uint8_t *packet);
void print_ip4_header(IPv4header ip4);

#endif