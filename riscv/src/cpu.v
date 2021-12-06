// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "alu.v"
`include "ask_memory.v"
`include "fetcher.v"
`include "issue.v"
`include "pc_reg.v"
`include "registerfile.v"
`include "rob.v"
`include "rs.v"
`include "slbuffer.v"



module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)
  
  //from rob
  wire has_misbranch;

  wire rob_avail;
  wire [`Rob_Addr_Len]rob_avail_num;
  wire rs1_ready;
  wire rs2_ready;
  wire [`Data_Len] rs1_data;
  wire [`Data_Len] rs2_data;

  wire has_rd_ready_1;
  wire [`Rob_Addr_Len] ready_robnum_1;
  wire [`Data_Len] ready_data_1;
  wire has_rd_ready_2;
  wire [`Rob_Addr_Len] ready_robnum_2;
  wire [`Data_Len] ready_data_2;

  wire can_store;

  wire has_to_reg;
  wire [`Reg_Addr_Len] dest_reg_num;
  wire [`Data_Len] out_reg_data;

  wire [`Addr_Len] out_true_pc;

  //from pc_reg
  wire [`Addr_Len] out_next_pc;
  wire pc_ready;
  wire has_jump;

  //from fetcher
  wire [`Addr_Len] out_mem_addr;
  wire mem_ask;

  wire [`Data_Len] out_pc_inst;
  wire pc_reg_ask;
  
  wire can_issue;
  wire [`Data_Len] out_issue_inst;
  wire [`Addr_Len] out_issue_pc;
  wire out_has_jump;

  //from ask_memory
  wire out_fetcher_mem_ready;
  wire [`Data_Len] out_fetcher_inst;

  wire out_slb_mem_ready;
  wire [`Data_Len] out_slb_mem_data;

  //from issue
  wire issue_rob;
  wire [1:0] inst_type;
  wire [`Reg_Addr_Len] dest;
  wire out_has_jump_issue;
  wire [`Rob_Addr_Len] out_rs1_rob_num;
  wire [`Rob_Addr_Len] out_rs2_rob_num;

  wire issue_rs;
  wire [`Data_Len] rs_imm;
  wire [5:0] rs_op;
  wire [`Addr_Len] rs_pc;
  wire [`Shamt_Len] shamt;
  wire [`Rob_Addr_Len] rs_rd_robnum;
  wire [`Data_Len] rs_rs1_oprand;
  wire [`Data_Len] rs_rs2_oprand;
  wire [`Rob_Addr_Len] rs_rs1_robnum;
  wire [`Rob_Addr_Len] rs_rs2_robnum;
  wire rs_rs1_ready;
  wire rs_rs2_ready;

  wire issue_slb;
  wire [`Data_Len] slb_imm;
  wire [5:0] slb_op;
  wire [`Rob_Addr_Len] slb_rd_robnum;
  wire [`Data_Len] slb_rs1_oprand;
  wire [`Data_Len] slb_rs2_oprand;
  wire [`Rob_Addr_Len] slb_rs1_robnum;
  wire [`Rob_Addr_Len] slb_rs2_robnum;
  wire slb_rs1_ready;
  wire slb_rs2_ready;

  wire [`Reg_Addr_Len] rs1_addr;
  wire [`Reg_Addr_Len] rs2_addr;
  wire needsetbusy;
  wire [`Reg_Addr_Len] rd_addr;
  wire [`Rob_Addr_Len] rd_rob_num;

  //from alu
  wire has_to_rob;
  wire [`Rob_Addr_Len] out_rd_robnum;
  wire [`Data_Len] out_rd_data;
  wire need_jump;
  wire [`Addr_Len] true_pc;

  //from rs
  wire rs_avail;

  wire has_to_alu;
  wire [`Data_Len] out_imm;
  wire [5:0] out_op;
  wire [`Addr_Len] out_pc;
  wire [`Shamt_Len] out_shamt;
  wire [`Rob_Addr_Len] out_rs_rd_robnum;
  wire [`Data_Len] out_rs1_oprand;
  wire [`Data_Len] out_rs2_oprand;

  //from slbuffer
  wire slb_avail;

  wire read_mem;
  wire write_mem;
  wire [`Addr_Len] mem_addr;
  wire [2:0] Byte_num;
  wire [`Data_Len] write_data;

  wire has_to_rob_slb;
  wire [`Rob_Addr_Len] out_rd_robnum_slb;
  wire [`Data_Len] out_rd_data_slb;

  //from registerfile
  wire [`Data_Len] rs1_data_reg;
  wire [`Data_Len] rs2_data_reg;
  wire rs1_busy;
  wire rs2_busy;
  wire [`Rob_Addr_Len] rs1_rob_num;
  wire [`Rob_Addr_Len] rs2_rob_num;


  pc_reg pc_reg_m(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
    .has_misbranch(has_misbranch),

    .out_next_pc(out_next_pc), .pc_ready(pc_ready), .has_jump(has_jump),

    .inst(out_pc_inst), .has_ask(pc_reg_ask), 

    .in_true_pc(out_true_pc)
  );

  fetcher fetcher_m(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
    .has_misbranch(has_misbranch),

    .out_mem_addr(out_mem_addr), .mem_ask(mem_ask),

    .in_mem_inst(out_fetcher_inst), .in_mem_ready(out_fetcher_mem_ready),

    .out_pc_inst(out_pc_inst), .pc_reg_ask(pc_reg_ask),

    .in_pc_addr(out_next_pc), .pc_ready(pc_ready), .in_has_jump(has_jump),

    .can_issue(can_issue), .out_issue_inst(out_issue_inst), .out_issue_pc(out_issue_pc),
    .out_has_jump(out_has_jump),

    .rob_avail(rob_avail),

    .rs_avail(rs_avail),

    .slb_avail(slb_avail) 

  );

  ask_memory ask_memory_m(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
    .io_buffer_full(io_buffer_full), .has_misbranch(has_misbranch),

    .ram_wr(mem_wr), .ram_addr(mem_a), .out_ram_data(mem_dout), 

    .in_ram_data(mem_din),

    .in_fetch_mem_addr(out_mem_addr), .in_fetch_mem_ask(mem_ask),

    .out_fetcher_mem_ready(out_fetcher_mem_ready), .out_fetcher_inst(out_fetcher_inst),

    .in_read_mem(read_mem), .in_write_mem(write_mem), .in_slb_mem_addr(mem_addr),
    .in_byte_num(Byte_num), .in_write_data(write_data),

    .out_slb_mem_ready(out_slb_mem_ready), .out_slb_mem_data(out_slb_mem_data)


  );

  issue issue_m(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
    .has_misbranch(has_misbranch),

    .inst(out_issue_inst), .pc(out_issue_pc), .can_issue(can_issue),
    .in_has_jump(out_has_jump),

    .rob_avail(rob_avail), .rob_avail_num(rob_avail_num), .rob_rs1_ready(rs1_ready), 
    .rob_rs2_ready(rs2_ready), .rob_rs1_data(rs1_data), .rob_rs2_data(rs2_data),

    .issue_rob(issue_rob), .inst_type(inst_type), .dest(dest),
    .out_has_jump(out_has_jump_issue), .out_rs1_rob_num(out_rs1_rob_num),
    .out_rs2_rob_num(out_rs2_rob_num),

    .rs_avail(rs_avail),

    .issue_slb(issue_slb), .slb_imm(slb_imm), .slb_op(slb_op),
    .slb_rd_robnum(slb_rd_robnum), .slb_rs1_oprand(slb_rs1_oprand), .slb_rs2_oprand(slb_rs2_oprand),
    .slb_rs1_robnum(slb_rs1_robnum), .slb_rs2_robnum(slb_rs2_robnum), .slb_rs1_ready(slb_rs1_ready),
    .slb_rs2_ready(slb_rs2_ready),

    .rs1_data(rs1_data_reg), .rs2_data(rs2_data_reg), .rs1_busy(rs1_busy), 
    .rs2_busy(rs2_busy), .in_rs1_rob_num(rs1_rob_num), .in_rs2_rob_num(rs2_rob_num),

    .rs1_addr(rs1_addr), .rs2_addr(rs2_addr), .needsetbusy(needsetbusy), 
    .rd_addr(rd_addr), .rd_rob_num(rd_rob_num)


  );

  registerfile registerfile_m(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
    .has_misbranch(has_misbranch),

    .rs1_data(rs1_data_reg), .rs2_data(rs2_data_reg), .rs1_busy(rs1_busy),
    .rs2_busy(rs2_busy), .rs1_rob_num(rs1_rob_num), .rs2_rob_num(rs2_rob_num),

    .rs1_addr(rs1_addr), .rs2_addr(rs2_addr), .needsetbusy(needsetbusy), 
    .rd_addr(rd_addr), .rd_rob_num(rd_rob_num),

    .has_from_rob(has_to_reg), .dest_reg_num(dest_reg_num), .in_reg_data(out_reg_data)

  );

  rob rob_m(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
    .has_misbranch(has_misbranch),

    .inst_type(inst_type), .dest(dest), .rs1_rob_num(out_rs1_rob_num), 
    .rs2_rob_num(out_rs2_rob_num), .hasissued(issue_rob),
    .in_has_jump(out_has_jump_issue),

    .rob_avail(rob_avail), .rob_avail_num(rob_avail_num), .rs1_ready(rs1_ready),
    .rs2_ready(rs2_ready), .rs1_data(rs1_data), .rs2_data(rs2_data),

    .has_from_alu(has_to_rob), .in_alu_rd_robnum(out_rd_robnum), .in_alu_rd_data(out_rd_data), 
    .in_need_jump(need_jump), .in_true_pc(true_pc), 

    .has_rd_ready_1(has_rd_ready_1), .ready_robnum_1(ready_robnum_1), .ready_data_1(ready_data_1), 
    .has_rd_ready_2(has_rd_ready_2), .ready_robnum_2(ready_robnum_2), .ready_data_2(ready_data_2),

    .has_from_slb(has_to_rob_slb), .in_slb_rd_robnum(out_rd_robnum_slb), .in_slb_rd_data(out_rd_data_slb),

    .can_store(can_store), 

    .has_to_reg(has_to_reg), .dest_reg_num(dest_reg_num), .out_reg_data(out_reg_data),

    .out_true_pc(out_true_pc)
  );

  rs rs_m(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in), 
    .has_misbranch(has_misbranch),

    .has_issue(issue_rs), .in_imm(rs_imm), .in_op(rs_op),
    .in_shamt(shamt), .in_rs_rd_robnum(rs_rd_robnum), .in_rs1_oprand(rs_rs1_oprand),
    .in_rs2_oprand(rs_rs2_oprand), .in_rs1_robnum(rs_rs1_robnum), .in_rs2_robnum(rs_rs2_robnum),
    .in_rs1_ready(rs_rs1_ready), .in_rs2_ready(rs_rs2_ready),

    .rs_avail(rs_avail),

    .has_to_alu(has_to_alu), .out_imm(out_imm), .out_op(out_op),
    .out_pc(out_pc), .out_shamt(out_shamt), .out_rs_rd_robnum(out_rs_rd_robnum), 
    .out_rs1_oprand(out_rs1_oprand), .out_rs2_oprand(out_rs2_oprand),

    .has_rd_ready_1(has_rd_ready_1), .ready_robnum_1(ready_robnum_1), .ready_data_1(ready_data_1), 
    .has_rd_ready_2(has_rd_ready_2), .ready_robnum_2(ready_robnum_2), .ready_data_2(ready_data_2)
  );

  alu alu_m(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
    .has_misbranch(has_misbranch),

    .has_to_alu(has_to_alu), .imm(out_imm), .op(out_op),
    .pc(out_pc), .shamt(out_shamt), .in_rd_robnum(out_rs_rd_robnum), 
    .rs1_oprand(out_rs1_oprand), .rs2_oprand(out_rs2_oprand),

    .has_to_rob(has_to_rob), .out_rd_robnum(out_rd_robnum), .out_rd_data(out_rd_data),
    .need_jump(need_jump), .true_pc(true_pc)
    
  );

  slbuffer slbuffer_m(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
    .has_misbranch(has_misbranch),

    .has_issue(issue_slb), .in_imm(slb_imm), .in_op(slb_op),
    .in_rd_robnum(slb_rd_robnum), .in_rs1_oprand(slb_rs1_oprand), .in_rs2_oprand(slb_rs2_oprand),
    .in_rs1_robnum(slb_rs1_robnum), .in_rs2_robnum(slb_rs2_robnum), .in_rs1_ready(slb_rs1_ready),
    .in_rs2_ready(slb_rs2_ready),

    .slb_avail(slb_avail),

    .in_mem_ready(out_slb_mem_ready), .in_mem_data(out_slb_mem_data),

    .read_mem(read_mem), .write_mem(write_mem), .mem_addr(mem_addr),
    .Byte_num(Byte_num), .write_data(write_data),

    .can_store(can_store),

    .has_rd_ready_1(has_rd_ready_1), .ready_robnum_1(ready_robnum_1), .ready_data_1(ready_data_1), 
    .has_rd_ready_2(has_rd_ready_2), .ready_robnum_2(ready_robnum_2), .ready_data_2(ready_data_2),
    
    .has_to_rob(has_to_rob_slb), .out_rd_robnum(out_rd_robnum_slb), .out_rd_data(out_rd_data_slb)

  );


  
endmodule