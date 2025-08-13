#include <stdio.h>
#include <string.h>
#include "metadata.h"

// void extract_metadata(const ethernet_header *eth, const ipv4_header *ip, metadata *meta) {
//     // Copy source and destination MAC addresses
//     memcpy(meta->src_mac, eth->src_mac, sizeof(meta->src_mac));
//     memcpy(meta->dest_mac, eth->dest_mac, sizeof(meta->dest_mac));
//     // Set Ethertype
//     meta->ethertype = eth->ethertype;


Metadata extract_metadata(EthernetHeader eth, const uint8_t *packet)
{
    Metadata meta;

    memcpy(meta.src_mac, eth.src_mac, 6);
    memcpy(meta.dest_mac, eth.dest_mac, 6);
    meta.ethertype = eth.ethertype;
    if (eth.ethertype == 0x0800)  // IPv4
    {
       IPv4header ip4 = ip4_parser(packet);
       meta.src_ip4 = ip4.src_ip4;
       meta.dest_ip4 = ip4.dest_ip4;
    }
    else if (eth.ethertype == 0x86DD) // IPv6
    {
       IPv6header ip6 = ip6_parser(packet);
       memcpy(meta.src_ip6, ip6.src_ip6, 16);
       memcpy(meta.dest_ip6, ip6.dest_ip6, 16);
    }
    // printf("===== Metadata =====\n");
    // printf("Source MAC: %02X:%02X:%02X:%02X:%02X:%02X\n",
    //        meta.src_mac[0], meta.src_mac[1], meta.src_mac[2],
    //        meta.src_mac[3], meta.src_mac[4], meta.src_mac[5]);

    // printf("Destination MAC: %02X:%02X:%02X:%02X:%02X:%02X\n",
    //        meta.dest_mac[0], meta.dest_mac[1], meta.dest_mac[2],
    //        meta.dest_mac[3], meta.dest_mac[4], meta.dest_mac[5]);

    // printf("Ethertype: 0x%04X\n", meta.ethertype);

    // if (eth.ethertype == 0x0800)  // IPv4
    // {
    //    printf("Source IP: %u.%u.%u.%u\n",
    //        (meta.src_ip >> 24) & 0xFF, (meta.src_ip >> 16) & 0xFF,
    //        (meta.src_ip >> 8) & 0xFF, meta.src_ip & 0xFF);
    //    printf("Destination IP: %u.%u.%u.%u\n",
    //        (meta.dest_ip >> 24) & 0xFF, (meta.dest_ip >> 16) & 0xFF,
    //        (meta.dest_ip >> 8) & 0xFF, meta.dest_ip & 0xFF);
    // }
    // else if (eth.ethertype == 0x86DD) // IPv6
    // {
    //    printf("Source IPv6 Address: ");
    // for (int i = 0; i < 16; i++) {
    //     printf("%d", ip6.src_ip6[i]);
    //     if (i < 15) printf(":");
    // }
    // printf("\nDestination IPv6 Address: ");
    // for (int i = 0; i < 16; i++) {
    //     printf("%d", ip6.dest_ip6[i]);
    //     if (i < 15) printf(":");
    // }
    // }

    
    //meta.protocol = ip.protocol;
//     meta.src_ip = ip.src_ip4;
//     meta.dest_ip = ip.dest_ip4;
    //meta.total_length = ip.total_length;

    return meta;
}


void print_metadata(Metadata meta) {
    printf("===== Metadata =====\n");
    printf("Source MAC: %02X:%02X:%02X:%02X:%02X:%02X\n",
           meta.src_mac[0], meta.src_mac[1], meta.src_mac[2],
           meta.src_mac[3], meta.src_mac[4], meta.src_mac[5]);

    printf("Destination MAC: %02X:%02X:%02X:%02X:%02X:%02X\n",
           meta.dest_mac[0], meta.dest_mac[1], meta.dest_mac[2],
           meta.dest_mac[3], meta.dest_mac[4], meta.dest_mac[5]);

    printf("Ethertype: 0x%04X\n", meta.ethertype);

    if (meta.ethertype == 0x0800)  // IPv4
    {
       printf("Source IP: %u.%u.%u.%u\n",
           (meta.src_ip4 >> 24) & 0xFF, (meta.src_ip4 >> 16) & 0xFF,
           (meta.src_ip4 >> 8) & 0xFF, meta.src_ip4 & 0xFF);
       printf("Destination IP: %u.%u.%u.%u\n",
           (meta.dest_ip4 >> 24) & 0xFF, (meta.dest_ip4 >> 16) & 0xFF,
           (meta.dest_ip4 >> 8) & 0xFF, meta.dest_ip4 & 0xFF);
    }
    else if (meta.ethertype == 0x86DD) // IPv6
    {
       printf("Source IPv6 Address: ");
    for (int i = 0; i < 16; i++) {
        printf("%d", meta.src_ip6[i]);
        if (i < 15) printf(":");
    }
    printf("\nDestination IPv6 Address: ");
    for (int i = 0; i < 16; i++) {
        printf("%d", meta.dest_ip6[i]);
        if (i < 15) printf(":");
    }
    }
    
    

    
}