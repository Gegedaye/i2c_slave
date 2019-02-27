`ifndef I2C_SLAVE_AGENT__SV
`define I2C_SLAVE_AGENT__SV

// Class: i2c_slave_agent
// Contains standard UVM agent objects for a slave agent including a configuration object, driver and monitor. 
class i2c_slave_agent extends uvm_agent;

  // agent variables
  virtual i2c_if      sigs; 
  i2c_cfg       cfg;
  i2c_monitor         mon;
  i2c_slave_driver    drv;
  e_i2c_frequency_mode frequency_mode;
  i2c_ref_model		  mdl;
  i2c_scoreboard	  scb;
  `uvm_component_utils_begin(i2c_slave_agent)
     `uvm_field_object(cfg,  UVM_ALL_ON)
     `uvm_field_object(mon,  UVM_ALL_ON)
     `uvm_field_object(drv,  UVM_ALL_ON)
  `uvm_component_utils_end

  typedef uvm_sequencer #(i2c_sequence_item)  i2c_slave_sequencer;
  uvm_analysis_port #(i2c_sequence_item)      analysis_port;
  uvm_tlm_analysis_fifo #(i2c_sequence_item) agt_mdl_fifo;
  uvm_tlm_analysis_fifo #(i2c_sequence_item) agt_scb_fifo;
  uvm_tlm_analysis_fifo #(i2c_sequence_item) mdl_scb_fifo;
  
  extern         function      new(string name = "i2c_slave_agent", uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  
endclass: i2c_slave_agent

//------------------------------------------------------------------------//
// function: new
// constructor
function i2c_slave_agent::new(string name = "i2c_slave_agent", uvm_component parent);
  super.new(name, parent);
  
endfunction: new

//------------------------------------------------------------------------//
// task: build_phase
// build phase is called by UVM flow. 
function void i2c_slave_agent::build_phase(uvm_phase phase);
  int 		speed_mode;
  int 		slave_addr_bit;
  logic[9:0] slave_address;
  super.build_phase(phase);

  // verify configuration object was set, randomize configuration here and print what was randomized
  uvm_config_db#(i2c_cfg)::get(this, "", "cfg", cfg);
  $display("print cfg !!");
  cfg.print();
  //if ( cfg  == null ) begin
  //  uvm_config_db#(int)::get(this, "", "speed", speed_mode);
  //  uvm_config_db#(int)::get(this, "", "slave_addr_bit", slave_addr_bit);
  //  uvm_config_db#(logic[9:0])::get(this, "", "slave_addr", slave_address);
  //  //$display("slave_address: %h",slave_address);
  //  if(!$cast(frequency_mode,speed_mode))
  //  	$display("cast failed for speed");
  //  //cfg = i2c_slave_cfg::type_id::create("cfg", this);
  //  cfg = new("cfg",frequency_mode);
  //  if ( !cfg.randomize() ) `uvm_warning(get_type_name(), $sformatf("Couldn't randomize configuration!") )
  //  cfg.slave_address=slave_address;
  //  cfg.address_num_of_bits =slave_addr_bit;
  //  $display("slave_cfg info");
  //  cfg.print();
  //end
  
    
  if ( sigs == null ) `uvm_fatal(get_type_name(), $sformatf("%s interface not set!", this.get_full_name() ) )

  mon       = i2c_monitor::type_id::create("mon", this);
  mon.sigs  = sigs; // pass interface into the monitor
  mon.cfg   = cfg;

  if (cfg.is_active) begin
    drv      = i2c_slave_driver::type_id::create("drv", this);
    drv.sigs = sigs; // pass interface into the driver
    drv.cfg  = cfg;
  end  

  agt_mdl_fifo = new("agt_mdl_fifo",this);
  agt_scb_fifo = new("agt_scb_fifo",this);
  mdl_scb_fifo = new("mdl_scb_fifo",this);

  scb = i2c_scoreboard #(i2c_sequence_item)::type_id::create("scb", this);
  mdl = i2c_ref_model#(i2c_sequence_item)::type_id::create("mdl", this);
endfunction: build_phase

//------------------------------------------------------------------//
// task: connect_phase
// connect phase is called by UVM flow. Connects monitor to agents analysis 
// port so monitored transactions can be connected to a scoreboard. 
function void i2c_slave_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  
  this.analysis_port = mon.analysis_port; // bring the monitor analysis port up to the user

  this.mon.analysis_port.connect(agt_mdl_fifo.analysis_export);
  mdl.port.connect(agt_mdl_fifo.blocking_get_export);

  this.mon.analysis_port.connect(agt_scb_fifo.analysis_export);
  scb.act_port.connect(agt_scb_fifo.blocking_get_export);

  mdl.ap.connect(mdl_scb_fifo.analysis_export);
  scb.exp_port.connect(mdl_scb_fifo.blocking_get_export);
endfunction: connect_phase

`endif //I2C_SLAVE_AGENT__SV
