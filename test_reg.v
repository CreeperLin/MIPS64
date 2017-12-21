module test;
reg[4:0] r_idx;
reg[4:0] w_idx;
reg[31:0] din;
wire[31:0] dout;
reg we;
regfile gpr(r_idx,w_idx,we,din,dout);
integer i;
initial begin
    din = 0;
    we = 0;
    r_idx = 0;
    $display("%d\n",dout);
    w_idx = 1;
    din = 25;
    we = 1;
    #1;
    r_idx = 1;
    $display("%d\n",dout);
    for (i=0;i<32;i=i+1) begin
        w_idx = i;
        we = 0;
        din[4:0] = $random;
        we = 1;
        #1;
        r_idx = w_idx;
        $display("%d %d %d",w_idx,din, dout);
    end
    we = 0;
    w_idx = 1;
    din = 100;
    #1;
    r_idx = 1;
    $display("%d",dout);
end
endmodule
