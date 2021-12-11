`include "config.v"

module slbuffer (
    input clk,
    input rst,
    input rdy,
    input has_misbranch,

    //from issue
    input has_issue,
    input [`Data_Len] in_imm,
    input [5:0] in_op,
    input [`Rob_Addr_Len] in_rd_robnum,
    input [`Data_Len] in_rs1_oprand,
    input [`Data_Len] in_rs2_oprand,
    input [`Rob_Addr_Len] in_rs1_robnum,
    input [`Rob_Addr_Len] in_rs2_robnum,
    input in_rs1_ready,
    input in_rs2_ready,

    //to issue
    output slb_avail,

    //from ask_memory
    input in_mem_ready, //ask_memory get the data or write has finished
    input [`Data_Len] in_mem_data, 

    //to ask_memory
    output reg read_mem,
    output reg write_mem,
    output reg[`Addr_Len] mem_addr,
    output reg[2:0] Byte_num,
    output reg [`Data_Len] write_data,

    //from rob
    input can_store,

    input has_rd_ready_1,
    input [`Rob_Addr_Len] ready_robnum_1,
    input [`Data_Len] ready_data_1,
    input has_rd_ready_2,
    input [`Rob_Addr_Len] ready_robnum_2,
    input [`Data_Len] ready_data_2,

    //to rob
    output reg has_to_rob,
    output reg [`Rob_Addr_Len] out_rd_robnum,
    output reg [`Data_Len] out_rd_data
    
);
    reg [`Slb_Addr_Len] head,tail;
    wire full;
    reg [`Data_Len] imm[`Slb_Size];
    reg [5:0] op[`Slb_Size];
    reg [`Rob_Addr_Len] rd_robnum[`Slb_Size];
    reg [`Data_Len] rs1_oprand[`Slb_Size];
    reg [`Data_Len] rs2_oprand[`Slb_Size];
    reg [`Rob_Addr_Len] rs1_robnum[`Slb_Size];
    reg [`Rob_Addr_Len] rs2_robnum[`Slb_Size];
    reg rs1_ready[`Slb_Size];
    reg rs2_ready[`Slb_Size];
    reg is_waiting;
    integer i;

    assign full = has_issue? head==tail+2 || (tail==4'd14&&head==4'd0) || (tail==4'd15&&head==4'd1) : head == tail+1 || (tail==4'd15&&head==4'd0); //only 15 entries can be used

    assign slb_avail = !full;

    always @(posedge clk) begin
        if(rst) begin
            head <= 4'd0;
            tail <= 4'd0;
            is_waiting <= `False;
            read_mem <= `False;
            write_mem <= `False;
            has_to_rob <= `False;
        end
        else if (has_misbranch) begin
            head <= 4'd0;
            tail <= 4'd0;
            is_waiting <= `False;
            read_mem <= `False;
            write_mem <= `False;
            has_to_rob <= `False;
        end
        else if(rdy) begin
            read_mem <= `False;
            write_mem <= `False;
            has_to_rob <= `False;
            if(has_issue) begin
                imm[tail] <= in_imm;
                op[tail] <= in_op;
                rd_robnum[tail] <= in_rd_robnum;
                rs1_oprand[tail] <= in_rs1_oprand;
                rs2_oprand[tail] <= in_rs2_oprand;
                rs1_robnum[tail] <= in_rs1_robnum;
                rs2_robnum[tail] <= in_rs2_robnum;
                rs1_ready[tail] <= in_rs1_ready;
                rs2_ready[tail] <= in_rs2_ready;
                tail <= tail + 1;
            end
            if(!is_waiting) begin
                if(head!=tail && rs1_ready[head] && rs2_ready[head]) begin
                    is_waiting <= `True;
                    case(op[head])
                    `op_lb: begin
                        read_mem <= `True;
                        mem_addr <= rs1_oprand[head] + imm[head];
                        Byte_num <= 3'd1;                 
                    end
                    `op_lh: begin
                        read_mem <= `True;
                        mem_addr <= rs1_oprand[head] + imm[head];
                        Byte_num <= 3'd2;
                    end
                    `op_lw: begin
                        read_mem <= `True;
                        mem_addr <= rs1_oprand[head] + imm[head];
                        Byte_num <= 3'd4;
                    end
                    `op_lbu: begin
                        read_mem <= `True;
                        mem_addr <= rs1_oprand[head] + imm[head];
                        Byte_num <= 3'd1;
                    end
                    `op_lhu: begin
                        read_mem <= `True;
                        mem_addr <= rs1_oprand[head] + imm[head];
                        Byte_num <= 3'd2;
                    end
                    `op_sb: begin
                        if(can_store) begin    
                            write_mem <= `True;
                            mem_addr <= rs1_oprand[head] + imm[head];
                            Byte_num <= 3'd1;
                            write_data <= {24'd0,rs2_oprand[head][7:0]};
                        end
                        else begin
                            is_waiting <= `False;
                        end
                    end
                    `op_sh: begin
                        if(can_store) begin
                            write_mem <= `True;
                            mem_addr <= rs1_oprand[head] + imm[head];
                            Byte_num <= 3'd2;
                            write_data <= {16'd0,rs2_oprand[head][15:0]};
                        end
                        else begin
                            is_waiting <= `False;
                        end
                    end
                    `op_sw: begin
                        if(can_store) begin
                            write_mem <= `True;
                            mem_addr <= rs1_oprand[head] + imm[head];
                            Byte_num <= 3'd4;
                            write_data <= rs2_oprand[head];
                        end
                        else begin
                            is_waiting <= `False;
                        end
                    end
                    endcase
                end  
            end
            if(in_mem_ready)begin
                is_waiting <= `False;
                has_to_rob <= `True;
                out_rd_robnum <= rd_robnum[head];
                head <= head + 1;
                case(op[head])
                    `op_lb: begin
                        out_rd_data <= in_mem_data;
                    end
                    `op_lh: begin
                        out_rd_data <= in_mem_data;
                    end
                    `op_lw: begin
                        out_rd_data <= in_mem_data;
                    end
                    `op_lbu: begin
                        out_rd_data <= {24{in_mem_data[7],in_mem_data[7:0]}};
                    end
                    `op_lhu: begin
                        out_rd_data <= {16{in_mem_data[15],in_mem_data[15:0]}};
                    end
                endcase
                /*if(head+1!=tail && rs1_ready[head+1] && rs2_ready[head+1]) begin
                    is_waiting <= `True;
                    case(op[head+1])
                    `op_lb: begin
                        read_mem <= `True;
                        mem_addr <= rs1_oprand[head+1] + imm[head+1];
                        Byte_num <= 3'd1;                 
                    end
                    `op_lh: begin
                        read_mem <= `True;
                        mem_addr <= rs1_oprand[head+1] + imm[head+1];
                        Byte_num <= 3'd2;
                    end
                    `op_lw: begin
                        read_mem <= `True;
                        mem_addr <= rs1_oprand[head+1] + imm[head+1];
                        Byte_num <= 3'd4;
                    end
                    `op_lbu: begin
                        read_mem <= `True;
                        mem_addr <= rs1_oprand[head+1] + imm[head+1];
                        Byte_num <= 3'd1;
                    end
                    `op_lhu: begin
                        read_mem <= `True;
                        mem_addr <= rs1_oprand[head+1] + imm[head+1];
                        Byte_num <= 3'd2;
                    end
                    `op_sb: begin
                        if(can_store) begin
                            write_mem <= `True;
                            mem_addr <= rs1_oprand[head+1] + imm[head+1];
                            Byte_num <= 3'd1;
                            write_data <= {24'd0,rs2_oprand[head+1][7:0]};
                        end
                        else begin
                            is_waiting <= `False;
                        end
                    end
                    `op_sh: begin
                        if(can_store) begin
                            write_mem <= `True;
                            mem_addr <= rs1_oprand[head+1] + imm[head+1];
                            Byte_num <= 3'd2;
                            write_data <= {16'd0,rs2_oprand[head+1][15:0]};
                        end
                        else begin
                            is_waiting <= `False;
                        end
                    end
                    `op_sw: begin
                        if(can_store) begin
                            write_mem <= `True;
                            mem_addr <= rs1_oprand[head+1] + imm[head+1];
                            Byte_num <= 3'd4;
                            write_data <= rs2_oprand[head+1];
                        end
                        else begin
                            is_waiting <= `False;
                        end
                    end
                    endcase
                end*/ 
            end
            if(has_rd_ready_1||has_rd_ready_2)begin
                for(i = 0; i <= 15; i = i + 1) begin
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
                end
            end
        end 
    end


endmodule //SLBuffer