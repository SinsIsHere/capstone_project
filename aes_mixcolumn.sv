module aes_mixcolumn (
    input  logic [31:0] aes_mixcolumn_in,
    output logic [31:0] aes_mixcolumn_out
);
    logic [31:0] aes_mixcolumn_mult2_out;
    logic [31:0] aes_mixcolumn_mult3_out;

    generate
        for (genvar i = 0; i < 4; i++) begin
            assign aes_mixcolumn_mult2_out[(i+1)*8-1:i*8] = (aes_mixcolumn_in[(i+1)*8-1]) ? ({aes_mixcolumn_in[(i+1)*8-2:i*8], 1'b0} ^ 8'b0001_1011)
                                                                                          :  {aes_mixcolumn_in[(i+1)*8-2:i*8], 1'b0};
        end
        assign aes_mixcolumn_mult3_out = aes_mixcolumn_mult2_out ^ aes_mixcolumn_in;
    endgenerate

    assign aes_mixcolumn_out[31:24] =    aes_mixcolumn_mult2_out[31:24] ^ aes_mixcolumn_mult3_out[23:16]
                                       ^ aes_mixcolumn_in[15:8]         ^ aes_mixcolumn_in[7:0];
    assign aes_mixcolumn_out[23:16] =    aes_mixcolumn_in[31:24]        ^ aes_mixcolumn_mult2_out[23:16]
                                       ^ aes_mixcolumn_mult3_out[15:8]  ^ aes_mixcolumn_in[7:0];
    assign aes_mixcolumn_out[15:8]  =    aes_mixcolumn_in[31:24]        ^ aes_mixcolumn_in[23:16]
                                       ^ aes_mixcolumn_mult2_out[15:8]  ^ aes_mixcolumn_mult3_out[7:0];
    assign aes_mixcolumn_out[7:0]   =    aes_mixcolumn_mult3_out[31:24] ^ aes_mixcolumn_in[23:16]
                                       ^ aes_mixcolumn_in[15:8]         ^ aes_mixcolumn_mult2_out[7:0];
endmodule
