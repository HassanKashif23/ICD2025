module parser(
    input logic clk,rst,

    packet.slave input_axi,
    packet.master output_axi
);

//Packet parser
logic [DATA_WIDTH-1:0] ff1,ff2,ff3;
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

// Stage 1: Pipeline register for input data
always @(posedge clk or posedge rst) begin
    if (rst) begin
        stage1 <= 0;
    end else begin
        stage1 <= data;
    end
end

// Stage 2: Extract Ethernet header and determine protocol
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        eth <= '0;
        stage2 <= 0;
        ipv4 <= 0;
        ipv6 <= 0
    end else begin
        stage2 <= stage1;      // Input data to first stage
        eth.dest_mac <= stage1[47:0];   // Extract destination MAC
        eth.src_mac <= stage1[95:48];   // Extract source MAC
        eth.eth_type <= stage1[111:96]; // Extract EtherType
        case (stage1[111:96])
                16'h0800: begin ipv4 <= 1'b1; ipv6 <= 1'b0; end // IPv4
                16'h86DD: begin ipv4 <= 1'b0; ipv6 <= 1'b1; end // IPv6
                default:  begin ipv4 <= 1'b0; ipv6 <= 1'b0; end // Unsupported
            endcase
    end
end

// Stage 3: Extract IP header based on protocol
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        stage3 <= 0;
        ip4 <= '0;
        ip6 <= '0;
    end else begin
        stage3 <= stage2;   // Pipeline register
        if (ipv4) begin
             // IPv4 header starts immediately after Ethernet (offset 112)
            ip4.version        <= stage2[115:112];
            ip4.ihl            <= stage2[119:116];
            ip4.tos            <= stage2[127:120];
            ip4.total_length   <= stage2[143:128];
            ip4.identification <= stage2[159:144];
            ip4.flags          <= stage2[162:160];
            ip4.fragment_offset<= stage2[175:163];
            ip4.ttl            <= stage2[183:176];
            ip4.protocol       <= stage2[191:184];
            ip4.header_checksum<= stage2[207:192];
            ip4.src_ip         <= stage2[239:208];
            ip4.dest_ip        <= stage2[271:240];
        end else if (ipv6) begin
            // IPv6 header starts immediately after Ethernet (offset 112)
            ip6.version        <= stage2[115:112];
            ip6.traffic_class  <= stage2[123:116];
            ip6.flow_label     <= stage2[143:124];
            ip6.payload_length <= stage2[159:144];
            ip6.next_header    <= stage2[167:160];
            ip6.hop_limit      <= stage2[175:168];
            ip6.src_ip         <= stage2[303:176];
            ip6.dest_ip        <= stage2[431:304];
        end
    end
end

// Stage 4: Metadata extraction
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        stage3 <= 0;
        meta <= '0;
    end else begin
        meta.dest_mac <= eth.dest_mac;
        meta.src_mac <= eth.src_mac;
        if (ipv4) begin
            meta.dest_ip <= ip4.dest_ip;
            meta.src_ip <= ip4.src_ip;
        end else if (ipv6) begin
            meta.dest_ip <= ip6.dest_ip;
            meta.src_ip <= ip6.src_ip;
        end
    end
end

assign sideband = meta;

//AXI Master Driver for Metadata

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        output_meta_axi.TVALID <= 0;
        output_meta_axi.TDATA <= 0;
        output_meta_axi.TLAST <= 0;
    end else if (meta_valid) begin
        output_meta_axi.TVALID <= 1;
        output_meta_axi.TDATA <= sideband;
        output_meta_axi.TLAST <= 1; // Metadata is a single beat
    end else if (output_meta_axi.TREADY) begin
        output_meta_axi.TVALID <= 1'b0; // Deassert after transfer
    end
end

//AXI Master Driver for Packet+payload

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        output_data_axi.TVALID <= 0;
        output_data_axi.TDATA <= 0;
        output_data_axi.TLAST <= 0;
    end else if (fifo_rd) begin
        output_data_axi.TVALID <= 1;
        output_data_axi.TDATA <= dout;
        output_data_axi.TLAST <= fifo_last;
    end else begin
        output_data_axi.TVALID <= 0;
    end
end
    
endmodule