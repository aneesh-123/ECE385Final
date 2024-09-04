module color_mapper (
    // input  logic clk,                   // Clock input
    // input  logic reset,                 // Reset input
    input  logic [9:0] DrawX, DrawY,    // Drawing coordinates (pixel)
    output logic [3:0] Red, Green, Blue, // RGB outputs
    input logic [5:0] grid_state[200]
);
  
    logic [9:0] row_val;
    logic [9:0] col_val;
    logic [9:0] reg_num;
    logic [2:0] color_select;
    logic border;

    // Color output logic based on the state
    always_comb 
    begin
        if(DrawX < 220 && DrawX > 19 && DrawY > 79)
            begin
                col_val = ((DrawX - 20) / 20);
                row_val = ((DrawY - 80) / 20);
                reg_num = (row_val * 10) + col_val;
                   

                if(DrawX % 20 == 0 || DrawX % 20 == 19 || DrawY % 20 == 0 || DrawY % 20 == 19)
                    begin
                        border = 1'b1;
                    end
                else
                    begin
                        border = 1'b0;
                    end
                
                if(border)
                    begin
                        Red = 4'b1111;
                        Green = 4'b1111;
                        Blue = 4'b1111;
                    end
                else
                    begin
                        color_select = grid_state[reg_num][2:0];
                            // Adaptation: setting RGB based on out_reg
                        case (color_select)
                            3'b000: {Red, Green, Blue} = 12'b0000_0000_0000; // Black
                            3'b001: {Red, Green, Blue} = 12'b0000_0000_1111; // Blue
                            3'b010: {Red, Green, Blue} = 12'b0000_1111_0000; // Green
                            3'b011: {Red, Green, Blue} = 12'b1111_0000_0000; // Red
                            3'b100: {Red, Green, Blue} = 12'b1111_0000_1010; // Orange
                            3'b101: {Red, Green, Blue} = 12'b1111_0000_1111; // Yellow
                            3'b110: {Red, Green, Blue} = 12'b1000_0000_1000; // Purple
                            3'b111: {Red, Green, Blue} = 12'b1111_1111_1111; // White
                            default: {Red, Green, Blue} = 12'b0000_0000_0000; // Default to Black
                        endcase
                    end       
            end
        else
            begin
                {Red, Green, Blue} = 12'b0101_0101_0101;
            end        
                
    end            
endmodule
