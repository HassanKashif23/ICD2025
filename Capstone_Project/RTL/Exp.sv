module axi4(
    input logic clk,rst,

    packet.slave input_axi,
    packet.master output_axi

);

//pipeline signals
logic pipe_ready,pipe;
logic [15:0] byte_offset;
logic [355:0] sideband;
logic meta_valid;
logic [511:0] data;

//Fifo signals
logic full_ready,fifo_empty,fifo_wr,fifo_rd,fifo_last;
logic [512:0] fifo_in,fifo_out;
logic [511:0] dout;

//================Handshaking===================//
// assign pipe_ready = (output_meta_axi.TVALID && output_meta_axi.TREADY)||~output_meta_axi.TVALID;
// assign pipe_ready = (!output_axi.TVALID || output_axi.TREADY);
assign input_axi.TREADY = !full_ready && !meta_fifo_full;
assign pipe = input_axi.TVALID && input_axi.TREADY;
assign data = input_axi.TDATA;

//================Byte Counter===================//
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        byte_offset <= 0;
    end else if (pipe) begin
        // On the beat where TLAST is received, reset for next packet
        if (input_axi.TLAST) begin
            byte_offset <= 0;
        end else begin
            // Increment offset by the number of bytes received this beat
            byte_offset <= byte_offset + 64;
        end
    end
end

//================Packet Parser Instance===================//
parser #(
    .DATA_WIDTH(512)
) parser_dut (
    .clk(clk),
    .rst(rst),
    .pipe(pipe),
    .byte_offset(byte_offset),
    .data(data),
    .meta_valid(meta_valid),
    .sideband(sideband)
);

//================Parser to metadata fifo connections===================//
logic meta_fifo_wr,meta_fifo_rd,meta_fifo_empty,meta_fifo_full;
logic [355:0] meta_fifo_in, meta_fifo_out; // Assuming metadata is 356 bits
assign meta_fifo_wr = meta_valid;
assign meta_fifo_in = sideband;

//================Metadata FIFO===================//
delayfifo #(
    .DBIT(356),
    .DEPTH(16)
) meta_fifo (
    .clk(clk),
    .rst(rst),
    .wr_en(meta_fifo_wr),
    .rd_en(meta_fifo_rd),
    .wr_data(meta_fifo_in),
    .rd_data(meta_fifo_out),
    .full(),
    .empty(meta_fifo_empty)
);

//================Payload FIFO Connections===================//
assign fifo_wr = input_axi.TVALID && input_axi.TREADY;   // Write when input is valid and ready
assign fifo_in = {input_axi.TLAST, input_axi.TDATA};   // Concatenate TLAST with TDATA for FIFO input
assign dout = fifo_out[511:0];                 // Extract TDATA from FIFO output
assign fifo_last = fifo_out[512];         // Extract TLAST from FIFO output

//================Payload FIFO Instance===================//
delayfifo #(
    .DBIT(513),
    .DEPTH(16)
) fifo_dut (
    .clk(clk),
    .rst(rst),
    .wr_en(fifo_wr),
    .rd_en(fifo_rd),
    .wr_data(fifo_in),
    .rd_data(fifo_out),
    .full(full_ready),
    .empty(fifo_empty)
);

//=================Control logic===============//
logic [1:0] beat_count;    // counts from 0 to 3
logic send_packet;         // flag to initiate packet transfer
// Check if a complete packet (meta + data) is ready to send
assign send_packet = (!meta_fifo_empty && !fifo_empty);

// State machine for fifo reading and beat counting
always_ff @(posedge clk or posedge rst) begin 
    if (rst) begin
        beat_count <= 0;
        meta_fifo_rd <= 0;
        fifo_rd <= 0;
    end else begin
        // defaults
        meta_fifo_rd <= 0;
        fifo_rd <= 0;
        if (output_axi.TREADY || !output_axi.TVALID) begin
            case (beat_count)
              0 : begin                     // IDLE state / About to send Beat 0
                if (send_packet) begin
                    beat_count <= 1;        // Move to Beat 1
                    meta_fifo_rd <= 1;      // Read metadata
                end
              end
              1 : begin                     // Just sent Beat 0, now prepping Beat 1
                if (send_packet) begin
                    beat_count <= 2;        // Move to Beat 2
                    fifo_rd <= 1;           // Read first data beat
                end
              end
              2 : begin                     // Just sent Beat 1, now prepping Beat 2
                if (send_packet) begin
                    beat_count <= 3;        // Move to Beat 3
                    fifo_rd <= 1;           // Read second data beat
                end
              end
              3 : begin                     // Just sent Beat 2, now prepping Beat 3
                if (send_packet) begin
                    beat_count <= 0;        // Packet done, return to IDLE
                    fifo_rd <= 1;           // Read third and last data beat
                end
              end
            endcase
        end
    end
end

//================AXI Master Drivers===================//
always @(posedge clk or posedge rst) begin
    if (rst) begin
        output_axi.TVALID <= 0;
        output_axi.TDATA <= 0;
        output_axi.TLAST <= 0;
        output_axi.TUSER <= 0;
    end else if (output_axi.TREADY || !output_axi.TVALID) begin
        // If slave is ready or we are not valid, we can update the output
        output_axi.TVALID <= 1'b1; // We are always valid during a packet

        case (beat_count)
           0 : begin
            output_axi.TDATA <= {156'b0, meta_fifo_out}; // Metadata is 356 bits, pad to 512
            output_axi.TLAST <= 0; // Not last beat
            output_axi.TUSER <= 1'b1; // Indicate this is metadata
           end
           1 : begin
            output_axi.TDATA <= dout;
            output_axi.TLAST <= 0; // Not last beat
            output_axi.TUSER <= 1'b0; // Indicate this is data
           end
           2 : begin
            output_axi.TDATA <= dout;
            output_axi.TLAST <= 0; // Not last beat
            output_axi.TUSER <= 1'b0; // Indicate this is data
           end
           3 : begin
            output_axi.TDATA <= dout;
            output_axi.TLAST <= fifo_last; // Last beat if fifo_last is set
            output_axi.TUSER <= 1'b0; // Indicate this is data
           end
        endcase
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
