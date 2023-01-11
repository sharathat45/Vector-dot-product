`include "floating_add_sub.v"
`include "floating_multiplier.v"

module vector_dot_dma(
				clk,
				reset,
				address,
				writedata,
				write,
				read,
				readdata,
                b_data);

///////// AVALON-MM Interface signals
input clk;				// clock coming in from the Avalon bus
input reset;			// reset from the Avalon bus
input [1:0]address;  	// 2-bit address coming from the Avalon bus 
input [31:0] writedata; // 32-bit write data line
input write;			// write request from the Avalon bus
input read;				// read request from the Avalon bus

input b_data;				

output reg [31:0] readdata;	// 32-bit data line read by the Avalon bus

localparam INPUT_BUFF_SIZE = 5;
integer i;

reg [31:0] in_data[INPUT_BUFF_SIZE-1:0];

reg [31:0] mull_in[1:0];	
reg [31:0] add_in_reg;	
reg [31:0] add_in_out_fb;
wire [31:0] mul_out;
wire [31:0] add_out;

floating_multiplier m1(mull_in[0], mull_in[1], mul_out);
floating_add_sub a1(add_in_reg, add_in_out_fb, add_out);

always @ (posedge clk)
begin
    if(reset == 1'b1)
    begin
        readdata <= 32'b0;
        {mull_in[0], mull_in[1]} <= {2{32'd0}};
        {add_in_reg, add_in_out_fb} <= {2{32'd0}};
        for(i=0; i < INPUT_BUFF_SIZE; i=i+1)
        begin
            in_data[i]<= 32'b0;
        end
    end    
    else
    begin    
        if (read == 1'b1 )
        begin
            readdata <= add_out;
            {mull_in[0], mull_in[1]} <= {2{32'd0}};
            {add_in_reg, add_in_out_fb} <= {2{32'd0}};
       
            for(i=0; i < INPUT_BUFF_SIZE; i=i+1)
            begin
                in_data[i]<= 32'd0;
            end
        end
        else if(write == 1'b1)
        begin
            if(b_data == 0)
                in_data[address] <= writedata; 
            else if(b_data == 1)
            begin
                mull_in[0]<= writedata;
                mull_in[1]<= in_data[address];
                
                add_in_reg <= mul_out; 
                add_in_out_fb <= add_out; 
            end
                         
        end     
    end    
end	


endmodule