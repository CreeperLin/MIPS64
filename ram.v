/* Random Access dataory
    * Features:
        * Clock driven? [x]
*/
module ram 
#(
    parameter MADDR_SZ = 32,
    parameter MEM_SZ = 2**25
)
(
    input clk, rst,
    input[7:0] datain,
    output[7:0] dataout,
    input[MADDR_SZ-1:0] raddr,
    input[MADDR_SZ-1:0] waddr,
    input re,we
);
reg[7:0] data[MEM_SZ-1:0];
assign dataout = data[raddr];
always @(posedge we) begin
    $display("MEM Write: addr:%x, data:%x",waddr,datain);
    data[waddr] = datain;
end
//always @(posedge re) begin
    //dataout = data[raddr];
    //$display("MEM Read: addr:%x, data:%x",raddr,dataout);
//end
initial begin
    $readmemh("./test/test.dat", data);
end
always @(posedge clk or posedge rst) begin
    if (rst) begin

    end else begin

    end
end

endmodule
