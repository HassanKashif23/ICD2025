module axi4(
    input logic clk,rst,

    packet.slave input_axi,
    packet.master output_axi,
    packet.master output_meta_axi,      //Metadata stream
    packet.master output_data_axi       //Packet+payload stream
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
assign pipe_ready = (!output_meta_axi.TVALID || output_meta_axi.TREADY) &&
                    (!output_data_axi.TVALID || output_data_axi.TREADY);
assign input_axi.TREADY = !full_ready && pipe_ready;
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

assign fifo_wr = input_axi.TVALID && input_axi.TREADY;   // Write when input is valid and ready
assign fifo_rd = output_data_axi.TREADY && !fifo_empty;   // Read when output is ready and fifo is not empty
assign fifo_in = {input_axi.TLAST, input_axi.TDATA};   // Concatenate TLAST with TDATA for FIFO input
assign dout = fifo_out[511:0];                 // Extract TDATA from FIFO output
assign fifo_last = fifo_out[512];         // Extract TLAST from FIFO output

delayfifo #(
    .DBIT(513),
    .DEPTH(16)
) fifo_dut (
    .clk(clk),
    .rst(rst),
    .wr_en(fifo_wr),
    .rd_en(fifo_rd),
    .wr_data(fifo_in)
    .rd_data(fifo_out),
    .full(full_ready),
    .empty(fifo_empty)
);

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