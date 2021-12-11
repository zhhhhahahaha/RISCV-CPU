`include "config.v"

module alu (
    input clk,
    input rst,
    input rdy,
    input has_misbranch,

    //from rs
    input has_to_alu,
    input [`Data_Len]imm,
    input [5:0] op,
    input [`Addr_Len] pc,
    input [`Shamt_Len] shamt,
    input [`Rob_Addr_Len] in_rd_robnum,
    input [`Data_Len] rs1_oprand,
    input [`Data_Len] rs2_oprand,

    //to rob
    output reg has_to_rob,
    output reg [`Rob_Addr_Len] out_rd_robnum,
    output reg [`Data_Len] out_rd_data,
    output reg need_jump,
    output reg [`Addr_Len] true_pc

);
    always @(posedge clk) begin
        if(rst) begin
            has_to_rob <= `False;
        end
        else if (has_misbranch) begin
            has_to_rob <= `False;
        end
        if(rdy) begin
            has_to_rob <= `False;
            if(has_to_alu)begin
                out_rd_robnum <= in_rd_robnum;
                has_to_rob <= `True;
                case (op)
                    `op_lui : begin
                        out_rd_data <= imm;
                    end
                    `op_auipc : begin
                        out_rd_data <= pc + imm;
                    end
                    `op_jal : begin
                        out_rd_data <= pc + 4;
                    end
                    `op_jalr : begin
                        out_rd_data <= pc + 4;
                        need_jump <= `True;
                        true_pc <= (rs1_oprand + imm)&~1;
                    end
                    `op_beq : begin
                        if(rs1_oprand==rs2_oprand)begin
                            need_jump <= `True;
                            true_pc <= pc + imm;
                        end
                        else begin
                            need_jump <= `False;
                            true_pc <= pc + 4;
                        end
                    end
                    `op_bne : begin
                        if(rs1_oprand!=rs2_oprand)begin
                            need_jump <= `True;
                            true_pc <= pc + imm;
                        end
                        else begin
                            need_jump <= `False;
                            true_pc <= pc + 4;
                        end
                    end
                    `op_blt : begin
                        if($signed(rs1_oprand)<$signed(rs2_oprand))begin
                            need_jump <= `True;
                            true_pc <= pc + imm;
                        end
                        else begin
                            need_jump <= `False;
                            true_pc <= pc + 4;
                        end
                    end
                    `op_bge : begin
                        if($signed(rs1_oprand)>=$signed(rs2_oprand))begin
                            need_jump <= `True;
                            true_pc <= pc + imm;
                        end
                        else begin
                            need_jump <= `False;
                            true_pc <= pc + 4;
                        end
                    end
                    `op_bltu : begin
                        if(rs1_oprand<rs2_oprand) begin
                            need_jump <= `True;
                            true_pc <= pc + imm;
                        end
                        else begin
                            need_jump <= `False;
                            true_pc <= pc + 4;
                        end
                    end
                    `op_bgeu : begin
                        if(rs1_oprand>=rs2_oprand) begin
                            need_jump <= `True;
                            true_pc <= pc + imm;
                        end
                        else begin
                            need_jump <= `False;
                            true_pc <= pc + 4;
                        end
                    end
                    `op_addi : begin
                        out_rd_data <= rs1_oprand + imm;
                    end
                    `op_slti : begin
                        out_rd_data <= ($signed(rs1_oprand)<$signed(imm)) ? 32'd1 : `Zero_Data;
                    end
                    `op_sltiu : begin
                        out_rd_data <= (rs1_oprand<imm)? 32'd1 : `Zero_Data;
                    end
                    `op_xori : begin
                        out_rd_data <= rs1_oprand ^ imm;
                    end
                    `op_ori : begin
                        out_rd_data <= rs1_oprand | imm;
                    end
                    `op_andi : begin
                        out_rd_data <= rs1_oprand & imm;
                    end
                    `op_slli : begin
                        out_rd_data <= rs1_oprand << shamt;
                    end
                    `op_srli : begin
                        out_rd_data <= rs1_oprand >> shamt;
                    end
                    `op_srai : begin
                        out_rd_data <= (rs1_oprand >> shamt) | ({32{rs1_oprand[31]}} << (6'd32 - {1'b0,shamt}));
                    end
                    `op_add : begin
                        out_rd_data <= rs1_oprand + rs2_oprand;
                    end
                    `op_sub : begin
                        out_rd_data <= rs1_oprand - rs2_oprand;
                    end
                    `op_sll : begin
                        out_rd_data <= rs1_oprand << rs2_oprand[4:0];
                    end
                    `op_slt : begin
                        out_rd_data <= ($signed(rs1_oprand)<$signed(rs2_oprand)) ? 32'd1 : `Zero_Data;
                    end
                    `op_sltu : begin
                        out_rd_data <= (rs1_oprand<rs2_oprand) ? 32'd1 : `Zero_Data;
                    end
                    `op_xor : begin
                        out_rd_data <= rs1_oprand ^ rs2_oprand;
                    end
                    `op_srl : begin
                        out_rd_data <= rs1_oprand >> rs2_oprand[4:0];
                    end
                    `op_sra : begin
                        out_rd_data <= (rs1_oprand >> rs2_oprand[4:0]) | ({32{rs1_oprand[31]}} << (6'd32 - {1'b0, rs2_oprand[4:0]}));
                    end
                    `op_or : begin
                        out_rd_data <= rs1_oprand | rs2_oprand;
                    end
                    `op_and : begin
                        out_rd_data <= rs1_oprand & rs2_oprand;
                    end
                endcase
            end
        end
    end

endmodule //alu