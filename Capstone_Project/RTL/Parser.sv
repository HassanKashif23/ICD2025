module parser #(
    parameter DATA_WIDTH = 512
) (
    input logic clk,rst,pipe,
    input logic [15:0] byte_offset,
    input logic [DATA_WIDTH-1:0] data,
    output logic meta_valid,
    output metadata sideband
);

logic valid1,valid2,valid3,valid4;
logic [DATA_WIDTH-1:0] stage1,stage2,stage3;
logic ipv4,ipv6;


//================================
//    Structure definations
//================================

typedef struct packed {
    logic [47:0] dest_mac;
    logic [47:0] src_mac;
    logic [15:0] eth_type;
} Ethernet;
Ethernet eth;

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
IPv4 ip4;

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
IPv6 ip6;

typedef struct packed {
    logic [47:0] dest_mac;
    logic [47:0] src_mac;
    logic [127:0] src_ip;
    logic [127:0] dest_ip;
    logic [3:0] version;
} metadata;
metadata meta;

logic [31:0] eth_start; 
logic [31:0] ip4_start;
logic [31:0] ip6_start;
assign eth_start = byte_offset * 8;
assign ip4_start = (byte_offset + 14) * 8;
assign ip6_start = (byte_offset + 14) * 8;

// Stage 1: Pipeline register for input data
always @(posedge clk or posedge rst) begin
    if (rst) begin
        stage1 <= 0;
        valid1 <= 0;
    end else if (pipe) begin
        stage1 <= data;
        valid1 <= 1;
    end else begin
        valid1 <= 0;
    end
end

// Stage 2: Extract Ethernet header and determine protocol
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        eth <= '0;
        stage2 <= 0;
        ipv4 <= 0;
        ipv6 <= 0;
        valid2 <= 0;
    end else if (pipe) begin
        stage2 <= stage1;      // Input data to first stage
        valid2 <= valid1;
        eth.dest_mac <= stage1[(eth_start + 47) : (eth_start)];   // Extract destination MAC
        eth.src_mac <= stage1[(eth_start + 95) : (eth_start + 48)];   // Extract source MAC
        eth.eth_type <= stage1[(eth_start + 111) : (eth_start + 96)]; // Extract EtherType
        case (stage1[(eth_start + 111) : (eth_start + 96)])
                16'h0800: begin ipv4 <= 1'b1; ipv6 <= 1'b0; end // IPv4
                16'h86DD: begin ipv4 <= 1'b0; ipv6 <= 1'b1; end // IPv6
                default:  begin ipv4 <= 1'b0; ipv6 <= 1'b0; end // Unsupported
            endcase
    end else begin
        valid2 <= 0;
    end
end

// Stage 3: Extract IP header based on protocol
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        stage3 <= 0;
        ip4 <= '0;
        ip6 <= '0;
        valid3 <= 0;
    end else if (pipe) begin
        stage3 <= stage2;   // Pipeline register
        valid3 <= valid2;
        if (ipv4) begin
             // IPv4 header starts immediately after Ethernet (offset 112)
            ip4.version        <= stage2[(ip4_start + 3) : (ip4_start)];
            ip4.ihl            <= stage2[(ip4_start + 7) : (ip4_start + 4)];
            ip4.tos            <= stage2[(ip4_start + 15) : (ip4_start + 8)];
            ip4.total_length   <= stage2[(ip4_start + 31) : (ip4_start + 16)];
            ip4.identification <= stage2[(ip4_start + 47) : (ip4_start + 32)];
            ip4.flags          <= stage2[(ip4_start + 50) : (ip4_start + 48)];
            ip4.fragment_offset<= stage2[(ip4_start + 63) : (ip4_start + 51)];
            ip4.ttl            <= stage2[(ip4_start + 71) : (ip4_start + 64)];
            ip4.protocol       <= stage2[(ip4_start + 79) : (ip4_start + 72)];
            ip4.header_checksum<= stage2[(ip4_start + 95) : (ip4_start + 80)];
            ip4.src_ip         <= stage2[(ip4_start + 127) : (ip4_start + 96)];
            ip4.dest_ip        <= stage2[(ip4_start + 159) : (ip4_start + 128)];
        end else if (ipv6) begin
            // IPv6 header starts immediately after Ethernet (offset 112)
            ip6.version        <= stage2[(ip6_start + 3) : (ip6_start)];
            ip6.traffic_class  <= stage2[(ip6_start + 11) : (ip6_start + 4)];
            ip6.flow_label     <= stage2[(ip6_start + 31) : (ip6_start + 12)];
            ip6.payload_length <= stage2[(ip6_start + 47) : (ip6_start + 32)];
            ip6.next_header    <= stage2[(ip6_start + 55) : (ip6_start + 48)];
            ip6.hop_limit      <= stage2[(ip6_start + 63) : (ip6_start + 56)];
            ip6.src_ip         <= stage2[(ip6_start + 191) : (ip6_start + 64)];
            ip6.dest_ip        <= stage2[(ip6_start + 319) : (ip6_start + 192)];
        end 
    end else begin
        valid3 <= 0;
    end
end

// Stage 4: Metadata extraction
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        meta <= '0;
        valid4 <= 0;
    end else if (pipe) begin
        meta.dest_mac <= eth.dest_mac;
        meta.src_mac <= eth.src_mac;
        valid4 <= valid3;
        if (ipv4) begin
            meta.dest_ip <= ip4.dest_ip;
            meta.src_ip <= ip4.src_ip;
        end else if (ipv6) begin
            meta.dest_ip <= ip6.dest_ip;
            meta.src_ip <= ip6.src_ip;
        end
    end else begin
        valid4 <= 0;
    end
end

assign meta_valid = valid4;
assign sideband = meta;

endmodule
    
