`ifndef I2C_CFG__SV
`define I2C_CFG__SV
	
class i2c_cfg extends uvm_object;
    
  rand uvm_active_passive_enum is_active;
  
  rand int address_num_of_bits;
  rand logic[9:0] slave_address;
  rand int max_write_word_access_before_nack;
  rand int max_read_word_access_before_nack;
    
  e_i2c_frequency_mode frequency_mode_range;
    
  realtime t_hd_dat_max;  // data hold time from the SCL negedge

  `uvm_object_utils_begin(i2c_cfg)
    `uvm_field_enum(uvm_active_passive_enum, is_active,        UVM_ALL_ON)
    `uvm_field_int(address_num_of_bits,                        UVM_ALL_ON)
    `uvm_field_enum(e_i2c_frequency_mode,frequency_mode_range, UVM_ALL_ON)
	`uvm_field_int(slave_address,                     UVM_ALL_ON)
	`uvm_field_int(max_write_word_access_before_nack, UVM_ALL_ON)
	`uvm_field_int(max_read_word_access_before_nack,  UVM_ALL_ON)
  `uvm_object_utils_end

  extern constraint agent_is_active_c;
  extern constraint address_bits_c;
  extern constraint slave_address_c;
  extern constraint max_word_access_c;;
 
  extern function      new(string name = "i2c_cfg" , e_i2c_frequency_mode  mode = I2C_STANDARD_MODE);
  extern function void post_randomize();
endclass: i2c_cfg

//------------------------------------------------------------------------//
function i2c_cfg::new(string name = "i2c_cfg" , e_i2c_frequency_mode  mode = I2C_STANDARD_MODE);
  super.new(name);
  //frequency_mode_range = mode;

endfunction: new
//------------------------------------------------------------------------//
function void i2c_cfg::post_randomize();
  string values_to_log = "";
  
  case(frequency_mode_range)
    I2C_STANDARD_MODE: begin
      t_hd_dat_max = 3.45us;
    end
    
    I2C_FAST_MODE: begin
      t_hd_dat_max = 0.9us;
    end
    
    I2C_HIGH_SPEED_MODE: begin
      t_hd_dat_max = 70ns;
    end
    
    default: `uvm_fatal(get_type_name(), $sformatf("illegal mode %s", frequency_mode_range.name()) )
  endcase

  values_to_log = "i2c bus timing values:\n";
  values_to_log = {values_to_log, "------------------------\n" };
  values_to_log = {values_to_log, $sformatf("t_hd_dat_max = %t\n", t_hd_dat_max)};
  `uvm_info(get_type_name(), values_to_log, UVM_LOW)
endfunction: post_randomize

//------------------------------------------------------------------------//
// constraint: agent_is_active_c
//constraint i2c_cfg::agent_is_active_c { soft is_active == UVM_PASSIVE; }
constraint i2c_cfg::agent_is_active_c { soft is_active == UVM_ACTIVE; }

//------------------------------------------------------------------------//
// constraint: address_bits_c
constraint i2c_cfg::address_bits_c { soft address_num_of_bits == 7; } 

//------------------------------------------------------------------------//
// constraint: slave_address_c
constraint i2c_cfg::slave_address_c { if (is_active == UVM_ACTIVE)  soft slave_address == `I2C_DEFAULT_SLAVE_ADDRESS;
                                            else                          soft slave_address == 0;
											                                          }
//constraint i2c_cfg::max_word_access_c
constraint i2c_cfg::max_word_access_c { 
  if (is_active == UVM_ACTIVE) {
    soft max_write_word_access_before_nack >= 1;
    soft max_write_word_access_before_nack < 50;
    soft max_read_word_access_before_nack == max_write_word_access_before_nack;
  }
  else {
    soft max_write_word_access_before_nack == 0;
    soft max_write_word_access_before_nack == 0;
  }
}

`endif //I2C_CFG__SV 
