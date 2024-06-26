module aes_128_tb;
    logic                clk;
    logic                rst_n;
    logic                aes_data_vld_i;
    logic        [127:0] aes_data_i;
    logic [10:0] [127:0] aes_key_connect;

    logic                aes_key_vld_i;
    logic        [127:0] aes_key_i;

    logic                aes_data_vld_o;
    logic        [127:0] aes_data_o;

    aes_128 MAIN_DUT (
        .clk(clk),
        .rst_n(rst_n),
        .aes_data_vld_i(aes_data_vld_i),
        .aes_data_i(aes_data_i),
        .aes_key_i(aes_key_connect),
        .aes_data_vld_o(aes_data_vld_o),
        .aes_data_o(aes_data_o)
    );

    aes_128_key KEY_DUT (
        .clk(clk),
        .rst_n(rst_n),
        .aes_key_vld_i(aes_key_vld_i),
        .aes_key_i(aes_key_i),
        .aes_key_o(aes_key_connect)
    );

    always #10 clk = ~clk;

    initial begin
        #0000   clk <= 1;
                rst_n <= 0;
                aes_data_vld_i <= 0;
                aes_data_i <= '0;
                aes_key_vld_i <= 0;
                aes_key_i <= '0;

        #0020   rst_n <= 1;
                aes_data_vld_i <= 1;
                aes_data_i <= 128'h7308_C7C5_FB82_4724_D2A5_AA72_1AA7_4921; //expected 28db_938d_50f7_abe5_b71d_cbcf_61ee_dbe5
                aes_key_vld_i <= 1;
                aes_key_i <= 128'h8F6F_4625_18AB_4E98_B9D4_1148_2027_6C41;

        #0020   aes_data_i <= 128'h2E62_74F3_0ED0_9979_5B5D_4530_F015_EB36; //expected 76a2_5526_cea2_118d_6bfe_104a_f6b6_fe44
                aes_key_vld_i <= 0;

        #0020   aes_data_vld_i <= 0;                
                aes_data_i <= 128'hD08A_9543_0346_4DBB_8A78_ECD1_66BF_9B92;

        #0020   aes_data_vld_i <= 1;
                aes_data_i <= 128'hE4A4_E52D_6046_BC5A_0355_7EA3_F389_B6B7; //expected 5649_57d8_5015_8ab7_9f1d_9918_379b_77ff
        
        #0020   aes_data_vld_i <= 0;
                aes_key_vld_i <= 0;

    end
endmodule
