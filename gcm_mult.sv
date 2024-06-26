module gcm_mult(
    input logic          clk,
    input logic         rst_n,
	input logic [127:0] x,
	input logic [127:0] y,
	output logic [127:0] z
);
	logic [0:128][127:0] m;
	logic [0:128][127:0] p;

	assign m[0] = x;
	assign p[0] = '0;

	generate
		for (genvar i = 1; i < 129; i++) begin
			assign p[i] = (y[i-1]) ? (p[i-1] ^ m[i-1]) : p[i-1];
			assign m[i] = (m[i-1][127]) ? ({m[i-1][126:0], 1'b0} ^ {120'd0, 8'b1000_0111}) : {m[i-1][126:0], 1'b0};
		end
	endgenerate

//	always_ff @(posedge clk, negedge rst_n) begin
//		if (!rst_n) z <= '0;
//		else 		z <= p[128];
//	end
	assign z = p[128];
endmodule
