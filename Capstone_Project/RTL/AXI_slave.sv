module axi4(
    input logic clk,rst,

    packet.slave input_axi,
    packet.master output_axi

);

//pipeline signals
logic pipe;
logic [15:0] byte_offset;
logic [355:0] sideband;
logic meta_valid;
logic [511:0] data;

//Fifo signals
logic full_ready,fifo_empty,fifo_wr,fifo_rd,fifo_last;
logic [512:0] fifo_in,fifo_out;
logic [511:0] dout;

//================Parser to metadata fifo connections===================//
logic meta_fifo_wr,meta_fifo_rd,meta_fifo_empty,meta_fifo_full;
logic [355:0] meta_fifo_in, meta_fifo_out; // Assuming metadata is 356 bits

// FSM signals
typedef enum logic [1:0] {IDLE, SEND_METADATA, SEND_DATA} state_t;
state_t current_state, next_state;
logic load_metadata;
logic metadata_sent;

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

//================Metadata FIFO===================//

assign meta_fifo_wr = meta_valid;
assign meta_fifo_in = sideband;

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
    .full(meta_fifo_full),
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

//=================FSM Control logic===============//

logic [1:0] beat_count;    // counts from 0 to 3
logic send_packet;         // flag to initiate packet transfer
// Check if a complete packet (meta + data) is ready to send
assign send_packet = (!meta_fifo_empty && !fifo_empty);

//FSM state register
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

// FSM next state logic

always_comb begin
    next_state = current_state;    // default stay in current state
    case (current_state)
       IDLE : begin
        if (!meta_fifo_empty && !fifo_empty) begin
            next_state = SEND_METADATA;
        end
       end
       SEND_METADATA : begin
        if (output_axi.TREADY) begin
            next_state = SEND_DATA;
        end
       end
       SEND_DATA : begin
        if (fifo_last && output_axi.TREADY) begin
            next_state = IDLE;
        end
       end
    endcase
end

// FSM output logic

always_comb begin
    meta_fifo_rd = 0;
    fifo_rd = 0;
    load_metadata = 0;
    case (current_state)
       IDLE : begin
        if (!meta_fifo_empty && !fifo_empty) begin
            meta_fifo_rd = 1; // Read metadata
            load_metadata = 1; // Indicate we are loading metadata
        end
       end
       SEND_METADATA : begin
        //  wait for slave to be ready to accept metadata
        if (output_axi.TREADY) begin
            // Metadata sent, move to sending data
            // fifo_rd will be handled in beat_count logic
        end
       end
       SEND_DATA : begin
        if (fifo_last && output_axi.TREADY) begin
            fifo_rd = 1; // Read last data beat
        end
       end
    endcase
end

//==============Latch metadata======================//
logic [355:0] latched_metadata;
always_ff @( posedge clk or posedge rst ) begin 
    if (rst) begin
        latched_metadata <= 0;
    end else if (load_metadata)begin
        latched_metadata <= meta_fifo_out;
    end
end

//===============AXI master driver===================//
always_ff @(posedge clk or posedge rst) begin 
    if (rst) begin
        output_axi.TVALID <= 0;
        output_axi.TDATA <= 0;
        output_axi.TLAST <= 0;
        output_axi.TUSER <= 0;
    end else begin
        case (current_state)
           IDLE : begin
            output_axi.TVALID <= 0;
           end
           SEND_METADATA : begin
            output_axi.TVALID <= 1'b1; // We are valid during metadata
            output_axi.TDATA <= {156'b0, latched_metadata}; // Metadata is 356 bits, pad to 512
            output_axi.TLAST <= 0; // Not last beat
            output_axi.TUSER <= 1'b1; // Indicate this is metadata
           end
           SEND_DATA : begin
            output_axi.TVALID <= 1'b1; // We are valid during data
            output_axi.TDATA <= dout;
            output_axi.TLAST <= fifo_last; // Last beat if fifo_last is set
            output_axi.TUSER <= 1'b0; // Indicate this is data
           end
        endcase
    end
end


endmodule