`include "config.v"

//have not considered the i/o problem

module ask_memory (
    input clk, input rst, input rdy,
    input io_buffer_full,
    input has_misbranch,

    //to ram
    output reg ram_wr,
    output reg [`Addr_Len] ram_addr,
    output reg [`Ram_Data_Len] out_ram_data,

    //from ram
    input [`Ram_Data_Len] in_ram_data,

    //from fetcher
    input [`Addr_Len] in_fetch_mem_addr,
    input in_fetch_mem_ask,

    //to fetcher
    output reg out_fetcher_mem_ready,
    output reg [`Data_Len] out_fetcher_inst,

    //from slbuffer
    input in_read_mem,
    input in_write_mem,
    input [`Addr_Len] in_slb_mem_addr,
    input [2:0] in_byte_num,
    input [`Data_Len] in_write_data,

    //to slbuffer
    output reg out_slb_mem_ready,
    output reg [`Data_Len] out_slb_mem_data


);
    reg fetch_waiting;
    reg fetch_is_reading;
    reg [`Data_Len] fetch_inst_buffer;
    reg [`Addr_Len] fetch_mem_addr;
    integer read_state;

    reg slb_waiting;
    reg slb_is_wr;
    reg wr; //1 for write, 0 for read
    reg [`Addr_Len] slb_mem_addr;
    reg [2:0] byte_num;
    reg [`Data_Len] slb_data;
    reg [`Data_Len] slb_read_buffer;
    reg [2:0] slb_wr_state;
    integer file;
    initial begin
        file = $fopen("a.out", "w");
    end

    always @(posedge clk) begin
        if(rst) begin
            ram_wr <= `Read;
            ram_addr <= `Zero_Addr;
            out_fetcher_mem_ready <= `False;
            out_slb_mem_ready <= `False;
            fetch_waiting <= `False;
            fetch_is_reading <= `False;
            slb_is_wr <= `False;
            slb_waiting <= `False;
        end
        else if (has_misbranch) begin
            ram_wr <= `Read;
            ram_addr <= `Zero_Addr;
            out_fetcher_mem_ready <= `False;
            out_slb_mem_ready <= `False;
            fetch_waiting <= `False;
            fetch_is_reading <= `False;
            slb_is_wr <= `False;
            slb_waiting <= `False;
        end
        else if(rdy) begin
            ram_wr <= `Read;
            ram_addr <= `Zero_Addr;
            out_fetcher_mem_ready <= `False;
            out_slb_mem_ready <= `False;
            if(in_fetch_mem_ask) begin
                fetch_waiting <= `True;
                fetch_is_reading <= `False;
                fetch_mem_addr <= in_fetch_mem_addr;
            end
            if(in_read_mem||in_write_mem) begin
                slb_waiting <= `True;
                wr <= in_read_mem? `Read : `Write;
                slb_mem_addr <= in_slb_mem_addr;
                byte_num <= in_byte_num;
                slb_data <= in_write_data;
            end
            if((in_read_mem||in_write_mem) && !fetch_is_reading) begin
                if(!(in_write_mem && in_slb_mem_addr==32'h30000)) begin
                    slb_is_wr <= `True;
                    fetch_is_reading <= `False;
                    ram_wr <= in_write_mem? `Write : `Read;
                    ram_addr <= in_slb_mem_addr;
                    out_ram_data <= in_write_data[7:0];
                    slb_wr_state <= 3'd0;
                end
            end
            if(slb_waiting && !fetch_is_reading && !slb_is_wr && slb_mem_addr!=32'h30000) begin
                slb_is_wr <= `True;
                fetch_is_reading <= `False;
                ram_wr <= wr? `Write : `Read;
                ram_addr <= slb_mem_addr;
                out_ram_data <= slb_data[7:0];
                slb_wr_state <= 3'd0;
            end
            if(in_fetch_mem_ask && !slb_is_wr) begin
                fetch_is_reading <= `True;
                slb_is_wr <= `False;
                read_state <= 0;
                ram_wr <= `Read;
                ram_addr <= in_fetch_mem_addr;
            end
            if(fetch_waiting && !fetch_is_reading && !slb_is_wr) begin
                fetch_is_reading <= `True;
                slb_is_wr <= `False;
                read_state <= 0;
                ram_wr <= `Read;
                ram_addr <= fetch_mem_addr; 
            end
            if(in_write_mem && !fetch_is_reading && in_slb_mem_addr==32'h30000)begin
                if(!io_buffer_full) begin
                    ram_wr <= `Write;
                    ram_addr <= in_slb_mem_addr;
                    out_ram_data <= in_write_data[7:0];
                    out_slb_mem_ready <= `True;
                    slb_waiting <= `False;
                    slb_is_wr <= `False;
                    fetch_is_reading <= `False;
                    //$fwrite(file, $time);
                    //$fwrite(file, "  ");
                    //$fdisplay(file, in_write_data[7:0]);
                end
            end
            if(slb_waiting && wr==`Write &&!fetch_is_reading && !slb_is_wr && slb_mem_addr==32'h30000 && !io_buffer_full)begin
                ram_wr <= `Write;
                ram_addr <= slb_mem_addr;
                out_ram_data <= slb_data[7:0];
                out_slb_mem_ready <= `True;
                slb_waiting <= `False;
                slb_is_wr <= `False;
                fetch_is_reading <= `False;
                //$fwrite(file, $time);
                //$fwrite(file, "  ");
                //$fdisplay(file, slb_data[7:0]);
            end
            if(fetch_is_reading) begin
                case(read_state)
                    0 : begin
                        ram_addr <= fetch_mem_addr + 1;
                        read_state <= read_state + 1;
                    end
                    1 : begin
                        fetch_inst_buffer <= {24'd0, in_ram_data};
                        ram_addr <= fetch_mem_addr + 2;
                        read_state <= read_state + 1;
                    end
                    2 : begin
                        fetch_inst_buffer <= {16'd0, in_ram_data, fetch_inst_buffer[7:0]};
                        ram_addr <= fetch_mem_addr + 3;
                        read_state <= read_state + 1;
                    end
                    3 : begin
                        fetch_inst_buffer <= {8'd0, in_ram_data, fetch_inst_buffer[15:0]};
                        read_state <= read_state + 1;
                    end
                    4 : begin
                        out_fetcher_mem_ready <= `True;
                        out_fetcher_inst <= {in_ram_data,fetch_inst_buffer[23:0]};
                        fetch_waiting <= `False;
                        fetch_is_reading <= `False;
                    end
                endcase
            end
            if(slb_is_wr && wr==`Read) begin
                case(slb_wr_state)
                    3'd0 : begin
                        if(byte_num==3'd1)begin
                            slb_wr_state <= slb_wr_state + 1;
                        end
                        else begin
                            ram_addr <= slb_mem_addr + 1;
                            slb_wr_state <= slb_wr_state + 1;
                        end
                    end
                    3'd1 : begin
                        if(byte_num==3'd1)begin
                            out_slb_mem_ready <= `True;
                            out_slb_mem_data <= {24'd0, in_ram_data};
                            slb_waiting <= `False;
                            slb_is_wr <= `False;
                        end
                        else if(byte_num==3'd2)begin
                            slb_wr_state <= slb_wr_state + 1;
                            slb_read_buffer <= {24'd0, in_ram_data};
                        end
                        else begin
                            ram_addr <= slb_mem_addr + 2;
                            slb_wr_state <= slb_wr_state + 1;
                            slb_read_buffer <= {24'd0, in_ram_data};
                        end
                    end
                    3'd2 : begin
                        if(byte_num==3'd2) begin
                            out_slb_mem_ready <= `True;
                            out_slb_mem_data <= {16'd0, in_ram_data, slb_read_buffer[7:0]};
                            slb_waiting <= `False;
                            slb_is_wr <= `False;
                        end
                        else begin
                            ram_addr <= slb_mem_addr + 3;
                            slb_wr_state <= slb_wr_state + 1;
                            slb_read_buffer <= {16'd0, in_ram_data, slb_read_buffer[7:0]};
                        end
                    end
                    3'd3 : begin
                        slb_wr_state <= slb_wr_state + 1;
                        slb_read_buffer <= {8'd0,in_ram_data, slb_read_buffer[15:0]};
                    end
                    3'd4 : begin
                        out_slb_mem_ready <= `True;
                        out_slb_mem_data <= {in_ram_data, slb_read_buffer[23:0]};
                        slb_waiting <= `False;
                        slb_is_wr <= `False;
                    end
                endcase
            end
            if(slb_is_wr && wr==`Write && slb_mem_addr!=32'd30000) begin
                case(slb_wr_state)
                    3'd0 : begin
                        if(byte_num==3'd1) begin
                            out_slb_mem_ready <= `True;
                            slb_waiting <= `False;
                            slb_is_wr <= `False;
                        end
                        else begin
                            ram_wr <= `Write;
                            ram_addr <= slb_mem_addr + 1;
                            out_ram_data <= slb_data[15:8];
                            slb_wr_state <= slb_wr_state + 1;
                        end
                    end
                    3'd1 : begin
                        if(byte_num==3'd2) begin
                            out_slb_mem_ready <= `True;
                            slb_waiting <= `False;
                            slb_is_wr <= `False;
                        end
                        else begin
                            ram_wr <= `Write;
                            ram_addr <= slb_mem_addr + 2;
                            out_ram_data <= slb_data[23:16];
                            slb_wr_state <= slb_wr_state + 1;
                        end
                    end
                    3'd2 : begin
                        ram_wr <= `Write;
                        ram_addr <= slb_mem_addr + 3;
                        out_ram_data <= slb_data[31:24];
                        slb_wr_state <= slb_wr_state + 1;
                    end
                    3'd3 : begin
                        out_slb_mem_ready <= `True;
                        slb_waiting <= `False;
                        slb_is_wr <= `False;
                    end
                endcase
            end
        end
       
    end

endmodule //ask_memory