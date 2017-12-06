/* Random Access Memory
    * Features:
        * Clock driven? [x]
*/

module RAM(addr, datain, we, dataout);
parameter ROW_SZ = 16;
parameter COL_SZ = 16;
parameter MADDR_SZ = 32;
input[MADDR_SZ-1:0] addr;
input we;
input datain;
output dataout;
reg[2**COL_SZ-1:0] mem[2**ROW_SZ-1:0];
wire[ROW_SZ-1:0] ras;
wire[COL_SZ-1:0] cas;
assign ras = addr[MADDR_SZ-1:COL_SZ];
assign cas = addr[COL_SZ-1:0];
assign dataout = mem[ras][cas];
always @(posedge we) begin
    mem[ras][cas] = datain;
end
endmodule
