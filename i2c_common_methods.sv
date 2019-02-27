`ifndef I2C_COMMON_METHODS__SV
`define I2C_COMMON_METHODS__SV

class i2c_common_methods extends uvm_object;
  
  virtual i2c_if sigs; // needed to use clocks and set timing limitations
  
  realtime input_clock_period_in_ps; //used to calculate all requests in clock deltas
  
	`uvm_object_utils_begin(i2c_common_methods)
	   `uvm_field_real(input_clock_period_in_ps, UVM_ALL_ON)
	 `uvm_object_utils_end
	
	 
    extern function new(string name = "i2c_common_methods");
    
    extern virtual task         calculate_input_clock_period();
    extern virtual function int calculate_number_of_clocks_for_time( realtime time_value, bit floor_calculation = 1 );
    extern virtual task         drive_x_to_outputs_during_reset();
    extern virtual task         monitor_for_start_condition( ref event start_e );
    extern virtual task         monitor_for_stop_condition( ref event stop_e );
    
endclass: i2c_common_methods

//------------------------------------------------------------------------//
function i2c_common_methods::new(string name = "i2c_common_methods");
  super.new(name);

endfunction: new

//------------------------------------------------------------------------//
task i2c_common_methods::calculate_input_clock_period();
  realtime before_t = 0;
  realtime after_t  = 0;
  
  @(sigs.drv_cb);
  before_t = $realtime;
  @(sigs.drv_cb);
  after_t = $realtime;
  
  input_clock_period_in_ps = (after_t - before_t) / 1ps;
  $display("aaaaa   i2c_common_methods::calculate_input_clock_period  is %d",input_clock_period_in_ps);
  
endtask: calculate_input_clock_period


//------------------------------------------------------------------------//
function int i2c_common_methods::calculate_number_of_clocks_for_time( realtime time_value, bit floor_calculation = 1 );
  int retval;
  if (input_clock_period_in_ps == 0) `uvm_error(get_type_name(), $sformatf("variable input_clock_period_in_ps = %t", input_clock_period_in_ps) )
  
  time_value = time_value / 1ps; // normalize to 1ps resolution
  retval = (time_value / input_clock_period_in_ps);
  $display("aaaaa   time_value %d\n" , time_value);
  $display("aaaaa   retval %d\n", retval);
  
  `uvm_info(get_type_name(), $sformatf("requested time = %t, time calculated in clocks = %t", time_value, retval * input_clock_period_in_ps * 1ps), UVM_LOW )
  
  return retval;
  
endfunction: calculate_number_of_clocks_for_time

//------------------------------------------------------------------------//
task i2c_common_methods::drive_x_to_outputs_during_reset();
  
  wait(sigs.resetn === 1'b0);
  sigs.scl_out <= 'x;
  sigs.sda_out <= 'x;
  
  wait(sigs.resetn === 1'b1);
  sigs.scl_out <= 1'b1;
  sigs.sda_out <= 1'b1;
  
endtask:drive_x_to_outputs_during_reset

//------------------------------------------------------------------------//
task i2c_common_methods::monitor_for_start_condition( ref event start_e );
  wait(sigs.drv_cb.sda_in !== 1'bx); // don't trigger from an X to 0 transition
  @(negedge sigs.drv_cb.sda_in);
  if (sigs.drv_cb.scl_in === 1'b1) begin
    ->start_e;
    sigs.bus_state_ascii = "START";
  end
endtask: monitor_for_start_condition

//------------------------------------------------------------------------//
task i2c_common_methods::monitor_for_stop_condition( ref event stop_e );
  wait(sigs.drv_cb.sda_in !== 1'bx); // don't trigger from an X to 1 transition
  @(posedge sigs.drv_cb.sda_in);
  if (sigs.drv_cb.scl_in === 1'b1) begin
    ->stop_e;
    sigs.bus_state_ascii = "STOP";
  end
endtask: monitor_for_stop_condition

`endif //I2C_COMMON_METHODS__SV
