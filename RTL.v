`timescale 1ns/1ps

module system_timebase (
    input  wire clk,
    input  wire rst_n,
    input  wire kick,
    input  wire system_reset_in,
    output reg  [15:0] count
);
    // Fixed: Ensure the counter increments ONLY when not being reset/kicked
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 16'd0;
        else if (kick || system_reset_in)
            count <= 16'd0;
        else
            count <= count + 1'b1;
    end
endmodule

module window_monitor (
    input  wire clk,
    input  wire rst_n,
    input  wire [15:0] count,
    input  wire [15:0] min_threshold,
    input  wire [15:0] max_threshold,
    output reg  win_error
);
    wire early_error_logic;
    wire late_error_logic;

    // Combinational logic for error detection
    assign early_error_logic = (count < min_threshold);
    assign late_error_logic  = (count > max_threshold);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            win_error <= 1'b0;
        end else begin
            // Error is high if we are outside the [min, max] window
            win_error <= early_error_logic | late_error_logic;
        end
    end
endmodule

module safety_ctrl (
    input  wire clk,
    input  wire rst_n,
    input  wire win_error,
    input  wire [15:0] data_in,
    output reg  action_reset,
    output reg  [7:0] safe_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            action_reset <= 1'b0;
            safe_out     <= 8'h00;
        end else begin
            if (win_error) begin
                action_reset <= 1'b1;
                safe_out     <= 8'h00; // Force Safe State
            end else begin
                action_reset <= 1'b0;
                safe_out     <= data_in[7:0];
            end
        end
    end
endmodule

module watchdog_system_top (
    input  wire clk,
    input  wire rst_n,
    input  wire kick,
    input  wire [15:0] min_threshold,
    input  wire [15:0] max_threshold,
    output wire [7:0] safe_state_out
);
    wire [15:0] internal_count;
    wire internal_error;
    wire internal_reset;

    system_timebase u_time (
        .clk(clk),
        .rst_n(rst_n),
        .kick(kick),
        .system_reset_in(internal_reset),
        .count(internal_count)
    );

    window_monitor u_mon (
        .clk(clk),
        .rst_n(rst_n),
        .count(internal_count),
        .min_threshold(min_threshold),
        .max_threshold(max_threshold),
        .win_error(internal_error)
    );

    safety_ctrl u_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .win_error(internal_error),
        .data_in(internal_count),
        .action_reset(internal_reset),
        .safe_out(safe_state_out)
    );
endmodule
