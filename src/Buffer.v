module Buffer (clock, inNum, ena, reset, matrix, conv_valid);
    input clock;
    input reset;    
    input ena;     
    input  [7:0] inNum;
    output [7:0] matrix [0:8];
    output conv_valid;
    parameter W = 128;      

    // column/row count
    reg [6:0] col_cnt;
    reg [6:0] row_cnt;

    // two line buffers 
    reg [7:0] lb0 [0:W-1];  // 1st row
    reg [7:0] lb1 [0:W-1];  // 2nd row

    reg [7:0] r00, r01, r02;  // top
    reg [7:0] r10, r11, r12;  // mid
    reg [7:0] r20, r21, r22;  // bottom 

    //extracting the pixel to insert into the matrix
    wire at_last_col = (col_cnt == W-1);


    //not at last col (right side padding) and row count >=2 use the line buffer, else its 0
    wire [7:0] top_pixel =
    (!at_last_col && row_cnt >= 2) ? lb0[col_cnt] : 8'd0;

    wire [7:0] mid_pixel =
    (!at_last_col && row_cnt >= 1) ? lb1[col_cnt] : 8'd0;

    wire [7:0] bot_pixel =
    at_last_col ? 8'd0 : inNum;
    
   

    // valid once we have 3 rows and 3 cols (with padding)
    assign conv_valid = (row_cnt >= 1) && (col_cnt >= 1);

    // pack the matrix
    assign matrix = '{ r00,r01,r02,
                      r10,r11,r12,
                      r20,r21,r22 };

    integer i;
    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            col_cnt <= 7'd0;
            row_cnt <= 7'd0;

            r00 <= 8'd0; r01 <= 8'd0; r02 <= 8'd0;
            r10 <= 8'd0; r11 <= 8'd0; r12 <= 8'd0;
            r20 <= 8'd0; r21 <= 8'd0; r22 <= 8'd0;

            for (i = 0; i < W; i = i + 1) begin
                lb0[i] <= 8'd0;
                lb1[i] <= 8'd0;
            end
        end else if (ena) begin // shift left
            r00 <= r01;  r01 <= r02;  r02 <= top_pixel;
            r10 <= r11;  r11 <= r12;  r12 <= mid_pixel;
            r20 <= r21;  r21 <= r22;  r22 <= bot_pixel;
            //update line buffers at current column 
            lb0[col_cnt] <= lb1[col_cnt];
            lb1[col_cnt] <= inNum;

            if (col_cnt == (W-1)) begin
                col_cnt <= 7'd0;
                row_cnt <= row_cnt + 7'd1;

                // reset the matrix when moving onto new row
                r00 <= 8'd0; r01 <= 8'd0;
                r10 <= 8'd0; r11 <= 8'd0;
                r20 <= 8'd0; r21 <= 8'd0;
            end else begin
                col_cnt <= col_cnt + 7'd1;
            end
	    end
    end
endmodule
