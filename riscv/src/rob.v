`include "config.v"

module rob (
    input clk,
    input rst,
    input rdy,

    output reg has_misbranch,

    //from issue
    input [1:0] inst_type,
    input [`Reg_Addr_Len] dest,
    input [`Rob_Addr_Len] rs1_rob_num,
    input [`Rob_Addr_Len] rs2_rob_num,
    input hasissued,
    input in_has_jump,

    //to issue
    output rob_avail,
    output [`Rob_Addr_Len] rob_avail_num,
    output rs1_ready,
    output rs2_ready,
    output [`Data_Len] rs1_data,
    output [`Data_Len] rs2_data,

    //from alu
    input has_from_alu,
    input [`Rob_Addr_Len] in_alu_rd_robnum,
    input [`Data_Len] in_alu_rd_data,
    input in_need_jump,
    input [`Addr_Len] in_true_pc,

    //data to rs and slbuffer
    output reg has_rd_ready_1,
    output reg[`Rob_Addr_Len] ready_robnum_1,
    output reg[`Data_Len] ready_data_1,
    output reg has_rd_ready_2,
    output reg[`Rob_Addr_Len] ready_robnum_2,
    output reg[`Data_Len] ready_data_2,

    //from slbuffer
    input has_from_slb,
    input [`Rob_Addr_Len] in_slb_rd_robnum,
    input [`Data_Len] in_slb_rd_data,

    //to slbuffer
    output can_store,

    //to register files
    output reg has_to_reg,
    output reg[`Reg_Addr_Len] dest_reg_num,
    output reg[`Data_Len] out_reg_data,
    output reg[`Rob_Addr_Len] out_reg_rob_num,

    //to pc_reg
    output reg [`Addr_Len] out_true_pc



);
    
    reg [`Rob_Addr_Len] head, tail;
    wire full;
    reg [1:0] inst_type_field [`Rob_Size];
    reg [`Reg_Addr_Len] dest_field [`Rob_Size];
    reg [`Data_Len] value_field [`Rob_Size];
    reg ready_field [`Rob_Size];
    reg has_jump [`Rob_Size];
    reg need_jump [`Rob_Size];
    reg [`Addr_Len] true_pc [`Rob_Size];
    integer file;
    initial begin
        file = $fopen("a.out", "w");
    end

    assign full = hasissued? head==tail+2 || (tail==4'd14&&head==4'd0) || (tail==4'd15&&head==4'd1) : head == tail+1 || (tail==4'd15&&head==4'd0); //only 15 entries can be used 

    //to slbuffer
    assign can_store = (inst_type_field[head]==`Store_Type)? `True : `False; 
    
    //to issue
    assign rob_avail = !full;
    assign rob_avail_num = hasissued ? tail+1 : tail;
    assign rs1_ready = ready_field[rs1_rob_num];
    assign rs2_ready = ready_field[rs2_rob_num];
    assign rs1_data = value_field[rs1_rob_num];
    assign rs2_data = value_field[rs2_rob_num];
    
    
    always @(posedge clk) begin
        if (rst) begin
            head <= 4'd0;
            tail <= 4'd0;
            has_rd_ready_1 <= `False;
            has_rd_ready_2 <= `False;
            has_to_reg <= `False;
            has_misbranch <= `False;
        end
        else if(rdy) begin
            has_rd_ready_1 <= `False;
            has_rd_ready_2 <= `False;
            has_to_reg <= `False;
            has_misbranch <= `False;
            if (hasissued && !has_misbranch) begin
                inst_type_field[tail] <= inst_type;
                dest_field[tail] <= dest;
                ready_field[tail] <= `False;
                has_jump[tail] <= in_has_jump;
                need_jump[tail] <= `False;
                true_pc[tail] <= `Zero_Reg_Addr;
                tail <= tail + 1;
                //$write("%d", tail);          
            end
            if (has_from_alu) begin
                ready_field[in_alu_rd_robnum] <= `True;
                case (inst_type_field[in_alu_rd_robnum])
                    `Branch_Type : begin
                        need_jump[in_alu_rd_robnum] <= in_need_jump;
                        true_pc[in_alu_rd_robnum] <= in_true_pc;
                    end
                    `Other_Type : begin
                        value_field[in_alu_rd_robnum] <= in_alu_rd_data;
                        has_rd_ready_1 <= `True;
                        ready_robnum_1 <= in_alu_rd_robnum;
                        ready_data_1 <= in_alu_rd_data;
                    end
                    `Jalr_Type : begin
                        value_field[in_alu_rd_robnum] <= in_alu_rd_data;
                        need_jump[in_alu_rd_robnum] <= in_need_jump;
                        true_pc[in_alu_rd_robnum] <= in_true_pc;
                        has_rd_ready_1 <= `True;
                        ready_robnum_1 <= in_alu_rd_robnum;
                        ready_data_1 <= in_alu_rd_data;
                    end
                endcase
            end
            if (has_from_slb) begin
                case (inst_type_field[in_slb_rd_robnum])
                    `Other_Type: begin
                        value_field[in_slb_rd_robnum] <= in_slb_rd_data;
                        has_rd_ready_2 <= `True;
                        ready_robnum_2 <= in_slb_rd_robnum;
                        ready_data_2 <= in_slb_rd_data;
                        ready_field[in_slb_rd_robnum] <= `True;
                    end
                    `Store_Type: begin
                        ready_field[in_slb_rd_robnum] <= `True;
                    end
                endcase 
            end
            //$write("%d", tail);
            //$display("%d",head);
            if(head!=tail && ready_field[head]) begin
                case (inst_type_field[head])
                    `Other_Type : begin
                        has_to_reg <= `True; 
                        dest_reg_num <= dest_field[head];
                        out_reg_data <= value_field[head];
                        out_reg_rob_num <= head;
                        head <= head + 1;
                    end
                    `Store_Type : begin
                        head <= head + 1;
                    end
                    `Branch_Type : begin
                        if(head+1!=tail && !(head==4'd15&&tail==4'd0))begin
                            head <= head + 1;
                            /*$fwrite(file, $time);
                            $fwrite(file, "  ");
                            $fwrite(file, "%d", head);
                            $fwrite(file, "  ");
                            $fwrite(file, "%d", head+1);
                            $fwrite(file, "  ");
                            $fwrite(file, "%d", has_jump[head+1]);
                            $fwrite(file, "  ");
                            $fdisplay(file, "%d",need_jump[head]);*/
                            if(head!=4'd15)begin
                                if(has_jump[head+1]!=need_jump[head])begin
                                    tail <= head + 1;
                                    has_misbranch <= `True;
                                    out_true_pc <= true_pc[head];
                                end
                            end
                            else begin
                                if(has_jump[0]!=need_jump[head])begin
                                    tail <= head + 1;
                                    has_misbranch <= `True;
                                    out_true_pc <= true_pc[head];
                                end
                            end
                        end    
                    end
                    `Jalr_Type : begin
                        has_to_reg <= `True;
                        dest_reg_num <= dest_field[head];
                        out_reg_data <= value_field[head];
                        out_reg_rob_num <= head;
                        head <= head + 1;
                        tail <= head + 1;
                        has_misbranch <= `True;
                        out_true_pc <= true_pc[head];
                    end
                endcase
            end
        end           
    end




endmodule //rob