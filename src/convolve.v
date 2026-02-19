module convolve (
    input wire signed [7:0] interval [8:0],
    input wire clk, resetn,
    output reg [7:0] convolution // max: 255, min: 0
);
    // get selected kernel from mux
    wire signed [7:0] kernel [8:0];
    kernelMux m1 (.kernelSelect(2'b01), .kernel(kernel));

    // multiply (dot product)
    reg signed [20:0] product [8:0];
    
    always @(posedge clk) begin
        if (!resetn) begin
            product <= '{0, 0, 0, 0, 0, 0, 0, 0, 0};
        end else begin
            integer k;
            for (k = 0; k < 9; k = k + 1) begin
                product[k] <= kernel[k]*interval[k];
            end
        end
    end

    // sum the products
    wire signed [20:0] sum;

    assign sum = product[0] + product[1] + product[2] + product[3] + 
        product[4] + product[5] + product[6] + product[7] + product[8];

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
    input wire [1:0] kernelSelect;
    output reg signed[7:0] kernel [8:0];
);
    // define kernels
    localparam signed [7:0] sobelKernelX [8:0] = '{-1, 0, 1, -2, 0, 2, -1, 0, 1};
    localparam signed [7:0] sobelKernelY [8:0] = '{-1, -2, -1, 0, 0, 0, 1, 2, 1};
    localparam signed [7:0] blurKernel [8:0] = '{1, 1, 1, 1, 1, 1, 1, 1, 1};

    // define mux states
    localparam [1:0] clear = 2'b00, sobX = 2'b01, sobY = 2'b10, blur = 2'b11;

    // mux logic
    always @ (*) begin
        case(kernelSelect)
            clear: kernel = '{0, 0, 0, 0, 0, 0, 0, 0, 0};
            sobX: kernel = sobelKernelX;
            sobY: kernel = sobelKernelY;
            blur: kernel = blurKernel;
        endcase
    end
endmodule