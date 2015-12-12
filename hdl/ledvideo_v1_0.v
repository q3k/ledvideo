
`timescale 1 ns / 1 ps

module ledvideo_v1_0 #
(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line


    // Parameters of Axi Slave Bus Interface S00_AXIS
    parameter integer C_S00_AXIS_TDATA_WIDTH    = 32
)
(
    // Users to add ports here
    input wire core_clk,
    input wire core_rst,
    
    output wire LED_CK,
    output wire LED_STB,
    output wire LED_OE,
    output wire [3:0] LED_BANK,
    output wire LED_R00,
    output wire LED_R01,
    output wire LED_G00,
    output wire LED_G01,
    output wire LED_B00,
    output wire LED_B01,
    output wire LED_R10,
    output wire LED_R11,
    output wire LED_G10,
    output wire LED_G11,
    output wire LED_B10,
    output wire LED_B11,
    output wire LED_R20,
    output wire LED_R21,
    output wire LED_G20,
    output wire LED_G21,
    output wire LED_B20,
    output wire LED_B21,
    output wire LED_R30,
    output wire LED_R31,
    output wire LED_G30,
    output wire LED_G31,
    output wire LED_B30,
    output wire LED_B31,
    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface S00_AXIS
    input wire  s00_axis_aclk,
    input wire  s00_axis_aresetn,
    output wire  s00_axis_tready,
    input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
    input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
    input wire  s00_axis_tlast,
    input wire  s00_axis_tvalid
);

// Instantiation of Axi Bus Interface S00_AXIS
ledvideo_v1_0_S00_AXIS # ( 
    .C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH)
) ledvideo_v1_0_S00_AXIS_inst (
    .S_AXIS_ACLK(s00_axis_aclk),
    .S_AXIS_ARESETN(s00_axis_aresetn),
    .S_AXIS_TREADY(s00_axis_tready),
    .S_AXIS_TDATA(s00_axis_tdata),
    .S_AXIS_TSTRB(s00_axis_tstrb),
    .S_AXIS_TLAST(s00_axis_tlast),
    .S_AXIS_TVALID(s00_axis_tvalid)
); 


// Fake data provider for framebuffer
reg write_frame_sel;
reg [13:0] writer_pixel;
wire [6:0] writer_y = writer_pixel >> 7;
wire [6:0] writer_x = writer_pixel[6:0];

//wire [7:0] writer_b = writer_x ^ writer_y;
wire [7:0] writer_b = writer_x << 1;
wire [7:0] writer_r = writer_y << 1;
wire [7:0] writer_g = 0;
    
// Current writing address decoder
wire [2:0] write_block = writer_y >> 4;
wire [3:0] write_line = writer_y & 4'b1111;
wire [10:0] write_address = (write_line << 7 ) | writer_x;

// Data draw from framebuffer
wire [6:0] draw_x;
wire [3:0] draw_y;
wire [3:0] draw_bit;
wire draw_vsync;
    
wire [15:0] current_reader_address = ((draw_y) << 7) + draw_x;
wire [23:0] dina = (writer_r << 16) | (writer_g << 8) | writer_b;

// Block RAM access lines
wire [7:0] frame_a_wen;
wire [7:0] frame_b_wen;
wire [23:0] reader_data [7:0];
wire [23:0] reader_data_a [7:0];
wire [23:0] reader_data_b [7:0];
wire frame_a_en = (write_frame_sel == 1);
wire frame_b_en = (write_frame_sel == 0);

genvar i;
generate for (i = 0; i < 8; i++) begin
    assign frame_a_wen[i] = (write_frame_sel == 0) && write_block == i;
    assign frame_b_wen[i] = (write_frame_sel == 1) && write_block == i;
    assign reader_data[i] = frame_a_en ? reader_data_a[i] : reader_data_b[i];
    bram #(
        .RAM_DEPTH(2048))
    ) ram_a (
        .clka(core_clk),
        .addra(write_address),
        .wea(frame_a_wen[i]),
        .dina(dina),
        .addrb(current_reader_address),
        .enb(frame_a_en),
        .doutb(reader_data_a[i])
    );
    bram #(
        .RAM_DEPTH(2048))
    ) ram_b (
        .clka(core_clk),
        .addra(write_address),
        .wea(frame_b_wen[i]),
        .dina(dina),
        .addrb(current_reader_address),
        .enb(frame_b_en),
        .doutb(reader_data_b[i])
    );
end

   
reg [1:0] vsync_twostep;
always @(posedge core_clk) begin
   vsync_twostep <= {vsync_twostep[0], draw_vsync};
end

wire core_nrst = !core_rst;
always @(posedge core_clk or negedge core_nrst) begin
   if (!core_nrst) begin
       writer_pixel <= 0;
       write_frame_sel <= 0;
   end else begin
       writer_pixel <= writer_pixel + 1;
       if (vsync_twostep == 2'b10) begin
           write_frame_sel <= write_frame_sel ^ 1;
       end
   end
end

wire sys_en = 1;
blitter bt (
    .sys_en(sys_en),
    .sys_clk(core_clk),
    .sys_rst(!core_rst),
    
    .led_clk(LED_CK),
    .led_stb(LED_STB),
    .led_oe(LED_OE),
    .led_bank(LED_BANK),
    
    .ctl_cur_x(draw_x),
    .ctl_cur_y(draw_y),
    .ctl_cur_bit(draw_bit),
    .ctl_vsync(draw_vsync)
);

wire [7:0] reader_data_r00 = current_reader_data_0[23:16];
wire [7:0] reader_data_g00 = current_reader_data_0[15:8];
wire [7:0] reader_data_b00 = current_reader_data_0[7:0];
wire [7:0] reader_data_r01 = current_reader_data_1[23:16];
wire [7:0] reader_data_g01 = current_reader_data_1[15:8];
wire [7:0] reader_data_b01 = current_reader_data_1[7:0];
wire [7:0] reader_data_r10 = current_reader_data_2[23:16];
wire [7:0] reader_data_g10 = current_reader_data_2[15:8];
wire [7:0] reader_data_b10 = current_reader_data_2[7:0];
wire [7:0] reader_data_r11 = current_reader_data_3[23:16];
wire [7:0] reader_data_g11 = current_reader_data_3[15:8];
wire [7:0] reader_data_b11 = current_reader_data_3[7:0];
wire [7:0] reader_data_r20 = current_reader_data_4[23:16];
wire [7:0] reader_data_g20 = current_reader_data_4[15:8];
wire [7:0] reader_data_b20 = current_reader_data_4[7:0];
wire [7:0] reader_data_r21 = current_reader_data_5[23:16];
wire [7:0] reader_data_g21 = current_reader_data_5[15:8];
wire [7:0] reader_data_b21 = current_reader_data_5[7:0];
wire [7:0] reader_data_r30 = current_reader_data_6[23:16];
wire [7:0] reader_data_g30 = current_reader_data_6[15:8];
wire [7:0] reader_data_b30 = current_reader_data_6[7:0];
wire [7:0] reader_data_r31 = current_reader_data_7[23:16];
wire [7:0] reader_data_g31 = current_reader_data_7[15:8];
wire [7:0] reader_data_b31 = current_reader_data_7[7:0];

wire [11:0] reader_gamma_r00;
wire [11:0] reader_gamma_g00;
wire [11:0] reader_gamma_b00;
wire [11:0] reader_gamma_r01;
wire [11:0] reader_gamma_g01;
wire [11:0] reader_gamma_b01;
wire [11:0] reader_gamma_r10;
wire [11:0] reader_gamma_g10;
wire [11:0] reader_gamma_b10;
wire [11:0] reader_gamma_r11;
wire [11:0] reader_gamma_g11;
wire [11:0] reader_gamma_b11;
wire [11:0] reader_gamma_r20;
wire [11:0] reader_gamma_g20;
wire [11:0] reader_gamma_b20;
wire [11:0] reader_gamma_r21;
wire [11:0] reader_gamma_g21;
wire [11:0] reader_gamma_b21;
wire [11:0] reader_gamma_r30;
wire [11:0] reader_gamma_g30;
wire [11:0] reader_gamma_b30;
wire [11:0] reader_gamma_r31;
wire [11:0] reader_gamma_g31;
wire [11:0] reader_gamma_b31;

gamma gr00(.in(reader_data_r00), .out(reader_gamma_r00));
gamma gg00(.in(reader_data_g00), .out(reader_gamma_g00));
gamma gb00(.in(reader_data_b00), .out(reader_gamma_b00));
gamma gr01(.in(reader_data_r01), .out(reader_gamma_r01));
gamma gg01(.in(reader_data_g01), .out(reader_gamma_g01));
gamma gb01(.in(reader_data_b01), .out(reader_gamma_b01));
gamma gr10(.in(reader_data_r10), .out(reader_gamma_r10));
gamma gg10(.in(reader_data_g10), .out(reader_gamma_g10));
gamma gb10(.in(reader_data_b10), .out(reader_gamma_b10));
gamma gr11(.in(reader_data_r11), .out(reader_gamma_r11));
gamma gg11(.in(reader_data_g11), .out(reader_gamma_g11));
gamma gb11(.in(reader_data_b11), .out(reader_gamma_b11));
gamma gr20(.in(reader_data_r20), .out(reader_gamma_r20));
gamma gg20(.in(reader_data_g20), .out(reader_gamma_g20));
gamma gb20(.in(reader_data_b20), .out(reader_gamma_b20));
gamma gr21(.in(reader_data_r21), .out(reader_gamma_r21));
gamma gg21(.in(reader_data_g21), .out(reader_gamma_g21));
gamma gb21(.in(reader_data_b21), .out(reader_gamma_b21));
gamma gr30(.in(reader_data_r30), .out(reader_gamma_r30));
gamma gg30(.in(reader_data_g30), .out(reader_gamma_g30));
gamma gb30(.in(reader_data_b30), .out(reader_gamma_b30));
gamma gr31(.in(reader_data_r31), .out(reader_gamma_r31));
gamma gg31(.in(reader_data_g31), .out(reader_gamma_g31));
gamma gb31(.in(reader_data_b31), .out(reader_gamma_b31));

assign LED_R00 = reader_gamma_r00 >> draw_bit;
assign LED_G00 = reader_gamma_g00 >> draw_bit;
assign LED_B00 = reader_gamma_b00 >> draw_bit;
assign LED_R01 = reader_gamma_r01 >> draw_bit;
assign LED_G01 = reader_gamma_g01 >> draw_bit;
assign LED_B01 = reader_gamma_b01 >> draw_bit;
assign LED_R10 = reader_gamma_r00 >> draw_bit;
assign LED_G10 = reader_gamma_g00 >> draw_bit;
assign LED_B10 = reader_gamma_b00 >> draw_bit;
assign LED_R11 = reader_gamma_r01 >> draw_bit;
assign LED_G11 = reader_gamma_g01 >> draw_bit;
assign LED_B11 = reader_gamma_b01 >> draw_bit;
assign LED_R20 = reader_gamma_r00 >> draw_bit;
assign LED_G20 = reader_gamma_g00 >> draw_bit;
assign LED_B20 = reader_gamma_b00 >> draw_bit;
assign LED_R21 = reader_gamma_r01 >> draw_bit;
assign LED_G21 = reader_gamma_g01 >> draw_bit;
assign LED_B21 = reader_gamma_b01 >> draw_bit;
assign LED_R30 = reader_gamma_r00 >> draw_bit;
assign LED_G30 = reader_gamma_g00 >> draw_bit;
assign LED_B30 = reader_gamma_b00 >> draw_bit;
assign LED_R31 = reader_gamma_r01 >> draw_bit;
assign LED_G31 = reader_gamma_g01 >> draw_bit;
assign LED_B31 = reader_gamma_b01 >> draw_bit;
//assign LED_R10 = reader_gamma_r10 >> draw_bit;
//assign LED_G10 = reader_gamma_g10 >> draw_bit;
//assign LED_B10 = reader_gamma_b10 >> draw_bit;
//assign LED_R11 = reader_gamma_r11 >> draw_bit;
//assign LED_G11 = reader_gamma_g11 >> draw_bit;
//assign LED_B11 = reader_gamma_b11 >> draw_bit;
//assign LED_R20 = reader_gamma_r20 >> draw_bit;
//assign LED_G20 = reader_gamma_g20 >> draw_bit;
//assign LED_B20 = reader_gamma_b20 >> draw_bit;
//assign LED_R21 = reader_gamma_r21 >> draw_bit;
//assign LED_G21 = reader_gamma_g21 >> draw_bit;
//assign LED_B21 = reader_gamma_b21 >> draw_bit;
//assign LED_R30 = reader_gamma_r30 >> draw_bit;
//assign LED_G30 = reader_gamma_g30 >> draw_bit;
//assign LED_B30 = reader_gamma_b30 >> draw_bit;
//assign LED_R31 = reader_gamma_r31 >> draw_bit;
//assign LED_G31 = reader_gamma_g31 >> draw_bit;
//assign LED_B31 = reader_gamma_b31 >> draw_bit;

endmodule
