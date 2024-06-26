module gcm (
    input logic clk,
    input logic rst_n,
//    input logic gcm_decrypt_i,

    input logic gcm_key_vld_i,
    input logic [127:0] gcm_key_i,

    input logic gcm_iv_vld_i,
    input logic [95:0] gcm_iv_i,

    input logic gcm_aad_vld_i,
    input logic gcm_pld_vld_i,
//    input logic gcm_tag_vld_i,
    input logic gcm_eof_i,
    input logic [127:0] gcm_pld_i,

    //output logic gcm_ready_o,
    output logic gcm_pld_vld_o,
    output logic gcm_tag_vld_o,
//    output logic gcm_ok_vld_o,
    output logic [127:0] gcm_pld_o,
    output logic [127:0] gcm_tag_o
//    output logic gcm_ok_o
);
//-----------------------------------------------------------------------------
    logic [127:0] inc1_out;
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) inc1_out <= '0;
        else if (gcm_iv_vld_i) inc1_out <= {gcm_iv_i, 32'd1};
        else if (gcm_pld_vld_i) inc1_out <= inc1_out + 1'd1;
        else inc1_out <= inc1_out;
    end
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
//    logic [127:0] tag_in;
//    always_ff @(posedge clk, negedge rst_n) begin
//        if (!rst_n) tag_in <= '0;
//        else if (gcm_tag_vld_i) tag_in <= gcm_pld_i;
//        else tag_in <= tag_in;
//    end
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
    logic [127:0] pipe_in;
    logic [127:0] pipe_out;
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) pipe_in <= '0;
        else if (gcm_aad_vld_i | gcm_pld_vld_i) pipe_in <= gcm_pld_i;
        else pipe_in <= pipe_in;
    end

    logic [12:0][127:0] pipe;
    assign pipe[0] = pipe_in;
    assign pipe_out = pipe[12];
    generate
        for (genvar i = 1; i <= 12; i++) begin
            always_ff @(posedge clk, negedge rst_n) begin
                if (!rst_n) pipe[i] <= '0;
                else pipe[i] <= pipe[i-1];
            end
        end
    endgenerate
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
    logic [127:0] len;
    logic [ 63:0] aad_cnt;
    logic [ 63:0] pld_cnt;
    assign len = {aad_cnt, pld_cnt};

    logic aad_cnt_vld;
    logic pld_cnt_vld;
    logic [14:1] aad_cnt_vld_pipe;
    logic [14:1] pld_cnt_vld_pipe;
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) aad_cnt_vld_pipe[1] <= '0;
        else aad_cnt_vld_pipe[1] <= gcm_aad_vld_i;
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) pld_cnt_vld_pipe[1] <= '0;
        else pld_cnt_vld_pipe[1] <= gcm_pld_vld_i;
    end
    generate
        for (genvar i = 2; i <= 14; i++) begin
            always_ff @(posedge clk, negedge rst_n) begin
                if (!rst_n) aad_cnt_vld_pipe[i] <= '0;
                else aad_cnt_vld_pipe[i] <= aad_cnt_vld_pipe[i-1];
            end
            always_ff @(posedge clk, negedge rst_n) begin
                if (!rst_n) pld_cnt_vld_pipe[i] <= '0;
                else pld_cnt_vld_pipe[i] <= pld_cnt_vld_pipe[i-1];
            end
        end
    endgenerate
    assign aad_cnt_vld = aad_cnt_vld_pipe[14];
    assign pld_cnt_vld = pld_cnt_vld_pipe[14];

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) aad_cnt <= '0;
        else if (gcm_iv_vld_i) aad_cnt <= '0;
        else if (aad_cnt_vld) aad_cnt <= aad_cnt + 64'd128;
        else aad_cnt <= aad_cnt;
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) pld_cnt <= '0;
        else if (gcm_iv_vld_i) pld_cnt <= '0;
        else if (pld_cnt_vld) pld_cnt <= pld_cnt + 64'd128;
        else pld_cnt <= pld_cnt;
    end
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
    logic [127:0] aes_data_i;
    logic aes_data_vld_o;
    logic [127:0] aes_data_o;
    logic [10:0][127:0] aes_key_conn;
    assign aes_data_i = (gcm_iv_vld_i) ? 128'd0 : inc1_out;

    logic aes_en_calc_h;
    logic aes_en_calc_j0;
    logic aes_en;
    assign aes_en_calc_h = gcm_iv_vld_i;
    assign aes_en = aes_en_calc_h | aes_en_calc_j0 | gcm_pld_vld_i;
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) aes_en_calc_j0 <= 0;
        else aes_en_calc_j0 <= aes_en_calc_h;
    end

    aes_128  aes_128_inst(
        .clk(clk),
        .rst_n(rst_n),
        .aes_data_vld_i(1'b1),
        .aes_data_i(aes_data_i),
        .aes_key_i(aes_key_conn),
        .aes_data_vld_o(aes_data_vld_o),
        .aes_data_o(aes_data_o)
    );

    aes_128_key aes_128_key_inst (
        .clk(clk),
        .rst_n(rst_n),
        .aes_key_vld_i(gcm_key_vld_i),
        .aes_key_i(gcm_key_i),
        .aes_key_o(aes_key_conn)
    );
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
    logic [127:0] pipe_out_mux;
    logic pipe_out_mux_sel_aad;
    logic pipe_out_mux_sel_pld;
    logic pipe_out_mux_sel_len;
    logic [2:0] pipe_out_mux_sel;
    assign pipe_out_mux_sel_aad = aad_cnt_vld_pipe[13];
    assign pipe_out_mux_sel_pld = pld_cnt_vld_pipe[13];
    assign pipe_out_mux_sel = {pipe_out_mux_sel_aad, pipe_out_mux_sel_pld, pipe_out_mux_sel_len};

    logic [14:1] pipe_out_mux_sel_len_pipe;
    assign pipe_out_mux_sel_len = pipe_out_mux_sel_len_pipe[14];
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) pipe_out_mux_sel_len_pipe[1] <= '0;
        else pipe_out_mux_sel_len_pipe[1] <= gcm_eof_i;
    end
    generate
        for (genvar i = 2; i <= 14; i++) begin
            always_ff @(posedge clk, negedge rst_n) begin
                if (!rst_n) pipe_out_mux_sel_len_pipe[i] <= '0;
                else pipe_out_mux_sel_len_pipe[i] <= pipe_out_mux_sel_len_pipe[i-1];
            end
        end
    endgenerate

    always_comb begin
        case (pipe_out_mux_sel)
            3'b100: pipe_out_mux = pipe_out;
            3'b010: pipe_out_mux = pipe_out ^ aes_data_o;
            3'b001: pipe_out_mux = len;
            default: pipe_out_mux = '0;
        endcase
    end
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
    logic [12:1] h_en_pipe;
    logic        h_en;
    logic [127:0] h_reg;
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) h_en_pipe[1] <= '0;
        else h_en_pipe[1] <= gcm_iv_vld_i;
    end
    generate
        for (genvar i = 2; i <= 12; i++) begin
            always_ff @(posedge clk, negedge rst_n) begin
                if (!rst_n) h_en_pipe[i] <= 0;
                else h_en_pipe[i] <= h_en_pipe[i-1];
            end
        end
    endgenerate

    assign h_en = h_en_pipe[12];

    always_ff @(posedge clk, negedge rst_n) begin
        if      (!rst_n) h_reg <= '0;
        else if (h_en)   h_reg <= aes_data_o;
        else             h_reg <= h_reg;
    end
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
    logic        j0_en;
    logic [127:0] j0_reg;
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) j0_en <= '0;
        else j0_en <= h_en;
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if      (!rst_n) j0_reg <= '0;
        else if (j0_en)  j0_reg <= aes_data_o;
        else             j0_reg <= j0_reg;
    end
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
    logic [127:0] mult_z;
    logic [127:0] mult_out;
    logic [13:1] mult_en_pipe;
    logic mult_en;
    assign mult_en = mult_en_pipe[13];
    gcm_mult gcm_mult_inst(
        .clk(clk),
        .rst_n(rst_n),
        .x(mult_out ^ pipe_out_mux),
        .y(h_reg),
        .z(mult_z)
    );
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) mult_en_pipe[1] <= '0;
        else mult_en_pipe[1] <= gcm_aad_vld_i | gcm_pld_vld_i;
    end
    generate
        for (genvar i = 2; i <= 13; i++) begin
            always_ff @(posedge clk, negedge rst_n) begin
                if (!rst_n) mult_en_pipe[i] <= '0;
                else mult_en_pipe[i] <= mult_en_pipe[i-1];
            end
        end
    endgenerate
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) mult_out <= '0;
        else if (mult_en) mult_out <= mult_z;
        else mult_out <= mult_out;
    end
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
    logic [127:0] pld_out_mux;
    logic [1:0] pld_out_mux_sel;
    assign pld_out_mux_sel = pipe_out_mux_sel[2:1];
    always_comb begin
        case (pld_out_mux_sel)
            2'b10: pld_out_mux = pipe_out;
            2'b01: pld_out_mux = pipe_out ^ aes_data_o;
            default: pld_out_mux = '0;
        endcase
    end
    logic pld_out_en;
    assign pld_out_en = mult_en;
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) gcm_pld_o <= '0;
        else if (pld_out_en) gcm_pld_o <= pld_out_mux;
        else gcm_pld_o <= gcm_pld_o;
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) gcm_pld_vld_o <= '0;
        else gcm_pld_vld_o <= pld_out_en;
    end
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
    logic tag_out_en;
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) tag_out_en <= '0;
        else tag_out_en <= pipe_out_mux_sel_len;
    end
    assign gcm_tag_o = (tag_out_en) ? (mult_out ^ j0_reg) : '0;
    assign gcm_tag_vld_o = tag_out_en;
//-----------------------------------------------------------------------------
endmodule
