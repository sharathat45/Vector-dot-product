`timescale 1ns/1ps  // time-unit = 1 ns, precision = 10 ps

`include "vector_dot_dma.v"

module vector_dot_dma_tb;

reg clk;

reg read;
reg reset;
reg write;
reg [1:0]address;
reg [31:0]writedata;
reg b_data;

wire [31:0]readdata;

parameter CLK_PERIOD = 10; //10ns
parameter STOP_PERIOD = 20;   //100ns

initial begin
  clk = 1;
  forever  #CLK_PERIOD clk = ~clk;
end

localparam INCREMET = 1;
localparam ARRAY_LENGTH = 6; 

wire [0:32*ARRAY_LENGTH-1]payload =
{
32'h3F800000, 
32'h40000000,
32'h40400000,
32'h40800000,
32'h40A00000, 
32'h40C00000
};

integer i;
vector_dot_dma s1(
				clk,
				reset,
				address,
				writedata,
				write,
				read,
				readdata, b_data);

initial 
    begin

      $dumpfile("vector_dot_dma.vcd");
      $dumpvars(0,vector_dot_dma_tb);
    
      
      reset = 1;
      #STOP_PERIOD 
      
      for (i = 0; i < ARRAY_LENGTH; i = i + INCREMET) 
      begin
        
          writedata = payload[(i)*32 +:32];  
          reset = 0; address = i; write =1; read = 0; b_data = 0;
          #STOP_PERIOD;

      $display("Operands A: A[%d] = %x\n",i, payload[(i)*32 +:32]);
      end

      for (i = 0; i < ARRAY_LENGTH; i = i + INCREMET) 
      begin
        
          writedata = payload[(i)*32 +:32];  
          reset = 0; address = i; write =1; read = 0; b_data = 1;
          #STOP_PERIOD;

      $display("Operands B: B[%d] = %x\n",i, payload[(i)*32 +:32]);
      end

      writedata = 32'd0;  
      reset = 0; address = 0; write =1; read = 0;
      #STOP_PERIOD;

      reset = 0; write = 0; read = 1; address =0;
      #STOP_PERIOD
      $display("Result = %x \n",readdata);
      
      $finish;
    end

endmodule