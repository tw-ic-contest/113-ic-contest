module cross (
    input [10:0]x1, 
    input [10:0]y1, 
    input [10:0]x2, 
    input [10:0]y2,
    output sign
)
    wire [21:0]lhs; 
    wire [21:0]rhs; 
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
    wire signed [10:0]vec1_x, [10:0]vec2_x, [10:0]vec3_x;
    wire signed [10:0]vec1_y, [10:0]vec2_y, [10:0]vec3_y;
    assign vec1_x = $signed(x2) - $signed(x1);
    assign vec1_y = $signed(y2) - $signed(y1);
    assign vec2_x = $signed(x2) - $signed(x3);
    assign vec2_y = $signed(y2) - $signed(y3);
    assign vec3_x = $signed(x2) - $signed(x);
    assign vec3_y = $signed(y2) - $signed(y);
    wire sign1, sign2, sign3, sign4;
    cross c1(vec1_x, vec1_y, vec2_x, vec2_y, sign1);
    cross c2(vec1_y, vec1_y, vec3_x, vec3_y, sign2);
    cross c3(vec2_x, vec2_y, vec1_x, vec1_y, sign3);
    cross c4(vec2_y, vec2_y, vec3_x, vec3_y, sign4);
    wire [1:0]judge1, [1:0]judge2;
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

    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            state <= 00;
            READ_PT <= 0;
            PT_XY <= 5'b0;
            DROP_X <= 9'b0;
            DROP_Y <= 9'b0;
            DROP_V <= 0;
            input_count <= 0;
            Xh <= 5'b0;
            Xl <= 5'b0;
            Yh <= 5'b0;
            Yl <= 5'b0;
        end

        else begin
            
            case(state)
            00:  
                if(READ_PT) begin
                input_count <= input_count + 1;
                READ_PT = 0;
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
                        stop_READ_PT == 0;
                    end

                    100: begin
                        Yl <= PT_XY;
                        newX <= {Xh, Xl};
                        newY <= {Yh, Yl};
                        input_count <= 0;                        
                    end

                    default: PT_XY;//
                endcase

            01:

            endcase



            
            

        end
    end


endmodule

