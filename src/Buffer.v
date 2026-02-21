module Buffer (
    input        clock,
    input        reset,    
    input        ena,
    input  [7:0]  inNum,
    output [71:0] matrix,
    output        conv_valid
);

    parameter W = 128;
    parameter H = 128;

    // Row and Col count
    reg [7:0] col_cnt;  
    reg [7:0] row_cnt;   

    // States for padding
    reg pad_col;         // 1 = extra right-pad column 
    reg pad_row;         // 1 = extra bottom-pad row 

    // Two line buffers (store REAL pixels only)
    reg [7:0] lb0 [0:W-1];  //top
    reg [7:0] lb1 [0:W-1]; //middle

    // 3x3 window regs
    reg [7:0] r00, r01, r02;
    reg [7:0] r10, r11, r12;
    reg [7:0] r20, r21, r22;

    // During pad_col, we must not index out-of-range, so use W-1
    wire [7:0] col_idx = pad_col ? (W-1) : col_cnt;

    // Top/mid come from previous rows (or 0 for top padding)
    wire [7:0] top_pixel = (row_cnt >= 2) ? lb0[col_idx] : 8'd0;
    wire [7:0] mid_pixel = (row_cnt >= 1) ? lb1[col_idx] : 8'd0;

    // during pad_col: insert 0 (right padding column)
    // during pad_row: insert 0 (bottom padding row)
    // otherwise: insert real input pixel
    wire [7:0] bot_insert = (pad_col || pad_row) ? 8'd0 : inNum;

    // pack the matrix
    assign matrix = { r00,r01,r02,
                      r10,r11,r12,
                      r20,r21,r22 };

   //valid once we have at least 2 rows and cols loaded
    assign conv_valid = (row_cnt >= 1) && ( (col_cnt >= 1) || pad_col );

    integer i;

    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            col_cnt <= 0;
            row_cnt <= 0;
            pad_col <= 1'b0;
            pad_row <= 1'b0;

            r00 <= 0; r01 <= 0; r02 <= 0;
            r10 <= 0; r11 <= 0; r12 <= 0;
            r20 <= 0; r21 <= 0; r22 <= 0;

            for (i = 0; i < W; i = i + 1) begin
                lb0[i] <= 0;
                lb1[i] <= 0;
            end

        end else if (ena) begin
            // shift left and insert right 
            r00 <= r01;  r01 <= r02;  r02 <= top_pixel;
            r10 <= r11;  r11 <= r12;  r12 <= mid_pixel;
            r20 <= r21;  r21 <= r22;  r22 <= bot_insert;

            // Update line buffers ONLY on real pixels
            if (!pad_col && !pad_row) begin
                lb0[col_cnt] <= lb1[col_cnt];
                lb1[col_cnt] <= inNum;
            end

            if (!pad_col) begin
                if (col_cnt == (W-1)) begin
                    // at last col, enable padding
                    pad_col <= 1'b1;
                end else begin
                    col_cnt <= col_cnt + 1;
                end
            end else begin
                // if this was the padding cycle, reset 
                pad_col <= 1'b0;
                col_cnt <= 0;

                if (!pad_row) begin
                    if (row_cnt == (H-1)) begin
                        // enable row padding at last row
                        pad_row <= 1'b1;
                        row_cnt <= row_cnt + 1; 
                    end else begin
                        row_cnt <= row_cnt + 1;
                    end
                end else begin
                    // reset if this was the row padding cycle
                    pad_row <= 1'b0;
                    row_cnt <= 0;
                end

                // Reset for new matrix (also help left padding)
                r00 <= 0; r01 <= 0;
                r10 <= 0; r11 <= 0;
                r20 <= 0; r21 <= 0;
            end
        end
    end

endmodule
