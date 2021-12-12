`include "config.v"

//have not setting prediction
//have not solve the misbranch problem
module pc_reg (
    input clk,
    input rst,
    input rdy,
    input has_misbranch,

    //to fetcher
    output [`Addr_Len] out_next_pc,
    output reg pc_ready,
    output reg has_jump,

    //from fetcher
    input [`Data_Len] inst,
    input has_ask,

    //from rob
    input [`Addr_Len] in_true_pc,
    input [`Addr_Len] in_pc,
    input in_need_jump
    
);
    reg [`Addr_Len] pc;
    reg [1:0] branch_predictor[`Predictor_Size];
    integer i;

    wire [`Data_Len] J_Imm, B_Imm;
    assign J_Imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:25], inst[24:21], 1'b0};
    assign B_Imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    assign out_next_pc = pc;
    
    always @(posedge clk) begin
        if(rst) begin
            pc <= `Zero_Addr;
            pc_ready <= `False;
            has_jump <= `False;
            for(i=0; i<255; i=i+1) begin
                branch_predictor[i] <= 2'b10;
            end
        end 
        else if(has_misbranch) begin
            pc <= in_true_pc;
            pc_ready <= `True;
            if(in_need_jump)begin
                if(branch_predictor[in_pc[9:2]][0]==1'b1)begin
                    branch_predictor[in_pc[9:2]] <= 2'b11;
                end
                else begin
                    branch_predictor[in_pc[9:2]] <= {branch_predictor[in_pc[9:2]][1], 1'b1};
                end
            end
            else begin
                if(branch_predictor[in_pc[9:2]][0]==1'b1)begin
                    branch_predictor[in_pc[9:2]] <= {branch_predictor[in_pc[9:2]][1], 1'b0};
                end
                else begin
                    branch_predictor[in_pc[9:2]] <= 2'b00;
                end
            end
            //$display("%d", pc);
        end
        else if (rdy) begin
            if(has_ask) begin
                pc_ready <= `True;
                if (inst[6:0]==`B_Type) begin
                    if(branch_predictor[pc[9:2]][1]==1'b1)begin
                        pc <= pc + B_Imm;
                        has_jump <= `True;    
                    end
                    else begin
                        pc <= pc + 4;
                        has_jump <= `False;
                    end
                    //$display("%d", pc);
                end
                else if(inst[6:0]==`Jal) begin
                    pc <= pc + J_Imm;
                    has_jump <= `True;
                    //$display("%d", pc);
                end
                else begin
                    pc <= pc + 4;
                    has_jump <= `False;
                    //$display("%d", pc);
                end
            end
            else begin
                pc_ready <= `False;
            end
        end    
    end

endmodule //pc_reg