class i2c_scoreboard extends uvm_scoreboard;
	i2c_sequence_item expect_queue[$];
	i2c_sequence_item actual_queue[$];
	uvm_blocking_get_port #(i2c_sequence_item) exp_port;
	uvm_blocking_get_port #(i2c_sequence_item) act_port;
	`uvm_component_utils(i2c_scoreboard)

	extern function new(string name, uvm_component parent = null);
	extern virtual function void build_phase(uvm_phase phase);
	extern virtual task main_phase(uvm_phase phase);
endclass

function i2c_scoreboard::new(string name, uvm_component parent = null);
	super.new(name ,parent);
endfunction

function void i2c_scoreboard::build_phase(uvm_phase phase);
	super.build_phase(phase);
	exp_port = new("exp_port", this);
	act_port = new("act_port", this);
endfunction

task i2c_scoreboard::main_phase(uvm_phase phase);
	i2c_sequence_item get_expect, get_actual, tmp_act, tmp_exp;
	bit result;

	super.main_phase(phase);
	fork
		while(1)
			begin
				exp_port.get(get_expect);
				$display("scb: get exp from ref +1");
				expect_queue.push_back(get_expect);
			end
		while(1)
			begin
				act_port.get(get_actual);
				$display("scb: get act from mon +1");
				actual_queue.push_back(get_actual);
				if(expect_queue.size()>0 & expect_queue.size()>0)
					begin
						//tmp_tran = expect_queue.pop_back();
						tmp_act = actual_queue.pop_front();
						tmp_exp = expect_queue.pop_front();
						$display("compare start ");
						result = tmp_act.compare(tmp_exp);
						if(result)
							begin
								`uvm_info("i2c_scoreboard", $psprintf("compare pass !!!"), UVM_LOW);
							end
						else
							`uvm_info("i2c_scoreboard", $psprintf("compare error !!!"), UVM_LOW);
					end
			end
	join
endtask
