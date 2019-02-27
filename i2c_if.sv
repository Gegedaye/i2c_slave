`ifndef I2C_IF__SV
`define I2C_IF__SV
    
interface i2c_if (input bit  clk,
                  inout wire sda,
                  inout wire scl
                 );
  timeunit 1ns/1ps;
  
  logic resetn; // used for i2c block level verification

  //----------------------------------------------------------------------//
  // signals sampled/driven by the agents 
  logic sda_in;
  logic sda_out;
  logic scl_in;
  logic scl_out;
  //----------------------------------------------------------------------//
  /// connectivity between the agent and the physical pins
  assign sda    = sda_out ? 1'bz : sda_out;
  assign sda_in = sda;
  
  assign scl    = scl_out ? 1'bz : scl_out;
  assign scl_in = scl;

  //----------------------------------------------------------------------//
  logic [255:0] bus_state_ascii; // ASCII showing the recognized state of the bus

  //----------------------------------------------------------------------//
  clocking drv_cb @(posedge clk);
      //default input #1step output #1;
      
      input   resetn;
      
      input   sda_in;
      output  sda_out;
      
      input   scl_in;
      output  scl_out;
  
  endclocking: drv_cb
  
  //---------------------------------//
  clocking mon_cb @(posedge clk);
      //default input #1step output #1;
      
      input scl_in;
      input sda_in;
      
  endclocking: mon_cb

endinterface: i2c_if
    
`endif //I2C_IF__SV
