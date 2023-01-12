module floating_multiplier(input [31:0] ain, input [31:0] bin, output [31:0] result);

wire  productsign;     // stores the final sign of the product +ve/-
wire [47:0] product;   // stores the product of the two 24 bit numbers
wire [48:0] norm_product;
wire [22:0] product_trimmed;
wire [8:0] final_exponent, exponentnormal;
wire over_exp; 
wire zero1; 

assign productsign = ain[31]^bin[31]; // sign of the product

assign product = {1'b1,ain[22:0]} * {1'b1,bin[22:0]}; // 48 bit product of mantissas 

// logic to check the significant most significant bit and then perform normalizations
// if 48th bit is 1 then right shift, take 46 bit onwards 23
// bits of mantissa 
// else no shift then take 23 bits from there
 
assign norm_product = ( product[47] == 1) ? product >> 1 : product;
 
// Extract 23 bits out of the 48 bit product
assign product_trimmed = norm_product[45:23]; 

// we will add exponenets and subtract bias from them since 127 is
//added twice, added exponent can be nine bits
// if 48 bit is 1 then we need to move the point to one place left
// and then add to the exponent, otherwise if 48th bit is zero 
// then we have to left shift entire expression.
 
assign exponentnormal = ((ain[30:23] + bin[30:23])); 
assign final_exponent = (exponentnormal - (9'b001111111)) + {8'b0, product[47]}; 

// check if exponent of any number > 255
assign over_exp = (&ain[30:23]) | (&bin[30:23]);

wire overflow; 
assign overflow = ((final_exponent[8] & !final_exponent[7]) & !zero1);

// // underflow condition for the test case a = 32'h0080_0000, b = 32'h00180_0000; 
wire underflow; 
assign underflow = ((final_exponent[8] & final_exponent[7]) & !zero1) ? 1'b1 : 1'b0; 

// check if product of mantissa is all zero; 
assign zero1 = over_exp ? 1'b0 : (product_trimmed == 23'd0) ? 1'b1 : 1'b0;
  
// assign the final result, here underflow and overflow checks could be eliminated code works
// without overlow and underflow flag checks as well. for most of the test cases. 
assign result = (ain == 32'h0 || bin == 32'h0) ? 32'b0 : over_exp ? 32'b0 : zero1 ? {productsign, final_exponent[7:0], 23'b0} : overflow ? {productsign,8'b1,23'b0} : underflow ? {productsign,31'b0} :{productsign,final_exponent[7:0],product_trimmed};

endmodule