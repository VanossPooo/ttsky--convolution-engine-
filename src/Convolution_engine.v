module convolution_engine (
	input  wire [7:0] ui_in,    // Number to be put in matrix
    	output wire [7:0] uo_out,   // Dedicated outputs
    	input  wire [7:0] uio_in,   // Size
    	output wire [7:0] uio_out,  // IOs: Output path
    	output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    	input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    	input  wire       clk,      // clock
    	input  wire       rst_n );    // reset_n - low to reset

wire [71:0] matrix, convolution;
wire conv_valid;

// instantiate modules
Buffer u1 (.clock(clk), .inNum(ui_in), .ena(ena), .reset(rst_n), .matrix(matrix), .conv_valid(conv_valid));
convolve u2 (.interval(matrix), .clk(clk), .resetn(rst_n), .ena(conv_valid), .convolution(convolution));

assign uo_out = convolution;

endmodule