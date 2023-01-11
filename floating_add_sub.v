module floating_add_sub(
		input [31:0] dataa,			
        input [31:0] datab,			
        output [31:0] result);

// floating point = Sign_bit| exponent[7:0] | Mantisa[22:0]
// Mantisa implied is in {1}.xxxxx, 1 is not represented in the binary, self implied

wire [7:0] big_exp;
wire [7:0] small_exp;

wire [23:0] big_mant;
wire [23:0] small_mant;

wire [7:0] exp_diff_abs;
wire [8:0] exp_diff_with_carry;

wire [24:0]final_tmp;
wire [24:0]add_tmp;
wire [24:0]sub_tmp;

wire operation;
wire is_big_mant_large;
wire is_both_mant_equal;
wire output_sign;

wire [7:0]new_exp;
wire [24:0]new_mantisa;

// Get difference of Exponents 
assign exp_diff_with_carry = dataa[30:23] - datab[30:23];
assign exp_diff_abs = (exp_diff_with_carry[8] == 1'b1)? ~exp_diff_with_carry+ 1'b1: exp_diff_with_carry;

// Assign the datas according to their exponents values [ big_exp > big_exp ] 
// exp_diff_with_carry[8] == 0 => data_big_exp >/= data_small_exp
// exp_diff_with_carry[8] == 1 => data_small_exp < data_big_exp
// Make their Exponents equal , Hence Shift lowest Mantisa by right shift
assign {big_exp, big_mant} = (exp_diff_with_carry[8] == 0)? 
                                {dataa[30:23], 1'b1, dataa[22:0]}: 
                                {datab[30:23], ({1'b1,dataa[22:0]} >> exp_diff_abs)};
assign {small_exp, small_mant} = (exp_diff_with_carry[8] == 0)? 
                                {dataa[30:23], ({1'b1,datab[22:0]} >> exp_diff_abs)} : 
                                {datab[30:23], 1'b1, datab[22:0]};

// Add the new Mantisa  
//0 = +
//1 = -
assign operation = dataa[31] ^ datab[31];
assign is_big_mant_large = big_mant > small_mant;
assign is_both_mant_equal = (big_mant == small_mant)? 1'b1 :1'b0;

//-- or ++
assign add_tmp = !operation? {1'b0,big_mant} + {1'b0,small_mant} : 24'b0; 

//a-b if a>b or b-a if b>a                                              
assign sub_tmp = operation? is_big_mant_large? {1'b0,big_mant} - {1'b0,small_mant} : {1'b0,small_mant} - {1'b0,big_mant}: 24'b0;

//derived from Kmap
assign final_tmp = add_tmp + sub_tmp;
assign output_sign = (is_both_mant_equal & operation)? 1'b0:
                     (dataa[31] & datab[31]) | (dataa[31] & is_big_mant_large) | (!dataa[31] & datab[31] & !is_big_mant_large); 

// Based on the Overflow: 
//			Adjust the output by left shift, including the overflow bit
// 			Calculate the output Exponents by adding 1 for each shift
highbit_pos m1(big_exp, final_tmp, new_exp, new_mantisa);

//exception handling if big_exp is infinity or NaN output is 0
assign result = (big_exp == 8'b11111111)? 32'b0:{output_sign, new_exp, new_mantisa[22:0]};

endmodule

module highbit_pos(input [7:0]old_exp, input [0:24]old_mantisa, output reg [7:0]new_exp, output reg [24:0]new_mantisa);

// wire [4:0] position;
// generate genvar i; 
//          for (i = 0; i <25; i=i+1)
//             new_mantisa = (old_mantisa == {{i{1'b0}}, 1'b1, {(24-i){1'bx}}})? old_mantisa << i : 5'b0;
// endgenerate

always @(old_mantisa)
begin
casex (old_mantisa)
    25'b0000000000000000000000000 : begin 
                                        new_mantisa = old_mantisa; 
                                        new_exp = 8'b00000000;   
                                    end 
    25'b1xxxxxxxxxxxxxxxxxxxxxxxx : begin 
                                        if(old_exp == 8'b00000000)
                                        begin
                                            new_mantisa = old_mantisa; 
                                            new_exp = old_exp;
                                        end    
                                        else
                                        begin
                                            new_mantisa = old_mantisa >> 1; 
                                            new_exp = old_exp + 1; 
                                        end
                                    end 

    25'b01xxxxxxxxxxxxxxxxxxxxxxx :  begin 
                                        new_mantisa = old_mantisa >> 0; 
                                        new_exp = old_exp + 0; 
                                    end 

    25'b001xxxxxxxxxxxxxxxxxxxxxx :  begin 
                                        new_mantisa = old_mantisa << 1; 
                                        new_exp = old_exp - 1; 
                                    end 

    25'b0001xxxxxxxxxxxxxxxxxxxxx :  begin 
                                        new_mantisa = old_mantisa << 2; 
                                        new_exp = old_exp - 2; 
                                    end 

    25'b00001xxxxxxxxxxxxxxxxxxxx :  begin 
                                        new_mantisa = old_mantisa << 3; 
                                        new_exp = old_exp - 3; 
                                    end 

    25'b000001xxxxxxxxxxxxxxxxxxx :  begin 
                                        new_mantisa = old_mantisa << 4; 
                                        new_exp = old_exp - 4; 
                                    end 

    25'b0000001xxxxxxxxxxxxxxxxxx :  begin 
                                        new_mantisa = old_mantisa << 5; 
                                        new_exp = old_exp - 5; 
                                    end 

    25'b00000001xxxxxxxxxxxxxxxxx :  begin 
                                        new_mantisa = old_mantisa << 6; 
                                        new_exp = old_exp - 6; 
                                    end 

    25'b000000001xxxxxxxxxxxxxxxx :  begin 
                                        new_mantisa = old_mantisa << 7; 
                                        new_exp = old_exp - 7; 
                                    end 

    25'b0000000001xxxxxxxxxxxxxxx :  begin 
                                        new_mantisa = old_mantisa << 8; 
                                        new_exp = old_exp - 8; 
                                    end 

    25'b00000000001xxxxxxxxxxxxxx :  begin 
                                        new_mantisa = old_mantisa << 9; 
                                        new_exp = old_exp - 9; 
                                    end 

    25'b000000000001xxxxxxxxxxxxx :  begin 
                                        new_mantisa = old_mantisa << 10; 
                                        new_exp = old_exp - 10; 
                                    end 

    25'b0000000000001xxxxxxxxxxxx :  begin 
                                        new_mantisa = old_mantisa << 11; 
                                        new_exp = old_exp - 11; 
                                    end 

    25'b00000000000001xxxxxxxxxxx :  begin 
                                        new_mantisa = old_mantisa << 12; 
                                        new_exp = old_exp - 12; 
                                    end 

    25'b000000000000001xxxxxxxxxx :  begin 
                                        new_mantisa = old_mantisa << 13; 
                                        new_exp = old_exp - 13; 
                                    end 

    25'b0000000000000001xxxxxxxxx :  begin 
                                        new_mantisa = old_mantisa << 14; 
                                        new_exp = old_exp - 14; 
                                    end 

    25'b00000000000000001xxxxxxxx :  begin 
                                        new_mantisa = old_mantisa << 15; 
                                        new_exp = old_exp - 15; 
                                    end 

    25'b000000000000000001xxxxxxx :  begin 
                                        new_mantisa = old_mantisa << 16; 
                                        new_exp = old_exp - 16; 
                                    end 

    25'b0000000000000000001xxxxxx :  begin 
                                        new_mantisa = old_mantisa << 17; 
                                        new_exp = old_exp - 17; 
                                    end 

    25'b00000000000000000001xxxxx :  begin 
                                        new_mantisa = old_mantisa << 18; 
                                        new_exp = old_exp - 18; 
                                    end 

    25'b000000000000000000001xxxx :  begin 
                                        new_mantisa = old_mantisa << 19; 
                                        new_exp = old_exp - 19; 
                                    end 

    25'b0000000000000000000001xxx :  begin 
                                        new_mantisa = old_mantisa << 20; 
                                        new_exp = old_exp - 20; 
                                    end 

    25'b00000000000000000000001xx :  begin 
                                        new_mantisa = old_mantisa << 21; 
                                        new_exp = old_exp - 21; 
                                    end 

    25'b000000000000000000000001x :  begin 
                                        new_mantisa = old_mantisa << 22; 
                                        new_exp = old_exp - 22; 
                                    end 

    25'b0000000000000000000000001 :  begin 
                                        new_mantisa = old_mantisa << 23; 
                                        new_exp = old_exp - 23; 
                                    end 
endcase
end

endmodule