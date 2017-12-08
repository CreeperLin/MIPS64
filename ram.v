/* Random Access Memory
    * Features:
        * Clock driven? [x]
*/

module RAM(addr, datain, we, dataout);
//parameter ROW_SZ = 16;
//parameter COL_SZ = 16;
parameter MADDR_SZ = 32;
input[MADDR_SZ-1:0] addr;
input we;
input[7:0] datain;
output[7:0] dataout;
//reg[2**COL_SZ-1:0] mem[2**ROW_SZ-1:0];
reg[7:0] mem[2**MADDR_SZ-1:0];
//wire[ROW_SZ-1:0] ras;
//wire[COL_SZ-1:0] cas;
//assign ras = addr[MADDR_SZ-1:COL_SZ];
//assign cas = addr[COL_SZ-1:0];
//assign dataout = mem[ras][cas];
assign dataout = mem[addr];
always @(posedge we) begin
    mem[addr] = datain;
end

initial begin
    $readmemb("test.rom",mem,0,2**20);
end
endmodule
