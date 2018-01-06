module b_predictor
#(
    parameter TAG_LEN = 10,
    parameter LOCAL_HLEN = 8,
    parameter GLOBAL_HLEN = 12
)
(
    input clk,rst,
    input we,
    output reg wack,
    input[TAG_LEN-1:0] tag_in,
    input t_in,
    input[TAG_LEN-1:0] tag_q,
    output t_out
);
reg[GLOBAL_HLEN-1:0] global_hist;
reg[1:0] global_pht[GLOBAL_HLEN-1:0];
reg[LOCAL_HLEN-1:0] local_hist[TAG_LEN-1:0];
reg[1:0] local_pht[TAG_LEN+LOCAL_HLEN-1:0];
integer i;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        global_hist = 0;
        wack = 0;
        for (i=0;i<GLOBAL_HLEN;i=i+1) begin
            global_pht[i] = 0;
        end
        for (i=0;i<TAG_LEN;i=i+1) begin
            local_hist[i] = 0;
        end
        for (i=0;i<TAG_LEN+LOCAL_HLEN;i=i+1) begin
            local_pht[i] = 0;
        end
    end else begin

    end
end
wire[TAG_LEN+LOCAL_HLEN-1:0] q_local_idx;
wire[TAG_LEN+LOCAL_HLEN-1:0] in_local_idx;
assign q_local_idx = {tag_q,local_hist[tag_q]};
assign in_local_idx = {tag_in,local_hist[tag_in]};

wire[1:0] in_local_phte;
assign in_local_phte = local_pht[in_local_idx];
wire[1:0] in_global_phte;
assign in_global_phte = global_pht[global_hist];

assign t_out = local_pht[q_local_idx][1];
always @(posedge we) begin
    local_hist[tag_in] = {local_hist[tag_in][LOCAL_HLEN-2:0],t_in};
    local_pht[in_local_idx] = in_local_phte + 1;
    global_hist = {global_hist[GLOBAL_HLEN-2:0],t_in};
    global_pht[global_hist] = in_global_phte + 1; 
    wack = 1;
end

always @(negedge we) begin
    wack = 0;
end

endmodule
