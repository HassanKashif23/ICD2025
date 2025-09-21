module parse #(
    parameter DATA_WIDTH = 512,
) (
    input logic clk,rst,
    input logic [DATA_WIDTH-1:0] data,
    output logic [DATA_WIDTH-1:0] parsed_data
);

logic [DATA_WIDTH-1:0] ff1,ff2,ff3;
logic [DATA_WIDTH-1:0] stage1,stage2,stage3;
logic ipv4,ipv6;

typedef struct packed {
    logic [47:0] dest_mac;
    logic [47:0] src_mac;
    logic [15:0] eth_type;
} Ethernet;

typedef struct packed {
    logic [3:0] version;
    logic [3:0] ihl;
    logic [7:0] tos;
    logic [15:0] total_length;
    logic [15:0] identification;
    logic [2:0] flags;
    logic [12:0] fragment_offset;
    logic [7:0] ttl;
    logic [7:0] protocol;
    logic [15:0] header_checksum;
    logic [31:0] src_ip;
    logic [31:0] dest_ip;
} IPv4;

typedef struct packed {
    logic [3:0] version;
    logic [7:0] traffic_class;
    logic [19:0] flow_label;
    logic [15:0] payload_length;
    logic [7:0] next_header;
    logic [7:0] hop_limit;
    logic [127:0] src_ip;
    logic [127:0] dest_ip;
} IPv6;

typedef struct packed {
    logic [47:0] dest_mac;
    logic [47:0] src_mac;
    logic [127:0] src_ip;
    logic [127:0] dest_ip;
    logic [3:0] version;
} metadata;

typedef struct packed {
    Ethernet eth;
    union {
        IPv4 ipv4;
        IPv6 ipv6;
    } ip;
} Packet;


always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        stage1 <= 0;
        stage2 <= 0;
        stage3 <= 0;
        ff1 <= 0;
        ff2 <= 0;
        ff3 <= 0;
    end else begin
        ff1 <= data;      // Input data to first stage
        stage1 <= data[111:0];      // Extract first 112 bits
        if (data[111:96] == 16'h0800) begin
            stage2 <= data[271:112];
        end else if (data[111:96] == 16'h86DD) begin
            ipv4 <= 0;
            ipv6 <= 1;
            stage2 <= data[431:112];
        end else begin
            ipv4 <= 0;
            ipv6 <= 0;
        end
        stage3 <= 0;
        ff1 <= 0;
        ff2 <= 0;
        ff3 <= 0;
    end
end
    
endmodule

                ┌────────────────────┐
AXI-Stream In → │  AXI Slave + Demux │
                └─────────┬──────────┘
                          │
     ┌────────────────────┴───────────────────┐
     │                                        │
     ▼                                        ▼
┌────────────┐                        ┌─────────────────┐
│  Pipeline  │                        │      FIFO       │
│  (Parser)  │                        │ (Payload store) │
└─────┬──────┘                        └───────┬─────────┘
      │ Metadata                               │ Payload
      │                                        │
      └──────────────────┬─────────────────────┘
                         ▼
                ┌────────────────────┐
                │ AXI Master + Align │
                │ (payload+metadata) │
                └────────────────────┘
                          │
                 AXI-Stream Out (Packet+Meta)
