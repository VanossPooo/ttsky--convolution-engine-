module convolve (
    input wire signed [71:0] interval,
    input wire clk, resetn,
    output reg [7:0] convolution // max: 255, min: 0
);
    // get selected kernel from mux
    wire signed [71:0] kernel;
    kernelMux m1 (.kernelSelect(2'b01), .kernel(kernel));

    // multiply (dot product)
    reg signed [89:0] product; // 90 bits, 10 bits per product
    
    always @(posedge clk) begin
        if (!resetn) begin
            product <= 0;
        end else begin
            integer k;
            for (k = 0; k < 9; k = k + 1) begin
                product[k*10+:10] <= $signed(kernel[k*8+:8])*$signed(interval[k*8+:8]);
            end
        end
    end

    // sum the products
    wire signed [20:0] sum;

    assign sum = product[0+:10] + product[10+:10] + product[20+:10] + product[30+:10] + 
        product[40+:10] + product[50+:10] + product[60+:10] + product[70+:10] + product[80+:10];

    // generate output pixel from sum value
    always @ (*) begin
        if (sum < -255) begin
            convolution = 255;
        end else if  (sum > 255) begin
            convolution = 255;
        end else if (sum < 0) begin
            convolution = (~sum[7:0]) + 1;
        end else begin
            convolution = sum[7:0];
        end
    end

endmodule

module kernelMux (
    input wire [1:0] kernelSelect,
    output reg signed[71:0] kernel
);
    // define kernels
    localparam signed [71:0] sobelKernelX = {-8'h1, 8'h0, 8'h1, -8'h2, 8'h0, 8'h2, -8'h1, 8'h0, 8'h1};
    localparam signed [71:0] sobelKernelY = {-8'h1, -8'h2, -8'h1, 8'h0, 8'h0, 8'h0, 8'h1, 8'h2, 8'h1};
    localparam signed [71:0] blurKernel = {8'h1, 8'h1, 8'h1, 8'h1, 8'h1, 8'h1, 8'h1, 8'h1, 8'h1};

    // define mux states
    localparam [1:0] clear = 2'b00, sobX = 2'b01, sobY = 2'b10, blur = 2'b11;

    // mux logic
    always @ (*) begin
        case(kernelSelect)
            clear: kernel = {8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0};
            sobX: kernel = sobelKernelX;
            sobY: kernel = sobelKernelY;
            blur: kernel = blurKernel;
        endcase
    end
endmodule