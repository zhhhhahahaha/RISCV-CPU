`include "config.v"
//must be careful about the things related to inst

//need to update in every instru
//inst_type
//issue_rs
//rs_imm
//rs_op
//shamt
//issue_slb
//slb_imm
//slb_op
//rs1_addr
//rs2_addr
//needsetbusy
//inst_need_rs1
//inst_need_rs2

module issue (
    input clk,
    input rst,
    input rdy,
    input has_misbranch,
    
    //from fetcher
    input [`Inst_Len] inst,
    input [`Addr_Len] pc,
    input can_issue,
    input in_has_jump,

    //from ROB
    input rob_avail,
    input [`Rob_Addr_Len] rob_avail_num,
    input rob_rs1_ready,
    input rob_rs2_ready,
    input [`Data_Len] rob_rs1_data,//if not ready, the data is unknown
    input [`Data_Len] rob_rs2_data,//if not ready, the data is unknown

    //to ROB
    output reg issue_rob,
    output reg[1:0] inst_type,
    output reg[`Reg_Addr_Len] dest,
    output reg out_has_jump,
    output reg [`Addr_Len] out_pc,
    output [`Rob_Addr_Len] out_rs1_rob_num,
    output [`Rob_Addr_Len] out_rs2_rob_num,

    //from RS
    input rs_avail,

    //to RS
    output reg issue_rs,
    output reg [`Data_Len] rs_imm,
    output reg [5:0] rs_op,
    output reg [`Addr_Len] rs_pc,
    output reg [`Shamt_Len] shamt,
    output reg [`Rob_Addr_Len] rs_rd_robnum,
    output [`Data_Len] rs_rs1_oprand,//if do not need rs1, data is unknown
    output [`Data_Len] rs_rs2_oprand,//if do not need rs2, data is unknown
    output [`Rob_Addr_Len] rs_rs1_robnum,
    output [`Rob_Addr_Len] rs_rs2_robnum,
    output rs_rs1_ready,
    output rs_rs2_ready,

    //to SLBuffer
    output reg issue_slb,
    output reg [`Data_Len] slb_imm,
    output reg [5:0] slb_op,
    output reg [`Rob_Addr_Len] slb_rd_robnum,
    output [`Data_Len] slb_rs1_oprand,
    output [`Data_Len] slb_rs2_oprand,
    output [`Rob_Addr_Len] slb_rs1_robnum,
    output [`Rob_Addr_Len] slb_rs2_robnum,
    output slb_rs1_ready,
    output slb_rs2_ready,

    //from registerfile
    input [`Data_Len] rs1_data,
    input [`Data_Len] rs2_data,
    input rs1_busy,
    input rs2_busy,
    input [`Rob_Addr_Len] in_rs1_rob_num,
    input [`Rob_Addr_Len] in_rs2_rob_num,

    //to registerfile
    output reg[`Reg_Addr_Len] rs1_addr,
    output reg[`Reg_Addr_Len] rs2_addr,
    output reg needsetbusy,
    output reg [`Reg_Addr_Len] rd_addr,
    output reg [`Rob_Addr_Len] rd_rob_num 
);
    reg inst_need_rs1;
    reg inst_need_rs2;

    //immediate
    wire [`Data_Len] I_Imm, S_Imm, B_Imm, U_Imm, J_Imm; 
    assign I_Imm = {{21{inst[31]}}, inst[30:20]};
    assign S_Imm = {{21{inst[31]}}, inst[30:25], inst[11:7]};
    assign B_Imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    assign U_Imm = {inst[31:12], 12'b0};
    assign J_Imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:25], inst[24:21], 1'b0};
    
    //to ROB
    assign out_rs1_rob_num = in_rs1_rob_num;
    assign out_rs2_rob_num = in_rs2_rob_num;

    //to RS
    assign rs_rs1_oprand = (!rs1_busy) ? rs1_data :
                            rob_rs1_ready ? rob_rs1_data :
                            `Zero_Data;
    assign rs_rs2_oprand = (!rs2_busy) ? rs2_data :
                            rob_rs2_ready ? rob_rs2_data :
                            `Zero_Data;
    assign rs_rs1_robnum = in_rs1_rob_num;
    assign rs_rs2_robnum = in_rs2_rob_num;
    assign rs_rs1_ready = (!inst_need_rs1) ? `True :
                          (!rs1_busy) ? `True :
                          rob_rs1_ready ? `True :
                          `False;
    assign rs_rs2_ready = (!inst_need_rs2) ? `True :
                          (!rs2_busy) ? `True :
                          rob_rs2_ready ? `True :
                          `False; 
    assign slb_rs1_oprand = rs_rs1_oprand;
    assign slb_rs2_oprand = rs_rs2_oprand;
    assign slb_rs1_robnum = rs_rs1_robnum;
    assign slb_rs2_robnum = rs_rs2_robnum;
    assign slb_rs1_ready = rs_rs1_ready;
    assign slb_rs2_ready = rs_rs2_ready;

    always @(posedge clk) begin
        if(rst) begin
            issue_rob <= `False;
            issue_rs <= `False;
            issue_slb <= `False;
            needsetbusy <= `False;
            inst_need_rs1 <= `False;
            inst_need_rs2 <= `False;
        end
        else if (has_misbranch) begin
            issue_rob <= `False;
            issue_rs <= `False;
            issue_slb <= `False;
            needsetbusy <= `False;
            inst_need_rs1 <= `False;
            inst_need_rs2 <= `False;
        end
        else if(rdy) begin
            issue_rob <= `False;
            issue_rs <= `False;
            needsetbusy <= `False;
            issue_slb <= `False;
            if(can_issue) begin
                dest <= inst[11:7];
                rd_addr <= inst[11:7];
                rd_rob_num <= rob_avail_num;
                rs_rd_robnum <= rob_avail_num;
                slb_rd_robnum <= rob_avail_num;
                rs_pc <= pc;
                out_has_jump <= in_has_jump;
                out_pc <= pc;
                        
                issue_rob <= `True;
                issue_rs <= `False;
                needsetbusy <= `False;
                issue_slb <= `False;
                case (inst[6:0])
                    `Lui: begin 
                        inst_type <= `Other_Type;
                        issue_rs <= `True;
                        rs_imm <= U_Imm;
                        rs_op <= `op_lui;
                        rs1_addr <= `Zero_Reg_Addr;
                        rs2_addr <= `Zero_Reg_Addr;
                        needsetbusy <= `True;
                        inst_need_rs1 <= `False;
                        inst_need_rs2 <= `False;                   
                    end
                    `Auipc: begin
                        inst_type <= `Other_Type;
                        issue_rs <= `True;
                        rs_imm <= U_Imm;
                        rs_op <= `op_auipc;
                        rs1_addr <= `Zero_Reg_Addr;
                        rs2_addr <= `Zero_Reg_Addr;
                        needsetbusy <= `True;
                        inst_need_rs1 <= `False;
                        inst_need_rs2 <= `False;  
                    end
                    `Jal: begin   //need to be finished
                        issue_rob <= `True;
                        inst_type <= `Other_Type;
                        issue_rs <= `True;
                        rs_imm <= J_Imm;
                        rs_op <= `op_jal;
                        rs1_addr <= `Zero_Reg_Addr;
                        rs2_addr <= `Zero_Reg_Addr;
                        needsetbusy <= `True;
                        inst_need_rs1 <= `False;
                        inst_need_rs2 <= `False; 
                    end
                    `Jalr: begin  //need to be finished
                        inst_type <= `Jalr_Type;
                        issue_rs <= `True;
                        rs_imm <= I_Imm;
                        rs_op <= `op_jalr;
                        rs1_addr <= inst[19:15];
                        rs2_addr <= `Zero_Reg_Addr;
                        needsetbusy <= `True;
                        inst_need_rs1 <= `True;
                        inst_need_rs2 <= `False;
                    end
                    `B_Type: begin
                        inst_type <= `Branch_Type;
                        issue_rs <= `True;
                        rs_imm <= B_Imm;
                        case (inst[14:12]) 
                            `beq : begin
                                rs_op <= `op_beq;
                            end
                            `bne : begin
                                rs_op <= `op_bne;
                            end
                            `blt : begin
                                rs_op <= `op_blt;
                            end
                            `bge : begin
                                rs_op <= `op_bge;
                            end
                            `bltu : begin
                                rs_op <= `op_bltu;
                            end
                            `bgeu : begin
                                rs_op <= `op_bgeu;
                            end
                        endcase
                        rs1_addr <= inst[19:15];
                        rs2_addr <= inst[24:20];
                        needsetbusy <= `False;
                        inst_need_rs1 <= `True;
                        inst_need_rs2 <= `True; 
                    end
                    `L_Type: begin
                        inst_type <= `Other_Type;
                        issue_slb <= `True;
                        slb_imm <= I_Imm;
                        case (inst[14:12])
                            `lb : begin
                                slb_op <= `op_lb;
                            end
                            `lh : begin
                                slb_op <= `op_lh;
                            end
                            `lw : begin
                                slb_op <= `op_lw;
                            end
                            `lbu : begin
                                slb_op <= `op_lbu;
                            end
                            `lhu : begin
                                slb_op <= `op_lhu;
                            end
                        endcase
                        rs1_addr <= inst[19:15];
                        rs2_addr <= `Zero_Reg_Addr;
                        needsetbusy <= `True;
                        inst_need_rs1 <= `True;
                        inst_need_rs2 <= `False;       
                    end
                    `S_Type: begin
                        inst_type <= `Store_Type;
                        issue_slb <= `True;
                        slb_imm <= S_Imm;
                        case (inst[14:12])
                            `sb : begin
                                slb_op <= `op_sb;
                            end
                            `sh : begin
                                slb_op <= `op_sh;
                            end
                            `sw : begin
                                slb_op <= `op_sw;
                            end
                        endcase
                        rs1_addr <= inst[19:15];
                        rs2_addr <= inst[24:20];
                        needsetbusy <= `False;
                        inst_need_rs1 <= `True;
                        inst_need_rs2 <= `True;
                    end
                    `OtherI: begin
                        inst_type <= `Other_Type;
                        issue_rs <= `True;
                        rs_imm <= I_Imm;
                        case (inst[14:12])
                            `addi : begin
                                rs_op <= `op_addi;
                            end
                            `slti : begin
                                rs_op <= `op_slti;
                            end
                            `sltiu : begin
                                rs_op <= `op_sltiu;
                            end
                            `xori : begin
                                rs_op <= `op_xori;
                            end
                            `ori : begin
                                rs_op <= `op_ori;
                            end
                            `andi : begin
                                rs_op <= `op_andi;
                            end
                            `slli : begin
                                rs_op <= `op_slli;
                                shamt <= inst[24:20];
                            end
                            `sr : begin
                                case (inst[31:25])
                                    `srli : begin
                                        rs_op <= `op_srli;
                                        shamt <= inst[24:20];
                                    end
                                    `srai : begin
                                        rs_op <= `op_srai;
                                        shamt <= inst[24:20];
                                    end
                                endcase
                            end
                        endcase
                        rs1_addr <= inst[19:15];
                        rs2_addr <= `Zero_Reg_Addr;
                        needsetbusy <= `True;
                        inst_need_rs1 <= `True;
                        inst_need_rs2 <= `False; 
                    end
                    `Other: begin
                        inst_type <= `Other_Type;
                        issue_rs <= `True;
                        case (inst[14:12])
                            `add_sub : begin
                                case (inst[31:25])
                                    `add : begin
                                        rs_op <= `op_add;
                                    end
                                    `sub : begin
                                        rs_op <= `op_sub;
                                    end
                                endcase
                            end
                            `sll : begin
                                rs_op <= `op_sll;
                            end
                            `slt : begin
                                rs_op <= `op_slt;
                            end
                            `sltu : begin
                                rs_op <= `op_sltu;
                            end
                            `XOR : begin
                                rs_op <= `op_xor;
                            end
                            `srl_a : begin
                                case (inst[31:25])
                                    `srl : begin
                                        rs_op <= `op_srl;
                                    end
                                    `sra : begin
                                        rs_op <= `op_sra;
                                    end
                                endcase
                            end
                            `OR : begin
                                rs_op <= `op_or;
                            end
                            `AND : begin
                                rs_op <= `op_and;
                            end
                        endcase
                        rs1_addr <= inst[19:15];
                        rs2_addr <= inst[24:20];
                        needsetbusy <= `True;
                        inst_need_rs1 <= `True;
                        inst_need_rs2 <= `True;
                    end
                endcase
            end
        end
    end



endmodule 