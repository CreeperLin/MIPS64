module test_adder;
	wire [15:0] answer;
	reg  [15:0] a, b;

	adder adder (a, b, answer);
	
	integer i;
	initial begin
		for(i=1; i<=100; i=i+1) begin
			a[14:0] = $random;
			a[15] = 0;
			b[14:0] = $random;
			b[15] = 0;
			
			#1;
			$display("TESTCASE %d: %d + %d = %d", i, a, b, answer);

			if (answer != a + b) begin
				$display("Wrong Answer!");
			end
		end
		$display("Congratulations! You have passed all of the tests.");
		$finish;
	end
endmodule

module adder1(A, B, c, S, p, g);
input A, B, c;
output S, p, g;
assign S = A ^ B ^ c;
assign g = A & B;
assign p = A | B; // xor or
endmodule

module LCU(p, g, c0, C, PG, GG, c1);
input [3:0] p;
input [3:0] g;
output [3:0] C;
input c0;
output PG, GG, c1;
assign C[0] = g[0] | (p[0] & c0);
assign C[1] = g[1] | (p[1] & C[0]);
assign C[2] = g[2] | (p[2] & C[1]);
assign C[3] = g[3] | (p[3] & C[2]);
assign c1 = C[3];
assign PG = p[0] & p[1] & p[2] & p[3];
assign GG = g[3] | (g[2] & p[3]) | (g[1] & p[2] & p[3]) | (g[0] & p[1] & p[2] & p[3]);
endmodule

module adder4(A, B, c0, S, PG, GG, c1);
input[3:0] A;
input[3:0] B;
input c0;
output[3:0] S;
output PG, GG, c1;
wire [3:0] C;
wire [3:0] p;
wire [3:0] g;
LCU lcu(p, g, c0, C, PG, GG, c1);
adder1 a0(A[0], B[0], c0, S[0], p[0], g[0]);
adder1 a1(A[1], B[1], C[0], S[1], p[1], g[1]);
adder1 a2(A[2], B[2], C[1], S[2], p[2], g[2]);
adder1 a3(A[3], B[3], C[2], S[3], p[3], g[3]);
endmodule

module adder16(A, B, c0, S, PG, GG, c1);
input[15:0] A;
input[15:0] B;
input c0;
output[15:0] S;
output PG, GG, c1;
wire [3:0] C;
wire [3:0] p;
wire [3:0] g;
LCU lcu(p, g, c0, C, PG, GG, c1);
adder4 a0(A[3:0], B[3:0], c0, S[3:0], p[0], g[0]);
adder4 a1(A[7:4], B[7:4], C[0], S[7:4], p[1], g[1]);
adder4 a2(A[11:8], B[11:8], C[1], S[11:8], p[2], g[2]);
adder4 a3(A[15:12], B[15:12], C[2], S[15:12], p[3], g[3]);
endmodule

module adder64(A, B, c0, S, PG, GG, c1);
input[63:0] A;
input[63:0] B;
input c0;
output[63:0] ans;
output PG, GG, c1;
wire[3:0] C;
wire[3:0] P;
wire[3:0] g;
LCU lcu(p, g, c0, C, PG, GG, c1);
adder16 a0(A[15:0], B[15:0], c0, S[15:0], p[0], g[0]);
adder16 a1(A[31:16], B[31:16], c0, S[31:16], p[1], g[1]);
adder16 a2(A[47:32], B[47:32], c0, S[47:32], p[2], g[2]);
adder16 a3(A[63:48], B[63:48], c0, S[63:48], p[3], g[3]);
endmodule
