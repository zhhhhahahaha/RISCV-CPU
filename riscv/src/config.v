`timescale  1ns/1ps

`define Inst_Len 31:0
`define Addr_Len 31:0
`define Data_Len 31:0
`define Ram_Data_Len 7:0
`define Zero_Data 32'h0000_0000
`define Zero_Addr 32'h0000_0000

`define True 1'b1
`define False 1'b0 

`define Read 1'b0
`define Write 1'b1

`define Regfile_Size 31:0
`define Reg_Addr_Len 4:0
`define Zero_Reg_Addr 5'b00000

`define Slb_Size 15:0
`define Slb_Addr_Len 3:0

`define Lui 7'b0110111
`define Auipc 7'b0010111
`define Jal 7'b1101111
`define Jalr 7'b1100111
`define B_Type 7'b1100011
`define L_Type 7'b0000011
`define S_Type 7'b0100011
`define OtherI 7'b0010011
`define Other 7'b0110011

`define beq 3'b000
`define bne 3'b001
`define blt 3'b100
`define bge 3'b101
`define bltu 3'b110
`define bgeu 3'b111

`define lb 3'b000
`define lh 3'b001
`define lw 3'b010
`define lbu 3'b100
`define lhu 3'b101

`define sb 3'b000
`define sh 3'b001
`define sw 3'b010

`define addi 3'b000
`define slti 3'b010
`define sltiu 3'b011
`define xori 3'b100
`define ori 3'b110
`define andi 3'b111
`define slli 3'b001
`define sr 3'b101

`define srli 7'b0000000
`define srai 7'b0100000

`define add_sub 3'b000
`define sll 3'b001
`define slt 3'b010
`define sltu 3'b011
`define XOR 3'b100
`define srl_a 3'b101
`define OR 3'b110
`define AND 3'b111

`define add 7'b0000000
`define sub 7'b0100000
`define srl 7'b0000000
`define sra 7'b0100000

`define Shamt_Len 4:0

//for ROB
`define Rob_Size 15:0
`define Rob_Addr_Len 3:0
`define Branch_Type 2'b00
`define Store_Type  2'b01
`define Other_Type  2'b10
`define Jalr_Type 2'b11

`define Rs_Size 15:0
`define Rs_Addr_Len 3:0

`define op_lui   6'd1
`define op_auipc 6'd2
`define op_jal   6'd3
`define op_jalr  6'd4
`define op_beq   6'd5
`define op_bne   6'd6
`define op_blt   6'd7
`define op_bge   6'd8
`define op_bltu  6'd9
`define op_bgeu  6'd10
`define op_lb    6'd11
`define op_lh    6'd12
`define op_lw    6'd13
`define op_lbu   6'd14
`define op_lhu   6'd15
`define op_sb    6'd16
`define op_sh    6'd17
`define op_sw    6'd18
`define op_addi  6'd19
`define op_slti  6'd20
`define op_sltiu 6'd21
`define op_xori  6'd22
`define op_ori   6'd23
`define op_andi  6'd24
`define op_slli  6'd25
`define op_srli  6'd26
`define op_srai  6'd27
`define op_add   6'd28
`define op_sub   6'd29
`define op_sll   6'd30
`define op_slt   6'd31
`define op_sltu  6'd32
`define op_xor   6'd33
`define op_srl   6'd34
`define op_sra   6'd35
`define op_or    6'd36
`define op_and   6'd37

