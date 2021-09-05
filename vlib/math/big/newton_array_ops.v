module big

// import math.bits

// suppose operand_a bigger than operand_b and both not null.
// Both quotient and remaider are allocated but of length 0
fn divide_array_by_array_newton(operand_a []u32, operand_b []u32, mut quotient []u32, mut remainder []u32) {
	// for index in 0 .. operand_a.len {
	// 	remainder << operand_a[index]
	// }

	// len_diff := operand_a.len - operand_b.len
	// assert len_diff >= 0

	// // we must do in place shift and operations.
	// mut divisor := []u32{cap: operand_b.len}
	// for _ in 0 .. len_diff {
	// 	divisor << u32(0)
	// }
	// for index in 0 .. operand_b.len {
	// 	divisor << operand_b[index]
	// }
	// // estimate bit length of result and build it (from remainder [== dividend])
	// remainder_bit_len := remainder.len * 32 + leading_zeros_32(remainder.last())
	// divisor_bit_len := divisor.len * 32 + leading_zeros_32(divisor.last())
	// quotient_bit_len := remainder_bit_len - remainder_bit_len
	// assert quotient_bit_len >= 0

	// for i in 0 .. (quotient_bit_len / 32) + 1 {
	// 	quotient << remainder[i]
	// }

	// mask := 1 << (quotient_bit_len % 32) - 1
	// quotient.last() = quotient.last() & mask

	// // tentative multiplicattion and difference
	// difference := 

	// // ajust result with the differential


	// for remainder.len > 0 && remainder.last() == 0 {
	// 	remainder.delete_last()
	// }
	// for quotient.len > 0 && quotient.last() == 0 {
	// 	quotient.delete_last()
	// }
}

