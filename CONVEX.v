module _cross (
    input signed [10:0]x1, 
    input signed [10:0]y1, 
    input signed [10:0]x2, 
    input signed [10:0]y2,
    output sign
);
    wire signed [21:0]lhs; 
    wire signed [21:0]rhs; 
    assign lhs = x1 * y2;
    assign rhs = x2 * y1;
    assign sign = (lhs >= rhs) ? 1 : 0; 
endmodule

module judge (
    input [9:0]x1, 
    input [9:0]y1,
    input [9:0]x2, 
    input [9:0]y2,
    input [9:0]x3, 
    input [9:0]y3,
    input [9:0]x, 
    input [9:0]y,
    output [1:0]result
);
    wire signed [10:0]vec1_x; wire signed [10:0]vec2_x; wire signed [10:0]vec3_x;
    wire signed [10:0]vec1_y; wire signed [10:0]vec2_y; wire signed [10:0]vec3_y;
    assign vec1_x = $signed(x2) - $signed(x1);
    assign vec1_y = $signed(y2) - $signed(y1);
    assign vec2_x = $signed(x2) - $signed(x3);
    assign vec2_y = $signed(y2) - $signed(y3);
    assign vec3_x = $signed(x2) - $signed(x);
    assign vec3_y = $signed(y2) - $signed(y);
    wire sign1, sign2, sign3, sign4;
    _cross c1(vec1_x, vec1_y, vec2_x, vec2_y, sign1);
    _cross c2(vec1_x, vec1_y, vec3_x, vec3_y, sign2);
    _cross c3(vec2_x, vec2_y, vec1_x, vec1_y, sign3);
    _cross c4(vec2_x, vec2_y, vec3_x, vec3_y, sign4);
    wire [1:0]judge1;
    wire [1:0]judge2;

    assign judge1[1] = 0;
    assign judge2[1] = 0;

    assign judge1[0] = (sign1 == sign2);
    assign judge2[0] = (sign3 == sign4);
    assign result = judge1 + judge2;

endmodule


module CONVEX (CLK, RST, PT_XY, READ_PT, DROP_X, DROP_Y, DROP_V);
    input CLK;
    input RST;
    input [4:0] PT_XY;
    output reg READ_PT;
    output reg [9:0] DROP_X;
    output reg [9:0] DROP_Y;
    output reg DROP_V;

    reg [1:0] state;

    reg [2:0] input_count;
    reg stop_READ_PT;

    reg [4:0] Xh;
    reg [4:0] Xl;
    reg [4:0] Yh;
    reg [4:0] Yl;

    reg [9:0] newX;
    reg [9:0] newY;
    
    reg [9:0] points_sorted_x [12:0];
    reg [9:0] points_sorted_y [12:0];
    reg [3:0] points_size;
    reg [9:0] points_swap_x [12:0];
    reg [9:0] points_swap_y [12:0];
    reg [3:0] swap_idx;
    reg [3:0] i;

    reg [1:0] points_judged [12:0];
    reg [3:0] insert;
    
    reg [9:0]x1; reg [9:0]y1; reg[9:0]x2; reg [9:0]y2; reg [9:0]x3; reg [9:0]y3; reg [9:0]x; reg [9:0]y; reg [1:0]result;
    reg flag;
    
    judge _judge(x1, y1, x2, y2, x3, y3, x, y, result);

    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            state <= 00;
            READ_PT <= 1;
            DROP_X <= 9'b0;
            DROP_Y <= 9'b0;
            DROP_V <= 0;
            input_count <= 0;
            Xh <= 5'b0;
            Xl <= 5'b0;
            Yh <= 5'b0;
            Yl <= 5'b0;
            points_size <= 0;
            swap_idx <= 0;
            i <= 0;
            points_judged[0] <= 10;
            points_judged[1] <= 10;
            points_judged[2] <= 10;
        end

        else begin
            
            case(state)
            
            00: begin //INPUT STATE: get newX and newY
                DROP_V <= 0;
                if(READ_PT == 1) begin
                input_count <= input_count + 1;
                READ_PT <= 0;
                end

                case(input_count)
                    001: begin
                        Xh <= PT_XY;
                        input_count <= input_count + 1;
                    end

                    010: begin
                        Xl <= PT_XY;
                        input_count <= input_count + 1;
                    end

                    011: begin
                        Yh <= PT_XY;
                        input_count <= input_count + 1;
                        stop_READ_PT <= 0;
                    end

                    100: begin
                        Yl <= PT_XY;
                        newX <= {Xh, Xl};
                        newY <= {Yh, Yl};
                        input_count <= 0;
                        i <= 0;
                        flag <= 0;
                        state <= 01; //Finish input, starts judging                      
                    end

                    default: begin end

                endcase
            end 




            01 : begin// JUDGING STATE: judge every vertice's status STATE (drop, tangent, dont care)
                DROP_V <= 0;
                if (points_size == 0) begin
                    insert <= points_size;
                    state <= 11;
                    swap_idx <= swap_idx + 1;
                    flag <= 0;


                end else if (points_size == 1) begin
                    insert <= points_size;
                    state <= 11;
                    swap_idx <= swap_idx + 1;
                    points_swap_x[0] <= points_sorted_x[0];
                    points_swap_y[0] <= points_sorted_y[0];
                    flag <= 0;
                    
                end else if (points_size == 2) begin
                    state <= 11;
                    insert <= points_size;
                    swap_idx <= swap_idx + 1;
                    points_swap_x[0] <= points_sorted_x[0];
                    points_swap_y[0] <= points_sorted_y[0];
                    points_swap_x[1] <= points_sorted_x[1];
                    points_swap_y[1] <= points_sorted_y[1];
                    flag <= 0;

                end else begin

                    if(i < points_size - 2) begin
                        if (flag == 0) begin
                            x1 <= points_sorted_x[i];
                            y1 <= points_sorted_y[i];
                            x2 <= points_sorted_x[i+1];
                            y2 <= points_sorted_y[i+1];
                            x3 <= points_sorted_x[i+2];
                            y3 <= points_sorted_y[i+2];
                            x <= newX;
                            y <= newY;
                            flag <= 1;
                        end else begin
                            points_judged[i + 1] <= result;
                            flag <= 0;
                            i <= i + 1;
                        end
                        
                        
                    end else if (i == points_size - 2) begin
                        
                        if (flag == 0) begin
                            x1 <= points_sorted_x[i];
                            y1 <= points_sorted_y[i];
                            x2 <= points_sorted_x[i+1];
                            y2 <= points_sorted_y[i+1];
                            x3 <= points_sorted_x[0];
                            y3 <= points_sorted_y[0];
                            x <= newX;
                            y <= newY;
                            flag <= 1;
                        end else begin
                            points_judged[i + 1] <= result;
                            flag <= 0;
                            i <= i + 1;
                        end
                              
                    end else if (i == points_size - 1) begin
                        if (flag == 0) begin
                            x1 <= points_sorted_x[i];
                            y1 <= points_sorted_y[i];
                            x2 <= points_sorted_x[0];
                            y2 <= points_sorted_y[0];
                            x3 <= points_sorted_x[1];
                            y3 <= points_sorted_y[1];
                            x <= newX;
                            y <= newY;
                            flag <= 1;
                        end else begin
                            points_judged[0] <= result;
                            flag <= 0;
                            i <= 0;
                            swap_idx <= 0;
                            state <= 10;
                        end
                    end
                end
            end



            10: begin//SORTING STATE: Sorting the new points 

                case (points_judged[i])
                    00: begin
                        // drop
                        DROP_V <= 1;
                        DROP_X <= points_sorted_x[i];
                        DROP_Y <= points_sorted_y[i];                                
                    end
                    01: begin
                        // tangent
                        DROP_V <= 0;
                        if (i == 0) begin 
                            if (points_judged[points_size - 1] == 00) begin
                                insert <= swap_idx;
                                points_swap_x[swap_idx + 1] <= points_sorted_x[i];
                                points_swap_y[swap_idx + 1] <= points_sorted_y[i];
                                swap_idx <= swap_idx + 2;
                            end else begin
                                points_swap_x[swap_idx] <= points_sorted_x[i];
                                points_swap_y[swap_idx] <= points_sorted_y[i];
                                swap_idx <= swap_idx + 1;
                            end
                        end else begin
                            if (points_judged[i - 1] == 00) begin
                                insert <= swap_idx;
                                points_swap_x[swap_idx + 1] <= points_sorted_x[i];
                                points_swap_y[swap_idx + 1] <= points_sorted_y[i];
                                swap_idx <= swap_idx + 2;
                            end else begin
                                points_swap_x[swap_idx] <= points_sorted_x[i];
                                points_swap_y[swap_idx] <= points_sorted_y[i];
                                swap_idx <= swap_idx + 1;
                            end
                        end
                    end

                        
                    10: begin
                        // dont care
                        DROP_V <= 0;
                        points_swap_x[swap_idx] <= points_sorted_x[i];
                        points_swap_y[swap_idx] <= points_sorted_y[i];
                        swap_idx <= swap_idx + 1;
                    end
                endcase



                if (i == points_size - 1) begin
                    i <= 0;
                    state <= 11;
                    flag <= 0;
                end else begin
                    i <= i + 1;
                
                end
            end

                

            11: begin  //SWAPING STAGE: swap the sorted 
                DROP_V <= 0;
                if (flag == 0) begin
                    points_swap_x[insert] <= newX;
                    points_swap_y[insert] <= newY;
                    flag <= 1;
                end else begin
                    points_size <= swap_idx;
                    points_sorted_x <= points_swap_x;
                    points_sorted_y <= points_swap_y;
                    state <= 00;
                    READ_PT <= 1;
                end
            end
                

            endcase

        end
    end


endmodule