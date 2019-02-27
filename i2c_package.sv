`ifndef I2C_PACKAGE__SV
`define I2C_PACKAGE__SV

package i2c_package;
  
  timeunit      1ns;
  timeprecision 1ps;
  
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "param.sv"
  `include "i2c_cfg.sv"
  `include "i2c_slave_cfg.sv"
  `include "i2c_sequence_item.sv"
  `include "i2c_common_methods.sv"
  `include "i2c_monitor.sv"
  `include "i2c_slave_driver.sv"
  `include "i2c_ref_model.sv"
  `include "i2c_scoreboard.sv"
  `include "i2c_slave_agent.sv"
  
endpackage: i2c_package

`endif // I2C_PACKAGE__SV
