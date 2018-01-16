module regfile
#(
    parameter REG_SZ = 32,
    parameter REG_NUM = 32
)
(
    input clk,rst,
    input[4:0] r_idx,
    input[4:0] w_idx,
    input re,we,
    output reg rack, wack,
    input[REG_SZ-1:0] din,
    output reg[REG_SZ-1:0] dout
);
wire[REG_SZ-1:0] gpr[REG_NUM-1:0];
reg[REG_SZ-1:0] data[REG_NUM-1:0];
supply0 zero;
assign gpr[0] = zero;
genvar i;
generate
    for (i=1;i<32;i=i+1) begin
        assign gpr[i] = data[i];
    end
endgenerate
//assign dout = gpr[r_idx];
//assign dout = (r_idx==0) ? 0 : data[r_idx];
integer t;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        rack <= 0;
        wack <= 0;
        for (t=0;t<32;t=t+1) begin
            data[t] <= 0;
        end
        dout <= 0;
    end else begin
    end
end

always @(posedge re) begin
    dout <= gpr[r_idx];
    rack <= 1;
    $display("REG:Read idx:%d val:%d",r_idx,dout);
end
always @(posedge we) begin
    data[w_idx] <= din;
    wack <= 1;
    $display("REG:Write idx:%d val:%d",w_idx,din);
end
always @(negedge re) begin
    rack <= 0;
end
always @(negedge we) begin
    wack <= 0;
end
endmodule
