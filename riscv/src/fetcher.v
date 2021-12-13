`include "config.v"

module fetcher (
    input clk,
    input rst,
    input rdy,
    input has_misbranch,
    //to ask_memory
    output reg [`Addr_Len] out_mem_addr,
    output reg mem_ask,

    //from ask_memory
    input [`Data_Len] in_mem_inst,
    input in_mem_ready, // only retain true for one clock
    
    //to pc_reg
    output reg[`Data_Len] out_pc_inst,
    output reg pc_reg_ask,

    //from pc_reg
    input [`Addr_Len] in_pc_addr,
    input pc_ready, //true only when the fetcher ask for the pc, and pc get the pc after next clock, and only retain true for one clock
    input in_has_jump,
    
    //to issue
    output reg can_issue,
    output reg [`Inst_Len] out_issue_inst,
    output reg [`Addr_Len] out_issue_pc,
    output reg out_has_jump,

    //from ROB
    input rob_avail,

    //from RS
    input rs_avail,

    //from slbuffer
    input slb_avail


    
);   
    //pc[1:0] byte_selector  pc[9:2]index  pc[31:10]tag
    reg valid[`Icache_Size];
    reg [21:0] tag[`Icache_Size];
    reg [`Data_Len] instuction[`Icache_Size]; 
    reg can_begin;
    reg misbranch_recover;
    reg wait_issue;
    wire allready;
    assign all_ready = rob_avail && rs_avail && slb_avail;
    integer i;


    always @(posedge clk) begin
        if(rst) begin
            can_issue <= `False;
            mem_ask <= `False;
            pc_reg_ask <= `False;
            wait_issue <= `False;
            misbranch_recover <= `False;
            can_begin <= `True;
            for(i=0; i<255; i=i+1)begin
                valid[i] <= `False;
            end
        end
        else if (rdy) begin
            pc_reg_ask <= `False;
            mem_ask <= `False;
            can_issue <= `False;
            if(can_begin) begin
                can_begin <= `False;
                out_mem_addr <= `Zero_Addr;
                mem_ask <= `True;
            end
            else if(has_misbranch) begin
                misbranch_recover <= `True;
                mem_ask <= `False;
                pc_reg_ask <= `False;
                can_issue <= `False;
                wait_issue <= `False;
            end
            else if(misbranch_recover) begin
                out_mem_addr <= in_pc_addr;
                mem_ask <= `True;
                misbranch_recover <= `False;
            end
            else begin
                if(wait_issue && all_ready)begin
                    wait_issue <= `False;
                    if(out_issue_inst!=32'd0)
                    can_issue <= `True;
                    pc_reg_ask <= `True;
                    out_pc_inst <= out_issue_inst;
                end
                if(in_mem_ready)begin
                    instuction[in_pc_addr[9:2]] <= in_mem_inst;
                    tag[in_pc_addr[9:2]] <= in_pc_addr[31:10];
                    valid[in_pc_addr[9:2]] <= `True;
                    out_issue_inst <= in_mem_inst;
                    out_issue_pc <= in_pc_addr;
                    out_has_jump <= in_has_jump;
                    if(all_ready) begin
                        if(in_mem_inst!=32'd0)
                        can_issue <= `True;
                        pc_reg_ask <= `True;
                        out_pc_inst <= in_mem_inst;
                    end
                    else begin
                        wait_issue <= `True;
                    end
                end
                if(pc_ready) begin
                    if(valid[in_pc_addr[9:2]] && tag[in_pc_addr[9:2]]==in_pc_addr[31:10]) begin
                        out_issue_inst <= instuction[in_pc_addr[9:2]];
                        out_issue_pc <= in_pc_addr;
                        out_has_jump <= in_has_jump;
                        if(all_ready) begin
                            if(instuction[in_pc_addr[9:2]]!=32'd0)
                            can_issue <= `True;
                            pc_reg_ask <= `True;
                            out_pc_inst <= instuction[in_pc_addr[9:2]];
                        end 
                        else begin
                            wait_issue <= `True;
                        end
                    end
                    else begin
                        out_mem_addr <= in_pc_addr;
                        mem_ask <= `True;
                    end
                end
            end
        end
    end    
     
endmodule //fetcher