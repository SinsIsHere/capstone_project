module aes_128_key_tb;
    logic                clk;
    logic                rst_n;
    logic                aes_key_vld_i;
    logic        [127:0] aes_key_i;
    logic [10:0] [127:0] aes_key_o;

    aes_128_key DUT (
        .clk(clk),
        .rst_n(rst_n),
        .aes_key_vld_i(aes_key_vld_i),
        .aes_key_i(aes_key_i),
        .aes_key_o(aes_key_o)
    );

    always #10 clk = ~clk;

    initial begin
        #0000   clk <= 1;
                rst_n <= 0;
                aes_key_vld_i <= 0;
                aes_key_i <= '0;

        #0020   rst_n <= 1;
                aes_key_vld_i <= 1;
                aes_key_i <= 128'h8F6F_4625_18AB_4E98_B9D4_1148_2027_6C41;

        #0020   aes_key_vld_i <= 0;
    end
endmodule
