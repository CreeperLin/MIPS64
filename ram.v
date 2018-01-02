/* Random Access dataory
    * Features:
        * Clock driven? [x]
*/
module ram 
#(
    parameter MADDR_SZ = 32,
    parameter MEM_SZ = 2**21
)
(
    input clk, rst,
    input[7:0] datain,
    output reg[7:0] dataout,
    //output[7:0] dataout,
    input[MADDR_SZ-1:0] raddr,
    input[MADDR_SZ-1:0] waddr,
    input re,we
);
reg[7:0] data[MEM_SZ-1:0];

//assign dataout = data[raddr];
reg[31:0] outl,inl;
always @(posedge we) begin
    $display("MEM Write: addr:%x, data:%x",waddr,datain);
    data[waddr] = datain;
    case (waddr)
        32'h104: begin
            $fwrite(fp_w,"%c",datain);
            $display("IO:PrintByte: %b %h %c",datain,datain,datain);
        end
        32'h209: begin
            outl = {data[32'h208],data[32'h207],data[32'h206],data[32'h205]};
            $fwrite(fp_w,"%d",outl);
            $display("IO:PrintInt: %0d",outl);
        end
        32'h200: begin
            //inl = {data[32'h204],data[32'h203],data[32'h202],data[32'h201]};
            cnt = $fscanf(fp_r,"%d",inl);
            data[32'h201] = inl[7:0];
            data[32'h202] = inl[15:8];
            data[32'h203] = inl[23:16];
            data[32'h204] = inl[31:24];
            $display("IO:InputInt: %d",inl);
        end
        32'h108: begin
            $display("IO:Return %d after %d tck",datain,$time);
            $finish;
        end
    endcase
end

integer fp_r, fp_w, cnt;
always @(posedge re) begin
    case (raddr)
        32'h100: begin
            data[raddr] = $fgetc(fp_r);
            $display("IO:InputByte: %c", dataout);
        end
    endcase
    dataout = data[raddr];
    $display("MEM Read: addr:%x, data:%x",raddr,dataout);
end

integer i;
initial begin
    for (i=0;i<MEM_SZ;i=i+1) begin
        data[i] = 0;
    end
    $readmemh("./test/test.dat", data);
    fp_r = $fopen("./test/test.in", "r");
    fp_w = $fopen("./test/test.out", "w");
end

always @(posedge clk or posedge rst) begin
    if (rst) begin

    end else begin

    end
end

endmodule
