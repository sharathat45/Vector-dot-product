`include "floating_add_sub.v"
`include "floating_multiplier.v"

module vector_dot(
				clk,
				reset,
				address,
				writedata,
				write,
				read,
				readdata);

///////// AVALON-MM Interface signals
input clk;				// clock coming in from the Avalon bus
input reset;			// reset from the Avalon bus
input [1:0]address;  	// 2-bit address coming from the Avalon bus 
input [31:0] writedata; // 32-bit write data line
input write;			// write request from the Avalon bus
input read;				// read request from the Avalon bus
output reg [31:0] readdata;	// 32-bit data line read by the Avalon bus

reg [31:0] in_data[1:0];
reg [31:0] add_in_reg;	
reg [31:0] add_in_out_fb;
wire [31:0] mul_out;
wire [31:0] add_out;

floating_multiplier m1(in_data[0], in_data[1], mul_out);
floating_add_sub a1(add_in_reg, add_in_out_fb, add_out);

always @ (posedge clk)
begin
    if(reset == 1'b1)
    begin
        readdata <= 32'b0;
        {in_data[0], in_data[1]} <= {2{32'b0}};
        {add_in_reg, add_in_out_fb} <= {2{32'b0}};
    end    
    else
    begin    
        if (read == 1'b1 )
        begin
            readdata <= add_out;
            {in_data[0], in_data[1]} <= {2{32'b0}};
            {add_in_reg, add_in_out_fb} <= {2{32'b0}};
        end
        else if(write == 1'b1)
        begin
            in_data[address] <= writedata; 
            if (address == 0) //3rd posedge clk
                add_in_reg <= mul_out;  
            else if (address == 1) //4th posedge clk
                add_in_out_fb <= add_out;                 
        end     
    end    
end	


endmodule