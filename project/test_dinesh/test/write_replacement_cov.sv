//=====================================================================
// Project: 4 core MESI cache design
// File Name: write_replacement_cov.sv
// Description: Test for read-miss to I-cache
// Designers: Venky & Suru
//=====================================================================

class write_replacement_cov extends base_test;

    //component macro
    `uvm_component_utils(write_replacement_cov)

    //Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    //UVM build phase
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "tb.vsequencer.run_phase", "default_sequence", write_replacement_cov_seq::type_id::get());
        super.build_phase(phase);
    endfunction : build_phase

    //UVM run phase()
    task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "Executing write_replacement_cov test" , UVM_LOW)
    endtask: run_phase

endclass : write_replacement_cov


// Sequence for a read-miss on I-cache
class write_replacement_cov_seq extends base_vseq;
    //object macro
    `uvm_object_utils(write_replacement_cov_seq)

    cpu_transaction_c trans;
    bit [31:0] addr;
    //constructor
    function new (string name="write_replacement_cov_seq");
        super.new(name);
    endfunction : new

    virtual task body();
        `uvm_do_on_with(trans, p_sequencer.cpu_seqr[1], {request_type == WRITE_REQ; access_cache_type == DCACHE_ACC; address == 32'h4000_0008; data == 32'hFFFF_FFFF;})
`uvm_do_on_with(trans, p_sequencer.cpu_seqr[2], {request_type == WRITE_REQ; access_cache_type == DCACHE_ACC; address == 32'h4000_0008; data == 32'h0000_FFFF;})

        `uvm_do_on_with(trans, p_sequencer.cpu_seqr[1], {request_type == READ_REQ; access_cache_type == DCACHE_ACC; address == 32'h4000_0008; })
        `uvm_do_on_with(trans, p_sequencer.cpu_seqr[3], {request_type == READ_REQ; access_cache_type == DCACHE_ACC; address == 32'h4000_0008; })

    repeat(50)
    begin
    addr = $urandom_range(32'h4000_0000,32'hFFFFFFFF);

            `uvm_do_on_with(trans, p_sequencer.cpu_seqr[1], {request_type == WRITE_REQ; access_cache_type == DCACHE_ACC; address == addr;})
`uvm_do_on_with(trans, p_sequencer.cpu_seqr[2], {request_type == WRITE_REQ; access_cache_type == DCACHE_ACC; address == addr;})

        `uvm_do_on_with(trans, p_sequencer.cpu_seqr[1], {request_type == READ_REQ; access_cache_type == DCACHE_ACC; address == addr; })
        `uvm_do_on_with(trans, p_sequencer.cpu_seqr[3], {request_type == READ_REQ; access_cache_type == DCACHE_ACC; address == addr; })
end

    endtask

endclass : write_replacement_cov_seq
