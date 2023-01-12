`timescale 1ns/1ps  // time-unit = 1 ns, precision = 10 ps

`include "vector_dot.v"

module vector_dot_tb;

reg clk;

reg read;
reg reset;
reg write;
reg [1:0]address;
reg [31:0]writedata;

wire [31:0]readdata;

parameter CLK_PERIOD = 10;     //10ns
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
vector_dot s1(
				clk,
				reset,
				address,
				writedata,
				write,
				read,
				readdata);

initial 
    begin

      $dumpfile("vector_dot.vcd");
      $dumpvars(0,vector_dot_tb);
      
      reset = 1;
      #STOP_PERIOD

      for (i = 0; i < ARRAY_LENGTH/2; i = i + INCREMET) 
      begin
        
      writedata = payload[(2*i)*32 +:32];  
      reset = 0; address = 0; write =1; read = 0;
      #20
      
      writedata = payload[(2*i+1)*32 +:32];  
      reset = 0; address = 1; write =1; read = 0;
      #STOP_PERIOD;

      $display("Operands are %x %x\n",payload[(2*i)*32 +:32], payload[(2*i+1)*32 +:32]);
      end

      writedata = 32'h0;  
      reset = 0; address = 0; write =1; read = 0;
      #STOP_PERIOD;

      reset = 0; write = 0; read = 1; address =0;
      #STOP_PERIOD
      $display("Result is %x \n",readdata);
      
      $finish;
    end

endmodule