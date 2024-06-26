module gcm_tb;
    logic clk;
    logic rst_n;

    logic gcm_key_vld_i;
    logic [127:0] gcm_key_i;

    logic gcm_iv_vld_i;
    logic [95:0] gcm_iv_i;

    logic gcm_aad_vld_i;
    logic gcm_pld_vld_i;
    
    logic gcm_eof_i;
    logic [127:0] gcm_pld_i;

    logic gcm_pld_vld_o;
    logic gcm_tag_vld_o;
    logic [127:0] gcm_pld_o;
    logic [127:0] gcm_tag_o;

    gcm DUT (
        .clk (clk),
        .rst_n (rst_n),

        .gcm_key_vld_i (gcm_key_vld_i),
        .gcm_key_i (gcm_key_i),

        .gcm_iv_vld_i (gcm_iv_vld_i),
        .gcm_iv_i (gcm_iv_i),

        .gcm_aad_vld_i (gcm_aad_vld_i),
        .gcm_pld_vld_i (gcm_pld_vld_i),
        
        .gcm_eof_i (gcm_eof_i),
        .gcm_pld_i (gcm_pld_i),

        .gcm_pld_vld_o (gcm_pld_vld_o),
        .gcm_tag_vld_o (gcm_tag_vld_o),
        .gcm_pld_o (gcm_pld_o),
        .gcm_tag_o (gcm_tag_o)
    );

    always #10 clk = ~clk;

    initial begin
        clk <= 1; rst_n <= 0; gcm_key_vld_i <= 0; gcm_key_i <= '0; gcm_iv_vld_i <= 0; gcm_iv_i <= '0; gcm_aad_vld_i <= 0; gcm_pld_vld_i <= 0; gcm_eof_i <= 0; gcm_pld_i <= '0;

        #20     rst_n <= 1;
                gcm_key_vld_i <= 1;
                gcm_key_i <= 128'hfeff_e992_8665_731c_6d6a_8f94_6730_8308;
                gcm_iv_vld_i <= 1;
                gcm_iv_i <= 128'hcafe_babe_face_dbad_deca_f888;
                gcm_aad_vld_i <= 1;
                gcm_pld_i <= 128'hfeed_face_dead_beef_feed_face_dead_beef;

        #20     gcm_key_vld_i <= 0;
                gcm_key_i <= '0;
                gcm_iv_vld_i <= 0;
                gcm_iv_i <= '0;
                gcm_pld_i <= 128'habad_dad2_0000_0000_0000_0000_0000_0000;


        #20     gcm_aad_vld_i <= 0;
                gcm_pld_vld_i <= 1;
                gcm_pld_i <= 128'hd931_3225_f884_06e5_a559_09c5_aff5_269a;

        #20     gcm_pld_i <= 128'h86a7_a953_1534_f7da_2e4c_303d_8a31_8a72;

        #20     gcm_pld_i <= 128'h1c3c_0c95_9568_0953_2fcf_0e24_49a6_b525;

        #20     gcm_pld_i <= 128'hb16a_edf5_aa0d_e657_ba63_7b39_0000_0000;
                gcm_eof_i <= 1;

        #20     gcm_pld_vld_i <= 0; gcm_eof_i <= 0;


    end

endmodule