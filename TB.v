module tb_watchdog_system();
    reg clk;
    reg rst_n;
    reg kick;
    reg [15:0] min_th;
    reg [15:0] max_th;
    wire [7:0] safe_out;

    // Instantiate Top Module
    watchdog_system_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .kick(kick),
        .min_threshold(min_th),
        .max_threshold(max_th),
        .safe_state_out(safe_out)
    );

    // Clock Generation
    always #5 clk = ~clk;

    initial begin
        // VCD Dumping - Updated for better GTKWave visibility
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_watchdog_system);

        // Initialize
        clk = 0;
        rst_n = 0;
        kick = 0;
        min_th = 16'd20; 
        max_th = 16'd50; 

        // Apply Reset
        #20 rst_n = 1;
        $display("Reset released at 20ns");

        // Test Case 1: Normal Operation (Kick within window)
        // Wait until count reaches ~30
        repeat (35) @(posedge clk);
        kick = 1; 
        #10 kick = 0;
        $display("TC1: Kick applied at count 30.");

        // Test Case 2: Early Error (Kick too soon)
        // Reset count manually or wait for next cycle
        #50;
        repeat (5) @(posedge clk);
        kick = 1; 
        #10 kick = 0;
        $display("TC2: Early Kick applied. Check for safe_out=0.");

        // Test Case 3: Late Error (Timeout)
        #200; // Let it run past max_th (50)
        
        #500 $finish;
    end
endmodule
