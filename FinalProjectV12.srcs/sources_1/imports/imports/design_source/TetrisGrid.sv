module TetrisGrid (
    input logic reset,
    input logic clk,
    input  logic [5:0] old_grid [200],  // Contains the current state of the grid
    output logic [5:0] new_grid [200], // Contains the new state of the grid after processing
    input logic [7:0] keycode,
    output logic [3:0] LED0,
    output logic [3:0] LED1,
    output logic [3:0] LED2,
    output logic [3:0] LED3
);


    logic [7:0] reg1 = shape[31:24];
    logic [7:0] reg2 = shape[23:16];
    logic [7:0] reg3 = shape[15:8];
    logic [7:0] reg4 = shape[7:0];

    logic [7:0] old_reg1;
    logic [7:0] old_reg2;
    logic [7:0] old_reg3;
    logic [7:0] old_reg4;

    logic [8:0] blocks_placed = 8'b00000001;
    logic [31:0] shape;

    logic [31:0] rot1;
    logic [31:0] rot2;
    logic [31:0] rot3;
    logic [31:0] rot4; 

    logic signed [7:0] offset1;
    logic signed [7:0] offset2;
    logic signed [7:0] offset3;
    logic signed [7:0] offset4;
    
    logic [7:0] addr;
    logic [7:0] rot_addr;

    logic [5:0] colors [5:0] = {6'b001001, 6'b001010, 6'b001011, 6'b001100, 6'b001101, 6'b001110};
    logic [5:0] current_color;


    typedef enum {IDLE, SHIFT} state_t;
    state_t current_state, next_state;

    localparam integer COUNT = 15;
    integer counter = COUNT;

    block_rom block_rom (
        //addr is 1-indexed
        .addr(addr),
        .rot_addr(rot_addr),
        .data(shape),
        .rot1(rot1),
        .rot2(rot2),
        .rot3(rot3),
        .rot4(rot4)
    );
    
    // FSM and timer logic to toggle states
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            counter <= COUNT;
            // Reset grid logic might be added here if needed
        end else begin
            if(current_state == IDLE)
            begin
                if(counter == 0)
                begin
                    current_state <= SHIFT;
                    counter <= COUNT;
                end
                else
                begin
                    counter <= counter - 1;
                end
            end
            else
            begin
                current_state <= IDLE;
            end
        end
    end

    // Update grid based on the current state
    always_ff @(posedge clk or posedge reset)
    begin
        if (reset)
        begin
            reg1 = shape[31:24];
            reg2 = shape[23:16];
            reg3 = shape[15:8];
            reg4 = shape[7:0];

            blocks_placed <= 8'b00000001;
            
            for (int i = 0; i < 200; i++) 
            begin
                if (i == reg4 || i == reg3 || i == reg2 || i == reg1)
                begin
                    new_grid[i] <= current_color; 
                end
                else
                begin
                    new_grid[i] <= 6'b000000;
                end
            end
        end

        else if (current_state == SHIFT)
        begin
            if(keycode == 8'h07)
                begin
                    // Shift all rows down by one if permissible
                if ((reg4 % 10 != 9 && (old_grid[reg4+1] == 6'b000000 || old_grid[reg4+1][3] == 1'b1)) && 
                    (reg3 % 10 != 9 && (old_grid[reg3+1] == 6'b000000 || old_grid[reg3+1][3] == 1'b1)) && 
                    (reg2 % 10 != 9 && (old_grid[reg2+1] == 6'b000000 || old_grid[reg2+1][3] == 1'b1)) &&  
                    (reg1 % 10 != 9 && (old_grid[reg1+1] == 6'b000000 || old_grid[reg1+1][3] == 1'b1)))
                begin
                    new_grid[reg4] <= 6'b000000;
                    new_grid[reg3] <= 6'b000000;
                    new_grid[reg2] <= 6'b000000;
                    new_grid[reg1] <= 6'b000000;

                    new_grid[reg4+1] <= old_grid[reg4];
                    new_grid[reg3+1] <= old_grid[reg3];
                    new_grid[reg2+1] <= old_grid[reg2];
                    new_grid[reg1+1] <= old_grid[reg1];

                    reg4 <= reg4 + 1;
                    reg3 <= reg3 + 1;
                    reg2 <= reg2 + 1;
                    reg1 <= reg1 + 1;
                end
                end
            else if(keycode == 8'h04)
                begin
                    // Shift left
                    if ((reg4 % 10 != 0 && (old_grid[reg4-1] == 6'b000000 || old_grid[reg4-1][3] == 1'b1)) && 
                        (reg3 % 10 != 0 && (old_grid[reg3-1] == 6'b000000 || old_grid[reg3-1][3] == 1'b1)) && 
                        (reg2 % 10 != 0 && (old_grid[reg2-1] == 6'b000000 || old_grid[reg2-1][3] == 1'b1)) &&
                        (reg1 % 10 != 0 && (old_grid[reg1-1] == 6'b000000 || old_grid[reg1-1][3] == 1'b1)))
                    begin
                        new_grid[reg4] <= 6'b000000;
                        new_grid[reg2] <= 6'b000000;
                        new_grid[reg3] <= 6'b000000;
                        new_grid[reg1] <= 6'b000000;
                        
                        new_grid[reg4-1] <= old_grid[reg4];
                        new_grid[reg2-1] <= old_grid[reg2];
                        new_grid[reg3-1] <= old_grid[reg3];
                        new_grid[reg1-1] <= old_grid[reg1];
                        
                        reg4 <= reg4 - 1;
                        reg2 <= reg2 - 1;
                        reg3 <= reg3 - 1;
                        reg1 <= reg1 - 1;
                    end
                end

            else if (keycode == 8'h1A)
            begin
                //You can only rotate if Reg + offset = active(1) or empty(0000)

                if (((old_grid[reg4+offset4][3] == 1'b1) || (old_grid[reg4+offset4] == 6'b000000)) &&
                ((old_grid[reg3+offset3][3] == 1'b1) || (old_grid[reg3+offset3] == 6'b000000)) &&
                ((old_grid[reg2+offset2][3] == 1'b1) || (old_grid[reg2+offset2] == 6'b000000)) &&
                ((old_grid[reg1+offset1][3] == 1'b1) || (old_grid[reg1+offset1] == 6'b000000)))
                begin
                    // new_grid[reg4] <= 6'b000000;
                    // new_grid[reg3] <= 6'b000000;
                    // new_grid[reg2] <= 6'b000000;
                    // new_grid[reg1] <= 6'b000000;

                    // new_grid[reg4+offset4] <= old_grid[reg4];
                    // new_grid[reg4+offset4][5:4] <= (new_grid[reg4+offset4][5:4] + 1) % 4;

                    // new_grid[reg3+offset3] <= old_grid[reg3];
                    // new_grid[reg3+offset3][5:4] <= (new_grid[reg3+offset3][5:4] + 1) % 4;

                    // new_grid[reg2+offset2] <= old_grid[reg2];
                    // new_grid[reg2+offset2][5:4] <= (new_grid[reg2+offset2][5:4] + 1) % 4;

                    // new_grid[reg1+offset1] <= old_grid[reg1];
                    // new_grid[reg1+offset1][5:4] <= (new_grid[reg1+offset1][5:4] + 1) % 4;

                    // reg4 <= reg4 + offset4;
                    // reg3 <= reg3 + offset3;
                    // reg2 <= reg2 + offset2;
                    // reg1 <= reg1 + offset1;
                end
            end

            else
            begin
                // Shift all rows down by one if permissible
                if ((old_grid[reg4+10] == 6'b000000 || old_grid[reg4+10][3] == 1'b1) && 
                    (old_grid[reg3+10] == 6'b000000 || old_grid[reg3+10][3] == 1'b1) && 
                    (old_grid[reg2+10] == 6'b000000 || old_grid[reg2+10][3] == 1'b1) && 
                    (old_grid[reg1+10] == 6'b000000 || old_grid[reg1+10][3] == 1'b1) && ((reg4+10) < 200))
                begin
                    new_grid[reg4+10] <= old_grid[reg4];
                    new_grid[reg4] <= 6'b000000;
                    reg4 <= reg4 + 10;

                    new_grid[reg3+10] <= old_grid[reg3];
                    new_grid[reg3] <= 6'b000000;
                    reg3 <= reg3 + 10;

                    new_grid[reg2+10] <= old_grid[reg2];
                    new_grid[reg2] <= 6'b000000;
                    reg2 <= reg2 + 10;

                    new_grid[reg1+10] <= old_grid[reg1];
                    new_grid[reg1] <= 6'b000000;
                    reg1 <= reg1 + 10;
                end
                //if you can't shift down then deactivate and spawn new block
                else
                begin
                    blocks_placed <= blocks_placed + 1;

                    old_reg1 = reg1;
                    old_reg2 = reg2; 
                    old_reg3 = reg3;
                    old_reg4 = reg4;
                    // Deactivate all the blocks at current positions
                    new_grid[old_reg1][3] <= 1'b0;
                    new_grid[old_reg2][3] <= 1'b0;
                    new_grid[old_reg3][3] <= 1'b0;
                    new_grid[old_reg4][3] <= 1'b0;

                    //Clear Row function here
                    for (int r = 1; r < 20; r++)
                    begin
                        if((new_grid[(r * 10)] != 6'b000000) && (new_grid[(r * 10) + 1] != 6'b000000)
                        && (new_grid[(r * 10) + 2] != 6'b000000) && (new_grid[(r * 10) + 3] != 6'b000000)
                        && (new_grid[(r * 10) + 4] != 6'b000000) && (new_grid[(r * 10) + 5] != 6'b000000)
                        && (new_grid[(r * 10) + 6] != 6'b000000) && (new_grid[(r * 10) + 7] != 6'b000000)
                        && (new_grid[(r * 10) + 8] != 6'b000000) && (new_grid[(r * 10 + 9)] != 6'b000000))
                        begin
                            new_grid[(r * 10)] <= 6'b000000;
                            new_grid[(r * 10) + 1] <= 6'b000000;
                            new_grid[(r * 10) + 2] <= 6'b000000;
                            new_grid[(r * 10) + 3] <= 6'b000000;
                            new_grid[(r * 10) + 4] <= 6'b000000;
                            new_grid[(r * 10) + 5] <= 6'b000000;
                            new_grid[(r * 10) + 6] <= 6'b000000;
                            new_grid[(r * 10) + 7] <= 6'b000000;
                            new_grid[(r * 10) + 8] <= 6'b000000;
                            new_grid[(r * 10) + 9] <= 6'b000000;
                            for (int x = 0; x < (r*10); x++)
                            begin
                                new_grid[x+10] <= old_grid[x];
                            end
                        end
                    end

                    // Reset the positions to their initial states
                    reg1 = shape[31:24];
                    reg2 = shape[23:16];
                    reg3 = shape[15:8];
                    reg4 = shape[7:0];

                    new_grid[reg1] <= current_color;
                    new_grid[reg2] <= current_color;
                    new_grid[reg3] <= current_color;
                    new_grid[reg4] <= current_color;

                end
            end
        end
    end

    
    always_comb
    begin
        addr = blocks_placed % 7;
        addr = addr + 1;
        rot_addr = (blocks_placed % 7) * 4 + 8;

        current_color = colors[blocks_placed % 6];

        if(new_grid[reg1][5:4] == 2'b00)
        begin
            offset1 = rot1[31:24];
            offset2 = rot1[23:16];
            offset3 = rot1[15:8];
            offset4 = rot1[7:0];
        end

        else if(new_grid[reg1][5:4] == 2'b01)
        begin
            offset1 = rot2[31:24];
            offset2 = rot2[23:16];
            offset3 = rot2[15:8];
            offset4 = rot2[7:0];
        end

        else if(new_grid[reg1][5:4] == 2'b10)
        begin
            offset1 = rot3[31:24];
            offset2 = rot3[23:16];
            offset3 = rot3[15:8];
            offset4 = rot3[7:0];
        end

        else if(new_grid[reg1][5:4] == 2'b11)
        begin
            offset1 = rot3[31:24];
            offset2 = rot3[23:16];
            offset3 = rot3[15:8];
            offset4 = rot3[7:0];
        end

    end

    always_comb
    begin
        case (current_state)
            IDLE:
            begin
                LED0 = reg4[7:4];
                LED1 = reg4[3:0];
                LED2 = 4'b1111;
                LED3 = 4'b1010;
                // LED2 = reg3[7:4];         
                // LED3 = reg3[3:0];
            end
            
            SHIFT:
            begin
                LED0 = 4'b1100;
                LED1 = reg4[3:0];
                LED2 = 4'b1111;
                LED3 = 4'b1010;
                // LED2 = reg3[7:4];         
                // LED3 = reg3[3:0];
            end
        endcase
    end

endmodule