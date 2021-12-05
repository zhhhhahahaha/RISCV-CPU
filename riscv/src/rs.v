`include "config.v"

module rs (
    input clk,
    input rst,
    input rdy,
    input has_misbranch,
 
    //from issue
    input has_issue,
    input [`Data_Len] in_imm,
    input [5:0] in_op,
    input [`Addr_Len] in_pc,
    input [`Shamt_Len] in_shamt,
    input [`Rob_Addr_Len] in_rs_rd_robnum,
    input [`Data_Len] in_rs1_oprand,
    input [`Data_Len] in_rs2_oprand,
    input [`Rob_Addr_Len] in_rs1_robnum,
    input [`Rob_Addr_Len] in_rs2_robnum,
    input in_rs1_ready,
    input in_rs2_ready,

    //to issue
    output rs_avail,

    //to alu
    output reg has_to_alu,
    output reg [`Data_Len] out_imm,
    output reg [5:0] out_op,
    output reg [`Addr_Len] out_pc,
    output reg [`Shamt_Len] out_shamt,
    output reg [`Rob_Addr_Len] out_rs_rd_robnum,
    output reg [`Data_Len] out_rs1_oprand,
    output reg [`Data_Len] out_rs2_oprand,
    
    //from rob
    input has_rd_ready_1,
    input [`Rob_Addr_Len] ready_robnum_1,
    input [`Data_Len] ready_data_1,
    input has_rd_ready_2,
    input [`Rob_Addr_Len] ready_robnum_2,
    input [`Data_Len] ready_data_2



    
);
    reg [`Rob_Addr_Len] rs1_robnum [`Rs_Size];
    reg [`Rob_Addr_Len] rs2_robnum [`Rs_Size];
    reg [`Data_Len] rs1_oprand [`Rs_Size];
    reg [`Data_Len] rs2_oprand [`Rs_Size];
    reg [`Data_Len] imm [`Rs_Size];
    reg [5:0] op [`Rs_Size];
    reg [`Addr_Len] pc [`Rs_Size];
    reg [`Shamt_Len] shamt [`Rs_Size];
    reg [`Rob_Addr_Len] rs_rd_robnum [`Rs_Size];
    reg busy [`Rs_Size];
    reg ready_to_alu [`Rs_Size];
    reg rs1_ready [`Rs_Size];
    reg rs2_ready [`Rs_Size];
    
    integer i;
    wire rs_avail_num;
    wire avail_to_alu_num;
    wire rs_ready_to_alu;


    assign rs_avail = !(busy[0]&&busy[1]&&busy[2]&&busy[3]&&busy[4]&&busy[5]&&
                      busy[6]&&busy[7]&&busy[8]&&busy[9]&&busy[10]&&busy[11]&&
                      busy[12]&&busy[13]&&busy[14]&&busy[15]);
    assign rs_ready_to_alu = ready_to_alu[0]||ready_to_alu[1]||ready_to_alu[2]||ready_to_alu[3]||
                             ready_to_alu[4]||ready_to_alu[5]||ready_to_alu[6]||ready_to_alu[7]||
                             ready_to_alu[8]||ready_to_alu[9]||ready_to_alu[10]||ready_to_alu[11]||
                             ready_to_alu[12]||ready_to_alu[13]||ready_to_alu[14]||ready_to_alu[15];
    always @(posedge clk) begin
        if(rst||has_misbranch) begin
            has_to_alu <= `False;
            for (i = 0; i<=15; i=i+1) begin
                rs1_robnum[i] <= 4'd0;
                rs2_robnum[i] <= 4'd0;
                rs1_oprand[i] <= `Zero_Data;
                rs2_oprand[i] <= `Zero_Data;
                imm[i] <= `Zero_Data;
                op[i] <= 6'd0;
                pc[i] <= `Zero_Addr;
                shamt[i] <= 6'd0;
                rs_rd_robnum[i] <= 4'd0;
                busy[i] <= `False;
                ready_to_alu[i] <= `False;
                rs1_ready[i] <= `False;
                rs2_ready[i] <= `False;
            end
        end
        else if(rdy) begin
            has_to_alu <= `False;
            if(has_issue) begin
                imm[rs_avail_num] <= in_imm;
                op[rs_avail_num] <= in_op;
                pc[rs_avail_num] <= in_pc;
                shamt[rs_avail_num] <= in_shamt;
                rs_rd_robnum[rs_avail_num] <= in_rs_rd_robnum;
                rs1_oprand[rs_avail_num] <= in_rs1_oprand;
                rs2_oprand[rs_avail_num] <= in_rs2_oprand;
                rs1_robnum[rs_avail_num] <= in_rs1_robnum;
                rs2_robnum[rs_avail_num] <= in_rs2_robnum;
                rs1_ready[rs_avail_num] <= in_rs1_ready;
                rs2_ready[rs_avail_num] <= in_rs2_ready;
                ready_to_alu[rs_avail_num] <= in_rs1_ready && in_rs2_ready;
                busy[rs_avail_num] <= `True;
            end
            if(rs_ready_to_alu) begin
                has_to_alu <= `True;
                out_imm <= imm[avail_to_alu_num];
                out_op <= op[avail_to_alu_num];
                out_pc <= pc[avail_to_alu_num];
                out_shamt <= shamt[avail_to_alu_num];
                out_rs_rd_robnum <= shamt[avail_to_alu_num];
                out_rs1_oprand <= rs1_oprand[avail_to_alu_num];
                out_rs2_oprand <= rs2_oprand[avail_to_alu_num];
                busy[avail_to_alu_num] <= `False;
                ready_to_alu[avail_to_alu_num] <= `False;
            end
            if(has_rd_ready_1||has_rd_ready_2) begin
                for(i = 0; i <= 15;i = i + 1) begin
                    if(busy[i]==`True) begin
                        if(has_rd_ready_1 && rs1_ready[i]==`False && rs1_robnum[i]==ready_robnum_1) begin
                            rs1_ready[i] <= `True;
                            rs1_oprand[i] <= ready_data_1;
                        end
                        if(has_rd_ready_2 && rs1_ready[i]==`False && rs1_robnum[i]==ready_robnum_2) begin
                            rs1_ready[i] <= `True;
                            rs1_oprand[i] <= ready_data_2;
                        end
                        if(has_rd_ready_1 && rs2_ready[i]==`False && rs2_robnum[i]==ready_robnum_1) begin
                            rs2_ready[i] <= `True;
                            rs2_oprand[i] <= ready_data_1;
                        end
                        if(has_rd_ready_2 && rs2_ready[i]==`False && rs2_robnum[i]==ready_robnum_2) begin
                            rs2_ready[i] <= `True;
                            rs2_oprand[i] <= ready_data_2;
                        end
                        ready_to_alu[i] <= rs1_ready[i] && rs2_ready[i];
                    end
                end
            end
        end
    end
    
    assign rs_avail_num = (!busy[0]) ? 0 :
                          (!busy[1]) ? 1 :
                          (!busy[2]) ? 2 :
                          (!busy[3]) ? 3 :
                          (!busy[4]) ? 4 :
                          (!busy[5]) ? 5 :
                          (!busy[6]) ? 6 :
                          (!busy[7]) ? 7 :
                          (!busy[8]) ? 8 :
                          (!busy[9]) ? 9 :
                          (!busy[10]) ? 10 :
                          (!busy[11]) ? 11 :
                          (!busy[12]) ? 12 :
                          (!busy[13]) ? 13 :
                          (!busy[14]) ? 14 :
                          (!busy[15]) ? 15 : 0;
    assign rs_avail = !(busy[0]&&busy[1]&&busy[2]&&busy[3]&&busy[4]&&busy[5]&&
                    busy[6]&&busy[7]&&busy[8]&&busy[9]&&busy[10]&&busy[11]&&
                    busy[12]&&busy[13]&&busy[14]&&busy[15]); 
    assign avail_to_alu_num = ready_to_alu[0] ? 0 :
                              ready_to_alu[1] ? 1 :
                              ready_to_alu[2] ? 2 :
                              ready_to_alu[3] ? 3 :
                              ready_to_alu[4] ? 4 :
                              ready_to_alu[5] ? 5 :
                              ready_to_alu[6] ? 6 :
                              ready_to_alu[7] ? 7 :
                              ready_to_alu[8] ? 8 :
                              ready_to_alu[9] ? 9 :
                              ready_to_alu[10] ? 10 :
                              ready_to_alu[11] ? 11 :
                              ready_to_alu[12] ? 12 :
                              ready_to_alu[13] ? 13 :
                              ready_to_alu[14] ? 14 :
                              ready_to_alu[15] ? 15 : 0;

    

endmodule //rs