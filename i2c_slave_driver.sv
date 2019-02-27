`ifndef I2C_SLAVE_DRIVER__SV
`define I2C_SLAVE_DRIVER__SV

// Slave driver waits for a transaction to begin on the interface and responds 
// in accordance with the <i2c_slave_cfg> configuration object members values. 
class i2c_slave_driver extends uvm_driver #(i2c_sequence_item);

  
  virtual i2c_if      sigs;
  i2c_cfg       cfg;
  i2c_common_methods  common_mthds;
  
  int                 number_of_clocks_for_t_hd_dat_max;
  logic [9:0]         address;
  bit   [7:0]         data[int]; //associative array so it can be allocated on the fly
  bit                 start_detection;
      
  event               start_detection_e;
  event               stop_detection_e;
  
  `uvm_component_utils(i2c_slave_driver)
  
  extern         function       new(string name, uvm_component parent);
  extern virtual function void  build_phase(uvm_phase phase);
  extern virtual task           main_phase(uvm_phase phase);
  extern virtual task           slave_search_for_start_condition(uvm_phase phase);
  extern virtual task           slave_search_for_stop_condition(uvm_phase phase);
  extern virtual task           slave_address_is_to_this_slave(output logic address_is_for_salve, output e_i2c_direction transaction_direction);
  extern virtual task           slave_get_read_write(output e_i2c_direction transaction_direction);
  extern virtual task           send_ack();
  extern virtual task           slave_write_request();
  extern virtual task           slave_read_request();
  extern virtual task           wait_for_ack_from_master(output bit ack);
  extern virtual task           wait_for_scl_negedge_plus_t_hd_dat_max();

  endclass: i2c_slave_driver
  
//------------------------------------------------------------------------//
// Function: new
// constructor
function i2c_slave_driver::new(string name, uvm_component parent);
  super.new(name, parent);

endfunction: new

//------------------------------------------------------------------------//
function void i2c_slave_driver::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  if ( cfg  == null ) `uvm_fatal(get_type_name(),  $sformatf("i2c cfg object is null!") )
  
  common_mthds = i2c_common_methods::type_id::create("common_mthds", this);
  common_mthds.sigs = sigs;
  
endfunction: build_phase

//------------------------------------------------------------------------//
task i2c_slave_driver::main_phase(uvm_phase phase);
  logic           enable_slave  = 0;
  int             thread_number = 0;
  process         thread_process[$];
  e_i2c_direction transaction_direction;
  super.main_phase(phase);
  start_detection = 1'b0; 
  
  sigs.scl_out <= 1'b1;
  sigs.sda_out <= 1'b1;
  // setup and calculate values which need to computed once per simulation
  common_mthds.calculate_input_clock_period();
  number_of_clocks_for_t_hd_dat_max = common_mthds.calculate_number_of_clocks_for_time( .time_value(cfg.t_hd_dat_max) );
  //number_of_clocks_for_t_hd_dat_max = common_mthds.calculate_number_of_clocks_for_time( .time_value(1us) );
  //$display("aaaaa  number_of_clocks_for_t_hd_dat_max  %d\n", number_of_clocks_for_t_hd_dat_max);
  `uvm_info(get_full_name(),$sformatf("number_of_clocks_for_t_hd_dat_max  %d\n", number_of_clocks_for_t_hd_dat_max),UVM_LOW)
  
  fork
    //forever common_mthds.drive_x_to_outputs_during_reset();
    forever slave_search_for_start_condition( .phase(phase) );
    forever slave_search_for_stop_condition(  .phase(phase) );
    forever begin

      fork 
        begin // respond to request thread
          thread_process[thread_number] = process::self();
          wait(start_detection_e.triggered);
          slave_address_is_to_this_slave( .address_is_for_salve(enable_slave), .transaction_direction(transaction_direction) );

          if (enable_slave) begin
            //slave_get_read_write( .transaction_direction(transaction_direction) ); 
            //send_ack();
            
            case (transaction_direction)
              I2C_DIR_WRITE : slave_write_request();
              I2C_DIR_READ  : slave_read_request();
              default   : `uvm_fatal(get_type_name(),  $sformatf("Slave read / write request unknown!") )
            endcase
          end
        end
        
        begin // start event is detected, wait for stop or repeated start to end this thread.
          //grab the current thread number since the thread number can increment if the response thread terminates naturally
          int wait_for_thread_number = thread_number;
          wait(start_detection_e.triggered); 
          #1; //wait so start event is no longer triggered
          wait(stop_detection_e.triggered || start_detection_e.triggered);
          
          if(start_detection_e.triggered) phase.drop_objection(this); //continuous start only, stop already drops objection 
          if (thread_process[wait_for_thread_number].status != process::FINISHED) thread_process[wait_for_thread_number].kill();
        end
      join_any
      
      thread_number++; // increment the thread number for next threads spawning

    end
    
  join
  
endtask: main_phase

//------------------------------------------------------------------------//
task i2c_slave_driver::slave_search_for_start_condition(uvm_phase phase);
  
  common_mthds.monitor_for_start_condition( .start_e(start_detection_e) );
  if(start_detection_e.triggered) begin
	//$display("aaaaa    find start sign !");
  	`uvm_info(get_full_name(),$sformatf("find start sign !"),UVM_LOW)
    start_detection = 1'b1;
    phase.raise_objection(this);
    `uvm_info(get_type_name(),  $sformatf("Start detected"), UVM_HIGH )
  end
  
endtask: slave_search_for_start_condition

//------------------------------------------------------------------------//
task i2c_slave_driver::slave_search_for_stop_condition(uvm_phase phase);
  common_mthds.monitor_for_stop_condition( .stop_e(stop_detection_e) );
  if(stop_detection_e.triggered) begin
    `uvm_info(get_type_name(),  $sformatf("Stop detected"), UVM_HIGH )
    if(start_detection) begin // verify a start was triggered before lowering the objection
      `uvm_info(get_type_name(),  $sformatf("Start existed, drop objection"), UVM_FULL )
      start_detection = 1'b0;
      phase.drop_objection(this);
    end
  end
  
endtask: slave_search_for_stop_condition

//------------------------------------------------------------------------//
task i2c_slave_driver::slave_address_is_to_this_slave(output logic address_is_for_salve , output e_i2c_direction transaction_direction);

  address               = '0;
  address_is_for_salve  =  0; 
  `uvm_info(get_type_name(),  $sformatf("Beginning address identification"), UVM_HIGH )
  
  if(cfg.address_num_of_bits == 10)
  	begin
		for(int i = 0; i < 7; i++)begin
			@(posedge sigs.drv_cb.scl_in);
			address = { address[8:0], sigs.drv_cb.sda_in };
		end
		if (address[6:2]==5'b11110 && address[1:0] == cfg.slave_address[9:8])
			begin
				slave_get_read_write( .transaction_direction(transaction_direction) );
				if (transaction_direction == I2C_DIR_WRITE) 
				begin
					send_ack();
					for(int i = 0; i < 8; i++)
					begin
						@(posedge sigs.drv_cb.scl_in);
						address = { address[8:0], sigs.drv_cb.sda_in };
  						if (address === cfg.slave_address)
  							begin
	 							address_is_for_salve = 1;
								//$display("aaaaa addr match !  %h",address);
  								`uvm_info(get_full_name(),$sformatf("addr match !  %h", address),UVM_LOW)
								send_ack();
	 						end
					end
				end
				if (transaction_direction == I2C_DIR_READ) 
				begin
	 				address_is_for_salve = 1;
					send_ack();
				end
				
			end
		else
			//not send ack
			//$display("aaaaa addr unmatch !!!");
  			`uvm_info(get_full_name(),$sformatf("addr unmatch !!!"),UVM_LOW)
	end
  else
  	begin
  		// get address
  		for(int i = 0; i < 7; i++)begin
    		@(posedge sigs.drv_cb.scl_in);
    		address = { address[8:0], sigs.drv_cb.sda_in };
		end
  		if (address === cfg.slave_address)
  			begin
	 			address_is_for_salve = 1;
				//$display("aaaaa addr match !  %h",address);
  				`uvm_info(get_full_name(),$sformatf("addr match !  %h", address),UVM_LOW)
				slave_get_read_write( .transaction_direction(transaction_direction) );
				send_ack();
	 		end
  	end


endtask: slave_address_is_to_this_slave

//------------------------------------------------------------------------//
task i2c_slave_driver::slave_get_read_write(output e_i2c_direction transaction_direction);
  //$display("aaaaa   detect read/write ..."); 
  `uvm_info(get_full_name(),$sformatf("detect read/write ..."),UVM_LOW)
  @(posedge sigs.drv_cb.scl_in);
  transaction_direction = e_i2c_direction'(sigs.drv_cb.sda_in);
  //$display("aaaaa   detect read/write  ok...   %d",transaction_direction); 
  `uvm_info(get_full_name(),$sformatf("detect read/write  ok...   %d", transaction_direction),UVM_LOW)
  
endtask: slave_get_read_write

//------------------------------------------------------------------------//
task i2c_slave_driver::slave_write_request();
  logic [7:0] input_data      = '0;
  int         num_of_accesses =  0;
  `uvm_info(get_type_name(),  $sformatf("Slave write"), UVM_FULL )
  
  while(num_of_accesses <= cfg.max_write_word_access_before_nack) begin
    input_data = '0;
    for (int i = 0; i < 8; i++) begin
      @(posedge sigs.drv_cb.scl_in);
      input_data = { input_data[6:0], sigs.drv_cb.sda_in};
    end
    data[address++] = input_data;
	$display("write date %h",input_data);
	$display("write addr %h",address -1);
    send_ack();
    num_of_accesses++;
  end
  
endtask: slave_write_request

//------------------------------------------------------------------------//
task i2c_slave_driver::slave_read_request();
  //int       current_address   = this.address; // start of read address is the requested address on the i2c bus
  int       current_address   = cfg.slave_address; // start of read address is the requested address on the i2c bus
  bit [7:0] data_to_transmit  = '0;
  bit       ack_from_master   = '0;
  `uvm_info(get_type_name(),  $sformatf("Slave read"), UVM_FULL )
  
  do begin
    if (!data.exists(current_address)) begin
      data[current_address] = $urandom_range(1 << 8); // data values are byte wide
      `uvm_info(get_type_name(),  $sformatf("Created a random value %0h for address %0h", data[current_address], current_address), UVM_LOW )
    end
    
    data_to_transmit = data[current_address];
    `uvm_info(get_type_name(),  $sformatf("transmitting read request data %0h", data_to_transmit), UVM_LOW )
    
    //TX to master the data requested by the read request
    for (int i = 8; i; i--) begin
      sigs.drv_cb.sda_out <= data_to_transmit[i - 1];
      wait_for_scl_negedge_plus_t_hd_dat_max();
    end
    sigs.drv_cb.sda_out <= 1'b1; // done transmitting read request, release the SDA
    
    current_address++;
    wait_for_ack_from_master( .ack(ack_from_master) );
  end 
  while(ack_from_master);
  
endtask: slave_read_request

//------------------------------------------------------------------------//
task i2c_slave_driver::send_ack();
  //$display("aaaaa   sending ack..."); 
  `uvm_info(get_full_name(),$sformatf("sending ack..."),UVM_LOW)
  wait_for_scl_negedge_plus_t_hd_dat_max();
  sigs.drv_cb.sda_out <= 1'b0;
  //$display("aaaaa   drive sda_out = 0..."); 
  `uvm_info(get_full_name(),$sformatf("drive sda_out = 0..."),UVM_LOW)
  
  wait_for_scl_negedge_plus_t_hd_dat_max();
  sigs.drv_cb.sda_out <= 1'b1;
  //$display("aaaaa   sended ack..."); 
  `uvm_info(get_full_name(),$sformatf("sended ack..."),UVM_LOW)
endtask: send_ack

//------------------------------------------------------------------------//
task i2c_slave_driver::wait_for_ack_from_master(output bit ack);
  @(posedge sigs.drv_cb.scl_in);
  ack = ~ (sigs.drv_cb.sda_in); // ack = 0, nack = 1
  `uvm_info(get_type_name(),  $sformatf("received ACK from master %0h", sigs.drv_cb.sda_in), UVM_FULL )
  
  wait_for_scl_negedge_plus_t_hd_dat_max();
endtask: wait_for_ack_from_master

//------------------------------------------------------------------------//
task i2c_slave_driver::wait_for_scl_negedge_plus_t_hd_dat_max();
  @(negedge sigs.drv_cb.scl_in);
  //repeat(number_of_clocks_for_t_hd_dat_max/2) @(sigs.drv_cb);
  repeat(number_of_clocks_for_t_hd_dat_max) @(sigs.drv_cb);
  
endtask: wait_for_scl_negedge_plus_t_hd_dat_max

`endif //I2C_SLAVE_DRIVER__SV

