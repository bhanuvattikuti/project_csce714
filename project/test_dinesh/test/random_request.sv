//=====================================================================
// Project: 4 core MESI cache design
// File Name: random_request.sv
// Description: Test for read-miss to I-cache
// Designers: Venky & Suru
//=====================================================================

class random_request extends base_test;

    //component macro
    `uvm_component_utils(random_request)

    //Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    //UVM build phase
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "tb.vsequencer.run_phase", "default_sequence", random_request_seq::type_id::get());
        super.build_phase(phase);
    endfunction : build_phase

    //UVM run phase()
    task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "Executing random_request test" , UVM_LOW)
    endtask: run_phase

endclass : random_request


// Sequence for a read-miss on I-cache
class random_request_seq extends base_vseq;
    //object macro
    `uvm_object_utils(random_request_seq)

    cpu_transaction_c trans;
	int p;
    //constructor
    function new (string name="random_request_seq");
        super.new(name);
    endfunction : new

    virtual task body();
        repeat(100)begin
	p=$urandom_range(0,3);
        `uvm_do_on_with(trans, p_sequencer.cpu_seqr[p], { })
	end
    endtask

endclass : random_request_seq

