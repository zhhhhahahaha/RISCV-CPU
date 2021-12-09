`include "config.v"

//the module can make sure the reg[0] cannot be modified
module registerfile (
    input clk,
    input rst,
    input rdy,
    input has_misbranch,

    //to issue
    output [`Data_Len] rs1_data,
    output [`Data_Len] rs2_data,
    output rs1_busy,
    output rs2_busy,
    output [`Rob_Addr_Len] rs1_rob_num,
    output [`Rob_Addr_Len] rs2_rob_num,

    //from issue
    input [`Reg_Addr_Len] rs1_addr,
    input [`Reg_Addr_Len] rs2_addr,
    input needsetbusy,
    input [`Reg_Addr_Len] rd_addr,
    input [`Rob_Addr_Len] rd_rob_num,

    //from rob
    input has_from_rob,
    input [`Reg_Addr_Len] dest_reg_num,
    input [`Data_Len] in_reg_data

    
);
    reg [`Data_Len] datas [`Regfile_Size];
    reg [`Rob_Addr_Len] rob_num [`Regfile_Size];
    reg busy [`Regfile_Size];
    integer i;
    integer file;
    initial begin
        file = $fopen("a.out", "w");
    end
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < 32 ; i = i + 1)begin
                datas[i] <= `Zero_Data;
                rob_num[i] <= 4'd0;
                busy[i] <= `False;
            end   
        end
        else if (has_misbranch) begin
            for(i = 0; i < 32 ; i = i + 1)begin
                busy[i] <= `False;
            end
        end
        else if(rdy) begin
            if (needsetbusy && rd_addr != `Zero_Reg_Addr) begin
                busy[rd_addr] <= `True;
                rob_num[rd_addr] <= rd_rob_num;
            end
            if (has_from_rob && dest_reg_num!=`Zero_Reg_Addr) begin
                busy[dest_reg_num] <= `False;
                datas[dest_reg_num] <= in_reg_data;
                $fwrite(file, "%d", dest_reg_num);
                $fwrite(file, "  ");
                $fwrite(file, $time);
                $fdisplay(file, "%d", in_reg_data);
            end
        end
    end

    assign rs1_data = (has_from_rob && dest_reg_num==rs1_addr)? in_reg_data : datas[rs1_addr];
    assign rs2_data = (has_from_rob && dest_reg_num==rs2_addr)? in_reg_data : datas[rs2_addr];
    assign rs1_busy = (has_from_rob && dest_reg_num==rs1_addr)? `False : busy[rs1_addr];
    assign rs2_busy = (has_from_rob && dest_reg_num==rs2_addr)? `False : busy[rs2_addr];
    assign rs1_rob_num = rob_num[rs1_addr];
    assign rs2_rob_num = rob_num[rs2_addr];

endmodule //registerfile