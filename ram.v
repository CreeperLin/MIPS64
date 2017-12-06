/* Random Access Memory
    * Features:
        * Clock driven? [x]
*/

parameter WORD_SZ = 8;
parameter ADDR_SZ = 8;
module RAM(ras, cas, datain, we, dataout);
input [ADDR_SZ-1:0]ras;
input [ADDR_SZ-1:0]cas;
input datain;
output dataout;
reg [WORD_SZ-1:0] mem[2**ADDR_SZ];
assign dataout = mem[ras][cas];
always @(posedge we) begin
    mem[ras][cas] = datain;
end
endmodule
