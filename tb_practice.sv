`timescale 1ns/10ps
`define CYCLE      30.0
`define MAX_CYCLE  200000
`define PATFILE    "test.dat"
`define SDFFILE    "./CONVEX_syn.sdf"

module tb;
    reg         CLK;
    reg         RST;
    reg  [4:0]  PT_XY;
    wire        READ_PT;
    wire [9:0]  DROP_X;
    wire [9:0]  DROP_Y;
    wire        DROP_V;

    integer cycle;
    integer fd;
    integer n_points;
    integer idx;
    integer ret;
    integer cur_x;
    integer cur_y;
    integer drop_count;
    integer idle_count;

    typedef enum reg [2:0] {
        H_IDLE  = 3'd0,
        H_XH    = 3'd1,
        H_XL    = 3'd2,
        H_YH    = 3'd3,
        H_YL    = 3'd4
    } host_state_t;

    host_state_t host_state;

    CONVEX u_convex (
        .CLK(CLK),
        .RST(RST),
        .PT_XY(PT_XY),
        .READ_PT(READ_PT),
        .DROP_X(DROP_X),
        .DROP_Y(DROP_Y),
        .DROP_V(DROP_V)
    );

`ifdef SDF
    initial begin
        $sdf_annotate(`SDFFILE, u_convex);
    end
`endif

    initial CLK = 1'b0;
    always #(`CYCLE/2.0) CLK = ~CLK;

    initial begin
        $fsdbDumpfile("CONVEX.fsdb");
        $fsdbDumpvars(0, tb, "+mda");
    end

    initial begin
        fd = $fopen(`PATFILE, "r");
        if (fd == 0) begin
            $display("ERROR: cannot open %s", `PATFILE);
            $finish;
        end
        ret = $fscanf(fd, "%d\n", n_points);
        if (ret != 1 || n_points <= 0) begin
            $display("ERROR: bad test.dat format. First line must be point count.");
            $finish;
        end
    end

    initial begin
        RST        = 1'b1;
        PT_XY      = 5'd0;
        cycle      = 0;
        idx        = 0;
        cur_x      = 0;
        cur_y      = 0;
        drop_count = 0;
        idle_count = 0;
        host_state = H_IDLE;

        #(2*`CYCLE);
        @(negedge CLK);
        RST = 1'b0;
    end

    always @(posedge CLK) begin
        if (RST) begin
            cycle <= 0;
        end else begin
            cycle <= cycle + 1;
            if (cycle > `MAX_CYCLE) begin
                $display("==================================================");
                $display("TIMEOUT: exceed MAX_CYCLE = %0d", `MAX_CYCLE);
                $display("==================================================");
                $finish;
            end
        end
    end

    always @(negedge CLK) begin
        if (RST) begin
            PT_XY      <= 5'd0;
            host_state <= H_IDLE;
            idx        <= 0;
            idle_count <= 0;
        end else begin
            case (host_state)
                H_IDLE: begin
                    PT_XY <= 5'd0;
                    if (idx < n_points && READ_PT) begin
                        ret = $fscanf(fd, "%d %d\n", cur_x, cur_y);
                        if (ret != 2) begin
                            $display("ERROR: not enough points in %s", `PATFILE);
                            $finish;
                        end
                        $display("[cycle %0d] SEND point #%0d = (%0d, %0d)", cycle, idx, cur_x, cur_y);
                        host_state <= H_XH;
                        idle_count <= 0;
                    end else begin
                        idle_count <= idle_count + 1;
                    end
                end

                H_XH: begin
                    PT_XY <= cur_x[9:5];
                    host_state <= H_XL;
                end

                H_XL: begin
                    PT_XY <= cur_x[4:0];
                    host_state <= H_YH;
                end

                H_YH: begin
                    PT_XY <= cur_y[9:5];
                    host_state <= H_YL;
                end

                H_YL: begin
                    PT_XY <= cur_y[4:0];
                    idx <= idx + 1;
                    host_state <= H_IDLE;
                end

                default: begin
                    PT_XY <= 5'd0;
                    host_state <= H_IDLE;
                end
            endcase
        end
    end

    always @(posedge CLK) begin
        if (!RST && DROP_V) begin
            drop_count <= drop_count + 1;
            $display("[cycle %0d] DROP #%0d => (%0d, %0d)", cycle, drop_count + 1, DROP_X, DROP_Y);
        end
    end

    always @(posedge CLK) begin
        if (!RST && idx >= n_points && host_state == H_IDLE && idle_count > 400) begin
            $display("==================================================");
            $display("Practice simulation done");
            $display("points sent   = %0d", idx);
            $display("drops seen    = %0d", drop_count);
            $display("==================================================");
            $fclose(fd);
            $finish;
        end
    end

endmodule
