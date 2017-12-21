module cache
#(
    parameter CACHE_ROW = 64,
    parameter CACHE_LEN = 8, //bytes
    parameter ADDR_L = 32 //bit
)
(
    input[8*CACHE_LEN-1:0] datain,
    input[ADDR_L-1:0] read_addr,
    input[ADDR_L-1:0] write_addr,
    output reg[8*CACHE_LEN-1:0] dataout
);
//2-way set associative
localparam OFS_L = 6;
localparam TAG_L = 21;
localparam IDX_L = 5;
localparam FLG_L = 1;
reg[FLG_L+TAG_L-1:0] map1[CACHE_ROW/2-1:0];
reg[8*CACHE_LEN-1:0] data1[CACHE_ROW/2-1:0];
reg[FLG_L+TAG_L-1:0] map2[CACHE_ROW/2-1:0];
reg[8*CACHE_LEN-1:0] data2[CACHE_ROW/2-1:0];
wire[TAG_L-1:0] tag;
wire[IDX_L-1:0] idx;
wire[OFS_L-1:0] ofs;
assign r_tag = read_addr[ADDR_L-1:ADDR_L-TAG_L];
assign r_idx = read_addr[ADDR_L-TAG_L-1:OFS_L];
assign r_ofs = read_addr[OFS_L-1:0];
assign w_tag = write_addr[ADDR_L-1:ADDR_L-TAG_L];
assign w_idx = write_addr[ADDR_L-TAG_L-1:OFS_L];
assign w_ofs = write_addr[OFS_L-1:0];
reg[FLG_L+TAG_L-1:0] key1;
reg[FLG_L+TAG_L-1:0] key2;
reg[CACHE_LEN-1:0] val1;
reg[CACHE_LEN-1:0] val2;
always @(read_addr) begin
    key1 <= map1[r_idx];
    key2 <= map2[r_idx];
    val1 <= data1[r_idx];
    val2 <= data2[r_idx];

    dataout = val1;
end

always @(write_addr) begin
    data1[w_idx] <= datain;
    data2[w_idx] <= datain;
end
endmodule

