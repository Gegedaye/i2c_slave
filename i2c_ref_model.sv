class i2c_ref_model extends uvm_component;

	uvm_blocking_get_port #(i2c_sequence_item) port;
	uvm_analysis_port #(i2c_sequence_item) ap;

	extern function new(string name, uvm_component parent);
	extern virtual function void build_phase(uvm_phase phase);
	extern virtual task main_phase(uvm_phase phase);

	`uvm_component_utils(i2c_ref_model)
endclass

function i2c_ref_model::new(string name, uvm_component parent);
	super.new(name , parent);
endfunction

function void i2c_ref_model::build_phase(uvm_phase phase);
	super.build_phase(phase);
	port = new("port", this);
	ap = new("ap", this);
endfunction

task i2c_ref_model::main_phase(uvm_phase phase);
	i2c_sequence_item tr;
	i2c_sequence_item new_tr;
	super.main_phase(phase);
	while(1)
		begin
			port.get(tr);
			$display("ref: get tr +1");
			new_tr = new("new_tr");
			new_tr.copy(tr);
			new_tr.print();
			ap.write(new_tr);
			$display("ref: write tr +1");
		end
endtask
