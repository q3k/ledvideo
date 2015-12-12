
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
    output wire [7:0] LED_R,
    output wire [7:0] LED_G,
    output wire [7:0] LED_B,
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
wire [23:0] reader_data [0:7];
wire [23:0] reader_data_frame_a [0:7];
wire [23:0] reader_data_frame_b [0:7];
wire frame_a_en = (write_frame_sel == 1);
wire frame_b_en = (write_frame_sel == 0);

wire [7:0] reader_data_r [0:7];
wire [7:0] reader_data_g [0:7];
wire [7:0] reader_data_b [0:7];

wire [11:0] gamma_r [0:7];
wire [11:0] gamma_g [0:7];
wire [11:0] gamma_b [0:7];

genvar i;
generate
    for (i = 0; i < 8; i=i+1) begin : BLOCKS
        assign frame_a_wen[i] = (write_frame_sel == 0) && write_block == i;
        assign frame_b_wen[i] = (write_frame_sel == 1) && write_block == i;
        assign reader_data[i] = frame_a_en ? reader_data_frame_a[i] : reader_data_frame_b[i];
        bram #(
            .RAM_DEPTH(2048)
        ) ram_a (
            .clka(core_clk),
            .addra(write_address),
            .wea(frame_a_wen[i]),
            .dina(dina),
            .addrb(current_reader_address),
            .enb(frame_a_en),
            .doutb(reader_data_frame_a[i])
        );
        bram #(
            .RAM_DEPTH(2048)
        ) ram_b (
            .clka(core_clk),
            .addra(write_address),
            .wea(frame_b_wen[i]),
            .dina(dina),
            .addrb(current_reader_address),
            .enb(frame_b_en),
            .doutb(reader_data_frame_b[i])
        );

        assign reader_data_r[i] = reader_data[i][23:16];
        assign reader_data_g[i] = reader_data[i][15:8];
        assign reader_data_b[i] = reader_data[i][7:0];

        gamma g_r (
            .in(reader_data_r[i]),
            .out(gamma_r[i])
        );
        gamma g_g (
            .in(reader_data_g[i]),
            .out(gamma_g[i])
        );
        gamma g_b (
            .in(reader_data_b[i]),
            .out(gamma_b[i])
        );

        assign LED_R[i] = gamma_r[i] >> draw_bit;
        assign LED_G[i] = gamma_g[i] >> draw_bit;
        assign LED_B[i] = gamma_b[i] >> draw_bit;
    end
endgenerate

   
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
timing_generator tg (
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

endmodule
