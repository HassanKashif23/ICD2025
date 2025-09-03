interface packet #(
    parameter DATA_WIDTH = 128,
    parameter DATA_BYTES = DATA_WIDTH / 8,
    parameter USER_WIDTH = 3
);
    logic       clk;
    logic       rst;
    logic       [DATA_WIDTH-1:0]TDATA;
    logic       TVALID;
    logic       TREADY;
    logic       TLAST;
    logic       [DATA_BYTES-1:0]TSTRB;
    logic       [USER_WIDTH-1:0] TUSER;

    //==========AXI4 STREAM MASTER==============
    modport master(
        input clk,
        input rst,
        output TDATA,
        output TVALID,
        input TREADY,
        output TLAST,
        output TSTRB,
        output TUSER
    );
    //==========AXI4 STREAM SLAVE===============
    modport slave(
        input clk,
        input rst,
        input TDATA,
        input TVALID,
        output TREADY,
        input TLAST,
        input TSTRB,
        input TUSER
    );



endinterface