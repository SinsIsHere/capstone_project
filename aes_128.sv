module aes_128 (
    input  logic                clk,
    input  logic                rst_n,
    input  logic                aes_data_vld_i,
    input  logic        [127:0] aes_data_i,
    input  logic [10:0] [127:0] aes_key_i,
    output logic                aes_data_vld_o,
    output logic        [127:0] aes_data_o
);
    logic        [127:0] aes_data_in_reg;
    logic [10:0] [127:0] aes_round_out;
    logic [10:1] [127:0] aes_sbox_out;
    logic [10:1] [127:0] aes_shiftrow_out;
    logic [10:1] [127:0] aes_mixcolumn_out;

    logic                aes_data_vld_in;
    logic [10:0]         aes_round_vld;

    always_ff @(posedge clk, negedge rst_n) begin
        if      (!rst_n)         aes_data_in_reg <= '0;
        else if (aes_data_vld_i) aes_data_in_reg <= aes_data_i;
        else                     aes_data_in_reg <= aes_data_in_reg;
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) aes_round_out[0] <= '0;
        else        aes_round_out[0] <= aes_data_in_reg ^ aes_key_i[0];
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) aes_data_vld_in <= '0;
        else        aes_data_vld_in <= aes_data_vld_i;
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) aes_round_vld[0] <= '0;
        else        aes_round_vld[0] <= aes_data_vld_in;
    end

    generate
        for (genvar i = 1; i <= 10; i++) begin
            for (genvar j = 0; j < 16; j++) begin
                aes_sbox gen_aes_sbox (
                    .aes_sbox_in (aes_round_out[i-1][(j+1)*8-1:j*8]),
                    .aes_sbox_out(aes_sbox_out[i][(j+1)*8-1:j*8])
                );
            end

            assign aes_shiftrow_out[i][127:96] = {aes_sbox_out[i][127:120], aes_sbox_out[i][ 87:80 ], aes_sbox_out[i][ 47:40 ], aes_sbox_out[i][  7:0 ]};
            assign aes_shiftrow_out[i][ 95:64] = {aes_sbox_out[i][ 95:88 ], aes_sbox_out[i][ 55:48 ], aes_sbox_out[i][ 15:8  ], aes_sbox_out[i][103:96]};
            assign aes_shiftrow_out[i][ 63:32] = {aes_sbox_out[i][ 63:56 ], aes_sbox_out[i][ 23:16 ], aes_sbox_out[i][111:104], aes_sbox_out[i][ 71:64]};
            assign aes_shiftrow_out[i][ 31:0 ] = {aes_sbox_out[i][ 31:24 ], aes_sbox_out[i][119:112], aes_sbox_out[i][ 79:72 ], aes_sbox_out[i][ 39:32]};

            if (i < 10) begin
                aes_mixcolumn gen_aes_mixcolumn_127_96 (
                    .aes_mixcolumn_in (aes_shiftrow_out[i][127:96]),
                    .aes_mixcolumn_out(aes_mixcolumn_out[i][127:96])
                );
                aes_mixcolumn gen_aes_mixcolumn_95_64 (
                    .aes_mixcolumn_in (aes_shiftrow_out[i][95:64]),
                    .aes_mixcolumn_out(aes_mixcolumn_out[i][95:64])
                );
                aes_mixcolumn gen_aes_mixcolumn_63_32 (
                    .aes_mixcolumn_in (aes_shiftrow_out[i][63:32]),
                    .aes_mixcolumn_out(aes_mixcolumn_out[i][63:32])
                );
                aes_mixcolumn gen_aes_mixcolumn_31_00 (
                    .aes_mixcolumn_in (aes_shiftrow_out[i][31:0]),
                    .aes_mixcolumn_out(aes_mixcolumn_out[i][31:0])
                );
            end else begin
                assign aes_mixcolumn_out[i] = aes_shiftrow_out[i];
            end

            always_ff @(posedge clk, negedge rst_n) begin
                if (!rst_n) aes_round_out[i] <= '0;
                else        aes_round_out[i] <= aes_mixcolumn_out[i] ^ aes_key_i[i];
            end

            always_ff @(posedge clk, negedge rst_n) begin
                if (!rst_n) aes_round_vld[i] <= '0;
                else        aes_round_vld[i] <= aes_round_vld[i-1];
            end
        end
    endgenerate

    assign aes_data_o = aes_round_out[10];
    assign aes_data_vld_o = aes_round_vld[10];
endmodule
