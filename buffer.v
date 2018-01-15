/*buffer*/
`ifndef BUFFER_H_
`define BUFFER_H_
module buffer
#(
    parameter BUF_ID = 0,
    parameter ADDR_L = 5,
    parameter DATA_L = 16
)
(
    input clk, rst,
    input re, we,
    input[DATA_L-1:0] din,
    output reg[DATA_L-1:0] dout,
    output reg r_ack, w_ack,
    output avail, full
);
localparam BUF_DEPTH = 1 << ADDR_L;
reg[DATA_L-1:0] data[BUF_DEPTH-1:0];
reg unsigned[ADDR_L-1:0] rpt;
reg unsigned[ADDR_L-1:0] wpt;
//wire unsigned[ADDR_L-1:0] winc;
//reg[ADDR_L:0] sz;
//assign winc = wpt + 1'b1;
assign full = (wpt+1 == rpt);
assign avail = (rpt != wpt);
always @(posedge clk or posedge rst) begin
    if (rst) begin
        dout <= 0;
        rpt <= 0;
        wpt <= 0;
        r_ack <= 0;
        w_ack <= 0;
    end else begin

    end
end

always @(posedge we) begin
    if (full) begin
        $display("BUF:ID:%d ERROR FULL w:%d r:%d",BUF_ID,wpt,rpt);
    end else begin
        data[wpt] <= din;
        wpt <= wpt + 1;
        //$display("BUF:ID:%d Write data:%d wpt:%d",BUF_ID,din,wpt);
        $display("BUF:ID:%d Write w:%d r:%d",BUF_ID,wpt,rpt);
    end
    w_ack <= 1;
end
always @(posedge re) begin
    if (avail) begin
        dout <= data[rpt];
        rpt <= rpt + 1;
        //$display("BUF:ID:%d Read data:%d rpt:%d",BUF_ID,dout,rpt);
        $display("BUF:ID:%d Read w:%d r:%d",BUF_ID,wpt,rpt);
    end else begin
        dout <= 0;
        $display("BUF:ID:%d ERROR EMPTY w:%d r:%d",BUF_ID,wpt,rpt);
    end
    r_ack <= 1;
end

always @(negedge we) begin
    w_ack <= 0;
end

always @(negedge re) begin
    r_ack <= 0;
end
endmodule
`endif
