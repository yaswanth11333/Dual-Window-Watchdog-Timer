# Read and set up hierarchy
read_verilog RTL.v
hierarchy -check -top watchdog_system_top

# Standard synthesis flow
proc; opt; fsm; opt; memory; opt
techmap; opt
abc; clean

# --- GENERATE REPORTS ---

# 1. Area and Cell Statistic Report
# This creates 'area_report.txt' with the gate count
tee -o area_report.txt stat

# 2. Design Consistency Check Report
# This checks for undriven wires or logic errors
tee -o check_report.txt check

# 3. Hierarchy Report
# This shows how modules u_time, u_mon, and u_ctrl are linked
tee -o hierarchy_report.txt hierarchy -check

# --- WRITE OUTPUT ---
write_verilog netlist.v
