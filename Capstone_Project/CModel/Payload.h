#ifndef PAYLOAD_H
#define PAYLOAD_H

#include <stdint.h>
#include <stddef.h>
#include "Ethernetheader.h"
#include "IPv4.h"
#include "IPv6.h"

#define MAX_PAYLOAD_SIZE 1500

size_t extract_payload(const uint8_t *packet, size_t packet_len, uint16_t ethertype, uint8_t *payload_out);

#endif
