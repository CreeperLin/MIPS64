module pipeWB
(
    input clk, rst,
    input up_syn,
    output reg up_ack,
    output reg down_syn,
    input down_ack,

    input[31:0] din,
    output reg[31:0] dout,
    input[4:0] idxin,
    output reg[4:0] idxout,
    output reg reg_we
);
always @(posedge clk or posedge rst) begin
    if (rst) begin
        reg_we <= 0;
        up_ack <= 0;
        dout <= 0;
        idxout <= 0;
        //#100;
        down_syn <= 1;
    end else begin

    end
end
//assign idxout = idxin;
//assign dout = din;
always @(posedge up_syn) begin
    #1;
    up_ack = 1;
    dout = din;
    idxout = idxin;
    reg_we = 1;
    #1;
    reg_we = 0;
    $display("WB: idx:%d val:%d",idxout,dout);
    down_syn = 1;
end
always @(negedge up_syn) begin
    up_ack <= #1 0;
end
always @(posedge down_ack) begin
    down_syn <= #1 0;
end

//initial begin
    //down_syn <= 1;
//end

endmodule
