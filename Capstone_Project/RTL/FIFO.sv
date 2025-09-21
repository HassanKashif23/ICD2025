module delayfifo #(
    parameter DBIT  = 513,
    parameter DEPTH = 8
)(
    input  logic              clk,
    input  logic              rst,
    input  logic              wr_en,
    input  logic              rd_en,
    input  logic [DBIT-1:0]   wr_data,
    output logic [DBIT-1:0]   rd_data,
    output logic              full,
    output logic              empty
);

    logic [DBIT-1:0] mem [0:DEPTH-1];
    localparam PTR_W = $clog2(DEPTH)  // pointer width
    logic [PTR_W-1:0] wr_ptr, rd_ptr;
    logic [PTR_W:0]   count;   // count can go upto DEPTH

    // write + read operations
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
            rd_data <= '0;
        end else begin
            // Write
            if (wr_en && !full) begin
                mem[wr_ptr] <= wr_data;
                wr_ptr <= (wr_ptr + 1) % DEPTH;
            end

            // Read
            if (rd_en && !empty) begin
                rd_data <= mem[rd_ptr];
                rd_ptr <= (rd_ptr + 1) % DEPTH;
            end

            // Count update
            case ({rd_en && !empty, wr_en && !full})
                2'b01: count <= count + 1; // Write only
                2'b10: count <= count - 1; // Read only
                default: count <= count;   // No change or simultaneous
            endcase
        end
    end

    // Status flags
    assign empty = (count == 0);
    assign full  = (count == DEPTH);

endmodule
