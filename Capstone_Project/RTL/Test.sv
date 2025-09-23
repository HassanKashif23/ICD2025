`timescale 1ns/1ps

module tb_axi4;

  logic clk, rst;

// AXI4-Stream interfaces
packet input_axi();           // AXI stream input slave
packet output_axi();         // AXI stream output master

  // DUT
  axi4 dut (
    .clk(clk),
    .rst(rst),
    .input_axi(input_axi),
    .output_axi(output_axi)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;   // 100MHz
  end

  // Reset
  initial begin
    rst = 1;
    #20 rst = 0;
  end

 // Ethernet + IPv4 header (272 bits total)
  localparam bit [271:0] ETH_IPV4_HDR = {
    8'hC2,8'h00,8'h68,8'hB3,8'h00,8'h01,
    8'hC2,8'h01,8'h68,8'hB3,8'h00,8'h01,
    8'h86,8'hDD,                             // Ethernet
    8'h45,8'hC0,8'h00,8'h30,8'h00,8'h00,
    8'h00,8'h00,8'h01,8'h11,8'h18,8'h35,
    8'hC0,8'hA8,8'h00,8'h1E,8'hE0,8'h00,
    8'h00,8'h02                              // IPv4
  };

  // Payload (dummy fill: DEAD_BEEF…)
  localparam bit [1536-272-1:0] PAYLOAD = {
    128'hDEAD_BEEF_DEAD_BEEF_DEAD_BEEF_DEAD_BEEF,
    1136'b0
  };

  // Complete packet = 272-bit header + rest payload
  localparam bit [1535:0] FULL_PACKET = {ETH_IPV4_HDR, PAYLOAD};

  // Drive Input Stimulus
  initial begin
    // Wait for reset release
    @(negedge rst);

    // Default
    input_axi.TVALID = 0;
    input_axi.TDATA  = 0;
    input_axi.TLAST  = 0;

    // Wait a few cycles
    repeat(5) @(posedge clk);

  // ---- Send 1536 bits = 3 beats ----
    send_packet(FULL_PACKET, 3);

    // Wait for outputs to flush
    repeat(30) @(posedge clk);

    $finish;
  end

  // Task to send one packet of N beats
  task send_packet(input bit [1535:0] pack,input int num_beats);
    int i;
    begin
      for (i = 0; i < num_beats; i++) begin
        @(posedge clk);
        input_axi.TVALID <= 1'b1;
        input_axi.TDATA  <= pack[1535 - i*512 -: 512];  // slice 512 bits
        input_axi.TLAST  <= (i == num_beats-1);  // last beat at end
        wait(input_axi.TREADY);
      end
      // de-assert after last
      @(posedge clk);
      input_axi.TVALID <= 0;
      input_axi.TLAST  <= 0;
    end
  endtask

  // Monitor Outputs
  always @(posedge clk) begin
    if (output_axi.TVALID && output_axi.TREADY) begin
      $display("[%0t] OUTPUT BEAT: TVALID = 1 TDATA=%h TLAST=%b",
               $time, output_axi.TDATA, output_axi.TLAST);
    end
  end

  // Always ready to accept outputs
  assign output_axi.TREADY = 1'b1;

endmodule
