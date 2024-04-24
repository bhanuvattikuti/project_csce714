//=====================================================================
// Project: 4 core MESI cache design
// File Name: system_bus_interface.sv
// Description: Basic system bus interface including arbiter
// Designers: Venky & Suru
//=====================================================================

interface system_bus_interface(input clk);

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    parameter DATA_WID_LV1        = `DATA_WID_LV1       ;
    parameter ADDR_WID_LV1        = `ADDR_WID_LV1       ;
    parameter NO_OF_CORE            = 4;

    wire [DATA_WID_LV1 - 1 : 0] data_bus_lv1_lv2     ;
    wire [ADDR_WID_LV1 - 1 : 0] addr_bus_lv1_lv2     ;
    wire                        bus_rd               ;
    wire                        bus_rdx              ;
    wire                        lv2_rd               ;
    wire                        lv2_wr               ;
    wire                        lv2_wr_done          ;
    wire                        cp_in_cache          ;
    wire                        data_in_bus_lv1_lv2  ;

    wire                        shared               ;
    wire                        all_invalidation_done;
    wire                        invalidate           ;

    logic [NO_OF_CORE - 1  : 0]   bus_lv1_lv2_gnt_proc ;
    logic [NO_OF_CORE - 1  : 0]   bus_lv1_lv2_req_proc ;
    logic [NO_OF_CORE - 1  : 0]   bus_lv1_lv2_gnt_snoop;
    logic [NO_OF_CORE - 1  : 0]   bus_lv1_lv2_req_snoop;
    logic                       bus_lv1_lv2_gnt_lv2  ;
    logic                       bus_lv1_lv2_req_lv2  ;

//Assertions
//property that checks that signal_1 is asserted in the previous cycle of signal_2 assertion
    property prop_sig1_before_sig2(signal_1,signal_2);
    @(posedge clk)
        signal_2 |-> $past(signal_1);
    endproperty

//ASSERTION1: lv2_wr_done should not be asserted without lv2_wr being asserted in previous cycle
    assert_lv2_wr_done: assert property (prop_sig1_before_sig2(lv2_wr,lv2_wr_done))
    else
    `uvm_error("system_bus_interface",$sformatf("Assertion assert_lv2_wr_done Failed: lv2_wr not asserted before lv2_wr_done goes high"))

/* 
//ASSERTION2: data_in_bus_lv1_lv2 and cp_in_cache should not be asserted without lv2_rd being asserted in previous cycle
property lv2_rd_cp_in_cache;
@(posedge clk)
    (data_in_bus_lv1_lv2 && cp_in_cache)|-> $past(lv2_rd);
endproperty
 assert_lv2_rd_cp_in_cache: assert property( lv2_rd_cp_in_cache)
 else 
    `uvm_error("system_bus_interface",$sformatf("Assertion assert_lv2_rd_cp_in_cache Failed: lv2_rd is not asserted in the previous cycle "))

//TODO: Add assertions at this interface
//There are atleast 20 such assertions. Add as many as you can!!
//ASSERTION 3
property shared_data_in_bus;//shared and data_in_bus_lv1_lv2 asserted together
@(posedge clk)
    shared|-> data_in_bus_lv1_lv2;
endproperty

assert_shared_data_in_bus: assert property(shared_data_in_bus)
else 
    `uvm_error("system_bus_interface",$sformatf("Assertion assert_shared_data_in_bus Failed: shared and data_in_bus_lv1_lv2 are not asserted together "))

// ASSERTION 4:invalidate followed by all_invalidation_done
property invalidate_follow_all;
@(posedge clk)
$rose(invalidate)|=>$rose(all_invalidation_done);
endproperty
assert_invalidate_follow_all: assert property(invalidate_follow_all)
else 
    `uvm_error("system_bus_interface",$sformatf("Assertion assert_invalidate_follow_all Failed: all_invalidation_done is not inserted in the next cycle after invalidate signal is asserted"))


//ASSERTION 5
property req_follow_by_grant;
@(posedge clk)
(bus_lv1_lv2_req_proc[3:0]>0)|=>##[0:$](bus_lv1_lv2_gnt_proc[3:0]>0);
endproperty

assert_req_follow_by_grant: assert property (req_follow_by_grant)
else    
    `uvm_error("system_bus_interface",$sformatf("Assertion assert_req_follow_by_grant Failed: After bus request is made, the grant is not asserted"))

//ASSERTION 6
//if either bus_lv1_lv2_gnt or bus_lv1_lv2_gnt_snoop is asserted, then bus_lv1_lv2_gnt_proc should be asserted

property gnt_follow_gnt_snoop;
@(posedge clk)
( bus_lv1_lv2_gnt_lv2 || (bus_lv1_lv2_gnt_snoop[3:0]>0))|->(bus_lv1_lv2_gnt_proc[3:0]>0);
endproperty

assert_gnt_follow_gnt_snoop: assert property(gnt_follow_gnt_snoop)
else    
    `uvm_error("system_bus_interface",$sformatf("Assertion assert_gnt_follow_gnt_snoop Failed: When either bus_lv1_lv2_gnt or bus_lv1_lv2_gnt_snoop is asserted, then bus_lv1_lv2_gnt_proc is not asserted "))


//ASSERTION 7
//once bus_lv1_lv2_gnt_proc is asserted, then after one cycle the address should be available
property gnt_proc_follow_address;
@(posedge clk)
(|bus_lv1_lv2_gnt_proc)|=>(addr_bus_lv1_lv2[31:0]!==32'bz);
endproperty

assert_gnt_proc_follow_address: assert property(gnt_proc_follow_address)
else
    `uvm_error("system_bus_interface",$sformatf("Assertion assert_gnt_proc_follow_address Failed: Once bus_lv1_lv2_gnt_proc is asserted then in the next cycle addr_bus_lv1_lv2 is not asserted"))

//ASSERTION 8
//once bus_lv1_lv2_gnt_proc is asserted, then after a cycle either lv2_rd or lv2_wr is asserted

property gnt_proc_follow_rd_wr;
@(posedge clk)
(|bus_lv1_lv2_gnt_proc)|=>(lv2_rd || lv2_wr);
endproperty

assert_gnt_proc_follow_rd_wr: assert property(gnt_proc_follow_rd_wr)
else
    `uvm_error("system_bus_interface",$sformatf("Assertion gnt_proc_follow_rd_wr Failed: Once bus_lv1_lv2_gnt_proc is asserted then in the next cycle lv2_rd or lv2_wr is not asserted"))

//ASSERTION 9
//if lv2_rd is asserted then bus_rd or bus_rdx is asserted

property lv2_rd_assert_rd_rdx;
@(posedge clk)
lv2_rd |-> ( bus_rd || bus_rdx);
endproperty

assert_lv2_rd_assert_rd_rdx: assert property(lv2_rd_assert_rd_rdx)
else
    `uvm_error("system_bus_interface",$sformatf("Assertion lv2_rd_assert_rd_rdx Failed: Once lv2_rd is asserted, then either bus_rd or bus_rdx is not asserted"))

//ASSERTION 10
// if bus_lv1_lv2_req_snoop is asserted, then lv2_rd is asserted

property snoop_follow_lv2_rd;
@(posedge clk)
(|bus_lv1_lv2_req_snoop[3:0])|->$past(lv2_rd);
endproperty

assert_snoop_follow_lv2_rd: assert property(snoop_follow_lv2_rd)
else
    `uvm_error("system_bus_interface",$sformatf("Assertion snoop_follow_lv2_rd Failed: Once bus_lv1_lv2_req_proc is asserted, then lv2_rd is not asserted in the past cycle"))
*/
//ASSERTION 11
// if bus_lv1_lv2_req_snoop is asserted then cp_in_cache is also asserted

property snoop_follow_cp_in_cache;
@(posedge clk)
$rose(|bus_lv1_lv2_req_snoop)|-> cp_in_cache;
endproperty

assert_snoop_follow_cp_in_cache: assert property(snoop_follow_cp_in_cache)
else
    `uvm_error("system_bus_interface",$sformatf("Assertion snoop_follow_cp_in_cache Failed: Once bus_lv1_lv2_req_proc is asserted, then cp_in_cache is not asserted"))
//ASSERTION 12
// if bus_lv1_lv2_gnt_proc is asserted, if the next cycle addr_bus_lv1_lv2 is asserted and lv2_rd and lv2_wr is not asserted in the same cycle invalidate signal should get asserted
property gnt_addr_invalidate;
@(posedge clk)
($rose(|bus_lv1_lv2_gnt_proc[3:0]))##1 (addr_bus_lv1_lv2[31:0]!==32'bz && !lv2_wr && !lv2_rd && !bus_rd && !bus_rdx) |->invalidate;
endproperty

assert_gnt_addr_invalidate: assert property(gnt_addr_invalidate)
else 
    `uvm_error("assert_gnt_addr_invalidate",$sformatf("if bus_lv1_lv2_gnt_proc is asserted, if the next cycle addr_bus_lv1_lv2 is asserted and lv2_rd and lv2_wr is not asserted in the same cycle invalidate signal should get asserted"))

 endinterface