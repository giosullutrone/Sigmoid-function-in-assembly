#################################################################################################
# Disclaimer:											#
#################################################################################################
# Made by: Giovanni Sullutrone									#
# Date: 8 march 2020										#
#################################################################################################


#################################################################################################
# .data												#
#################################################################################################
# precision:		number of factors in of taylor's approximation				#
# array:		values to compute (can be any number of floats)				#
# size_of_array:	size of the array to compute						#
#################################################################################################


		.data
precision:	.word		20			#Can be changed
one:		.word		1
neg_one:	.word		-1
zero.s:		.float		0.0
one.s:		.float		1.0
e.s:		.float		2.71828182846
array:		.float		0.5, 1.0, 1.5		#Can be changed
size_of_array:	.word		3			#Can be changed
nl:		.asciiz		"\n"
		.text

#################################################################################################
# functions											#
#################################################################################################
# factorial:		($a0) => ($v0)								#
# factorial_minus_1:	($a0) => ($f0)								#
# pow.s:			($f1, $a0) => ($f0)						#
# centered_pow.s:	($f1, $f2, $a0) => ($f0)						#
# taylor_of_exp.s:	($f1) => ($f0)								#
# sigmoid.s:		($f1) => ($f0)								#
# sigmoid_array.s:	($a0, $a1, $a2)								#
# print_array.s:		($a0, $a1)							#
#################################################################################################


#################################################################################################
# Heap Map											#
#################################################################################################
# 4 * precision - bytes for coefficients of taylor series					#
#												#
# To store array to computer allocate double that amount					#
# 4 * (size of array * 2)									#
#################################################################################################


#################################################################################################
# s registers map										#
#################################################################################################
# $s0 => Heap pointer										#
# $s1 => int one										#
# $s2 => precision const									#
# $s3 => size of array										#
# $s4 => int neg one										#
#################################################################################################


#################################################################################################
# f registers map										#
#################################################################################################
# $f0 => results										#
# $f1 => first paramater									#
# $f2 => second parameter									#
# $f28 => -one											#
# $f29 => zero											#
# $f30 => one											#
# $f31 => e											#
# $f14 to $f26 => temp values									#
#################################################################################################


main:
		#Allocate memory and generate coeff
		jal	alloc_constants
		jal	alloc_heap_memory
		jal	alloc_array
		jal	alloc_taylor_coeff
		
		#Print taylor coeffs
		addi	$a0, $s0, 0
		addi	$a1, $s2, 0
		jal	print_array.s
		
		#Print array to compute
		jal	get_address_of_first_array
		addi	$a0, $v0, 0
		addi	$a1, $s3, 0
		jal	print_array.s
		
		#Calculate sigmoid of array
		jal	get_address_of_first_array
		addi	$a0, $v0, 0
		jal	get_address_of_second_array
		addi	$a1, $v0, 0
		addi	$a2, $s3, 0
		jal	sigmoid_array.s	
		
		#Print sigmoid_array result
		jal	get_address_of_second_array
		addi	$a0, $v0, 0
		addi	$a1, $s3, 0
		jal	print_array.s
		
		li	$v0, 10
		syscall

#################################################################################################
# alloc_constants										#
#################################################################################################
# Allocate in registers the previously defined constants as specified in s/f registers map	#
#												#
# Parameters:											#
#												#
# Returns:											#
#												#
#################################################################################################

alloc_constants:
		#s registers
		lw	$s1, one
		lw	$s2, precision
		lw	$s3, size_of_array
		lw	$s4, neg_one
		#f registers
		l.s	$f29, zero.s
		l.s	$f30, one.s
		l.s	$f31, e.s
		
		jr	$ra
		
#################################################################################################
# alloc_heap_memory										#
#################################################################################################
# Allocate in Heap taylor coefficients and array to compute as specified in Heap Map		#
#												#
# Parameters:											#
#												#
# Returns:											#
#												#	
#################################################################################################
		
alloc_heap_memory:
		#Get precision + size_of_array + size_of_array
		add	$t0, $s2, $s3
		addi	$t0, $s3, 0
		#Allocate $t0 * 4 bytes
		sll	$t0, $t0, 2
		addi	$s0, $gp, 0
		add	$gp, $gp, $t0
		
		jr	$ra
		
#################################################################################################
# alloc_array											#
#################################################################################################
# Allocate in the Heap the array to compute from the .data as specified in the Heap Map		#
#												#
# Parameters:											#
#												#
# Returns:											#
#												#
#################################################################################################

alloc_array:		
		#Save size_of_array in $t0
		lw	$t0, size_of_array
		
		#Create counter_loop
		li	$t1, 0
		#Create counter_array_data
		li	$t2, 0
		#Create counter_array_heap
		li	$t3, 0
		#Starting position of array_data
		la	$t4, array
		
		#Starting position of array_heap
		#precision * 4 + $s0
		addi	$t5, $s2, 0
		sll	$t5, $t5, 2
		add	$t5, $t5, $s0

alloc_array_loop:
		#If counter_loop == size_of_array
		beq	$t1, $t0, alloc_array_loop_end
		#Else:
		
		#Get current position in the array_data
		addi	$t2, $t1, 0
		sll	$t2, $t2, 2
		add	$t2, $t2, $t4
		
		#Get current position in the array_heap
		addi	$t3, $t1, 0
		sll	$t3, $t3, 2
		add	$t3, $t3, $t5
		
		#Load the value of the array_data into $f15
		l.s	$f15, 0($t2)
		#Store the value of $f15 into current array_heap position
		s.s	$f15, 0($t3)
		
		#Increment counter_loop and recall loop
		addi	$t1, $t1, 1
		j	alloc_array_loop
		
alloc_array_loop_end:
		jr	$ra

#################################################################################################
# get_address_of_first_array									#
#################################################################################################
# Get address of the first array to compute as specified in the Heap Map			#
#												#
# Parameters:											#
#												#
# Returns:											#
# 	$v0: the address of the first array							#
#################################################################################################

get_address_of_first_array:
		#Load the allocated heap starting position in $v0
		addi	$v0, $s0, 0
		#Get offset caused by taylor coeffs
		addi	$t0, $s2, 0
		sll	$t0, $t0, 2
		#Add offset to base address
		add	$v0, $v0, $t0
		
		jr	$ra
		
#################################################################################################
# get_address_of_second_array									#
#################################################################################################
# Get address of the second array to compute as specified in the Heap Map			#
#												#
# Parameters:											#
#												#
# Returns:											#
# 	$v0: the address of the second array							#
#################################################################################################
		
get_address_of_second_array:
		#Store the current $ra in stack
		addi $sp, $sp, -4
		sw $ra, 0($sp)

		#Get address of first array
		jal	get_address_of_first_array
		#Calculate offset caused by the first array size
		addi	$t0, $s3, 0
		sll	$t0, $t0, 2
		#Add the offset
		add	$v0, $v0, $t0
		
		#Load the old $ra and return
		lw 	$ra, 0($sp)
   		addi 	$sp, $sp, 4
		jr	$ra

#################################################################################################
# alloc_taylor_coeff										#
#################################################################################################
# Takes the precision const and allocates in heap (precision) taylor coefficients		#
#												#
# Parameters:											#
#												#
# Returns:											#
#												#	
#################################################################################################

alloc_taylor_coeff:
		#TODO: Should add error checking
		
		#Store the current $ra in stack
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		
		#Save precision in $t7
		addi	$t7, $s2, 0
		#Create counter_loop
		li	$t8, 0
		#Create counter_array
		li	$t9, 0
		
alloc_taylor_coeff_loop:
		#If counter_loop == precision
		beq	$t8, $t7, alloc_taylor_coeff_loop_end
		#Else:
		
		#Get current position in the heap
		addi	$t9, $t8, 0
		sll	$t9, $t9, 2
		add	$t9, $t9, $s0

		#Get factorial of counter_loop
		#Set the param
		addi	$a0, $t8, 0
		#Call the function
		jal	factorial_minus_1
		
		#Store the float from $f0 to heap
		#Move $f0 to $t0
		mfc1	$t0, $f0
		#Store $t0
		sw	$t0, 0($t9)
		
		#Increment counter and recall loop
		addi	$t8, $t8, 1
		j	alloc_taylor_coeff_loop
		
alloc_taylor_coeff_loop_end:
		#Load the old $ra and return
		lw 	$ra, 0($sp)
   		addi 	$sp, $sp, 4
		jr	$ra
		
#################################################################################################
# factorial											#
#################################################################################################
# Takes an integer and computes n!								#
#												#
# Parameters:											#
#	$a0: an integer										#
#												#
# Returns:											#
#	$v0: n!											#	
#################################################################################################

factorial:
		#If $a0 is equal to zero => 1
		beq	$a0, $zero, factorial_return_1
		#Else:
		#Load the putput with 1
		li	$v0, 1
		#Create counter_loop
		li	$t0, 1
factorial_loop:
		#If the counter is greater than $a0
		bgt	$t0, $a0, factorial_loop_end
		#Else:
		#Multiply $vo with the counter
		mul	$v0, $v0, $t0
		#Increase the counter_loop
		addi	$t0, $t0, 1
		j	factorial_loop
		
factorial_loop_end:
		jr	$ra
		
factorial_return_1:
		li	$v0, 1
		jr	$ra
		
#################################################################################################
# factorial_minus_1										#
#################################################################################################
# Takes an integer and computes 1/(n!)								#
#												#
# Parameters:											#
#	$a0: an integer										#
#												#
# Returns:											#
#	$f0: 1/(n!)										#
#################################################################################################

factorial_minus_1:
		#Store this function's $ra in stack
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		
		#Get factorial of n
		jal	factorial
		#Store the factorial from $v0
		addi	$t0, $v0, 0
		#Move $t0 to $f15 of the coproc1
		mtc1	$t0, $f15
		#Convert it to float
		cvt.s.w	$f15, $f15
		#In $f0 save (1.0 / $f15)
		div.s	$f0, $f30, $f15
		
		#Load the old $ra and return
		lw 	$ra, 0($sp)
   		addi 	$sp, $sp, 4
		jr	$ra
		
#################################################################################################
# pow.s												#
#################################################################################################
# Take a float and an integer and return (float) ^ (int)					#
#												#
# Parameters:											#
#	$f1: a single percision float								#
#	$a0: an integer										#
#												#
# Returns:											#
#	$f0: ($f1)^$a0										#
#################################################################################################

pow.s:
		#If $a0 == 0
		beq	$a0, $zero, pow.s_return_1
		#Else if $a0 < 0:
		blt	$a0, $zero, pow.s_neg
		#Create a counter_loop
		li	$t0, 2
		#Assign $f1 to $f0
		add.s	$f0, $f1, $f29
pow.s_loop:
		#If counter_loop > $a0:
		bgt	$t0, $a0, pow.s_loop_end
		#Else:
		#Mul $f0 by $f0 and store it in $f0
		mul.s	$f0, $f0, $f0
		#Increment counter_loop and recall loop
		addi	$t0, $t0, 1
		j	pow.s_loop
		
pow.s_loop_end:
		jr	$ra
		
pow.s_return_1:
		l.s	$f0, one.s
		jr	$ra

pow.s_neg:
		#Store this function's $ra in stack
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		
		#Change sign of $a0
		mul	$a0, $a0, $s4
		#Recall pow.s with the new $a0
		jal	pow.s
		
		#Divide 1 by the result of pow.s
		div.s	$f0, $f30, $f0
		
		#Load the old $ra and return
		lw 	$ra, 0($sp)
   		addi 	$sp, $sp, 4
		jr	$ra
		
#################################################################################################
# centered_pow.s										#
#################################################################################################
# Take two float (x, x0), one int and calculates (x - x0)^(int)					#
#												#
# Parameters:											#
#	$f1: a single precision float => x							#
#	$f2: a single precision float => center (x0)						#
#	$a0: an integer										#
#												#
# Returns:											#
#	$f0: ($f1 - $f2)^$a0									#
#################################################################################################

centered_pow.s:
		#Store this function's $ra in stack
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		
		#Get ($f1 - $f2) ^ $a0
		#Store $f1 - $f2 in $f1
		sub.s	$f1, $f1, $f2
		#Get the new $f1 ^ $a0
		jal	pow.s
		
		#The result is already in $f0 so:		
		#Load the old $ra and return
		lw 	$ra, 0($sp)
   		addi 	$sp, $sp, 4
		jr	$ra
		
#################################################################################################
# taylor_of_exp.s										#
#################################################################################################
# Takes one float (x) and returns an approximation of e^x					#
#												#
# Parameters:											#
#	$f1: a single precision float => x							#
#												#
# Returns:											#
#	$f0: e^($f1)										#
#												#
#	or											#
#	$f0: taylor series with precision number of factors and centered around x0		#
#	Where x0 = floor of x									#
#################################################################################################

taylor_of_exp.s:
		#Store $f1 inside $f15
		add.s	$f15, $f1, $f29
		#Store floor of $f1 inside $f16 (x0)
		floor.w.s	$f16, $f1
		#Store the integer to $t9
		mfc1		$t9, $f16
		#Convert it back to float
		cvt.s.w		$f16, $f16
		
		#Objective: 	series of beta=0 to beta=precision - 1 of (alpha_of_beta) * e^(x0) * (x - x0)^(beta)
		
		#Store this function's $ra in stack
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		
		#Get e^(x0) and store it inside $f17
		add.s	$f1, $f31, $f29
		addi	$a0, $t9, 0
		jal	pow.s
		add.s	$f17, $f0, $f29
		
		#Save precision in %t7
		addi	$t7, $s2, 0		
		#Create counter_loop
		li	$t8, 0
		#Create counter_array
		li	$t9, 0
		
		#Set $f0 to 0
		add.s	$f0, $f29, $f29
		
taylor_of_exp.s_loop:
		#If counter_loop == precision
		beq	$t8, $t7, taylor_of_exp.s_loop_end
		#Else:
		
		#Get current position in the heap
		addi	$t9, $t8, 0
		sll	$t9, $t9, 2
		add	$t9, $t9, $s0

		#Store inside $f18 e^x0
		add.s	$f18, $f17, $f29
		
		#Store the current taylor coeff inside $f20
		l.s	$f20, 0($t9)
		#Mul $f20 by $f18 and store it inside $f18 (alpha * e^(x0))
		mul.s	$f18, $f20, $f18
		
		#Store centered_pow.s inside $f19
		#Set parameters
		add.s	$f1, $f15, $f29
		add.s	$f2, $f16, $f29
		addi	$a0, $t8, 0
		#Get centered_pow.s
		jal	centered_pow.s
		add.s	$f20, $f0, $f29
		
		#Mul $f20 by $f18 and store it inside $f18 (alpha_of_beta * e^(x0) * (x - x0)^(beta))
		mul.s	$f18, $f20, $f18
		
		#Add $f18 to $f0 ($f0 = $f0 + beta order of approx)
		add.s	$f21, $f21, $f18
		
		#Increment counter and recall loop
		addi	$t8, $t8, 1
		j	taylor_of_exp.s_loop
		
taylor_of_exp.s_loop_end:
		#Move $f21 to $f0
		add.s	$f0, $f21, $f29
		#Clear $f21
		add.s	$f21, $f29, $f29

		#Load the old $ra and return
		lw 	$ra, 0($sp)
   		addi 	$sp, $sp, 4
		jr	$ra

#################################################################################################
# sigmoid.s											#
#################################################################################################
# Takes one float (x) and returns an approximation of the sigmoid(x)				#
#												#
# Parameters:											#
#	$f1: a single precision float								#
#												#
# Returns:											#
#	$f0: sigmoid($f1)									#
#################################################################################################

sigmoid.s:
		#Store this function's $ra in stack
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		
		#Change sign of $f1
		neg.s	$f1, $f1
		
		#Get approximation of exp($f1) (i.e.: e^(-x)) and store it inside $f15
		#The parameters are already in the right place
		jal	taylor_of_exp.s
		add.s	$f15, $f0, $f29
		
		#Add 1.0 to $f15
		add.s	$f15, $f15, $f30
		
		#Divide 1 / ($f15) (i.e.: 1/ (1 + e^(-x)))
		div.s	$f0, $f30, $f15
		
		#Load the old $ra and return
		lw 	$ra, 0($sp)
   		addi 	$sp, $sp, 4
		jr	$ra
		
#################################################################################################
# sigmoid_array.s										#
#################################################################################################
# Takes the address of the array, the address of a second array of the same size, its size	#
# and assign the sigmoid of the first array (element-wise) to the second array			#
#												#
# Parameters:											#
#	$a0: address first array								#
#	$a1: address of second array								#
#	$a2: size of array									#
#												#
# Returns:											#
#												#
#################################################################################################

sigmoid_array.s:
		#Store this function's $ra in stack
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		
		#Save size_of_array in $t1
		addi	$t1, $a2, 0
		#Create counter_loop
		li	$t2, 0
		#Create counter_array
		li	$t3, 0
		#Create counter_array_output
		li	$t4, 0
		
		#Save starting position of the first array (source)
		addi	$t5, $a0, 0
		#sll	$t5, $t5, 2
		#Save starting position of the second array (destination)
		addi	$t6, $a1, 0
		#add	$t6, $t6, $a2
		#sll	$t6, $t6, 2
		
sigmoid_array.s_loop:
		#If counter_loop == size_of_array
		beq	$t2, $t1, sigmoid_array.s_loop_end
		#Else:
		
		#Get current position in the first array_heap
		addi	$t3, $t2, 0
		sll	$t3, $t3, 2
		add	$t3, $t3, $t5
		
		#Get current position in the second array_heap
		addi	$t4, $t2, 0
		sll	$t4, $t4, 2
		add	$t4, $t4, $t6
		
		#Get sigmoid of current element
		#Get value from the array and store it inside $f1
		l.s	$f1, 0($t3)
		jal	sigmoid.s
		#Store the result inside the second array 
		s.s	$f0, 0($t4)
		
		#Increment counter_loop and recall loop
		addi	$t2, $t2, 1
		j	sigmoid_array.s_loop
		
sigmoid_array.s_loop_end:
		#Load the old $ra and return
		lw 	$ra, 0($sp)
   		addi 	$sp, $sp, 4
		jr	$ra
		
#################################################################################################
# print_array.s											#
#################################################################################################
# Takes the address of the array, its size and prints the stored values				#
#												#
# Parameters:											#
#	$a0: address of the array								#
#	$a1: size of the array									#
#												#
# Returns:											#
#												#
#################################################################################################


print_array.s:		
		#Save size_of_array in $t0
		addi	$t0, $a1, 0
		#Create counter_loop
		li	$t1, 0
		#Create counter_array
		li	$t2, 0

print_array.s_loop:
		#If counter_loop == size_of_array
		beq	$t1, $t0, print_array.s_loop_end
		#Else:
		
		#Get current position in the heap
		addi	$t2, $t1, 0
		sll	$t2, $t2, 2
		add	$t2, $t2, $a0
		
		#Set syscall instruction for float print
		li	$v0, 2
		#Load the value to $f12
		l.s	$f12, 0($t2)
		#Execute print
		syscall
		
		#Store the original $a0 in stack
		addi $sp, $sp, -4
		sw $a0, 0($sp)
		
		#Print new-line
		li	$v0, 4
		la	$a0, nl
		syscall
		
		#Restore original $a0
		lw 	$a0, 0($sp)
   		addi 	$sp, $sp, 4
		
		#Increment counter_loop and recall loop
		addi	$t1, $t1, 1
		j	print_array.s_loop
		
print_array.s_loop_end:
		jr	$ra
