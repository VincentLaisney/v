module big

import math.bits

// suppose operand_a bigger than operand_b and both not null.
// Both quotient and remaider are allocated but of length 0
fn divide_array_by_array_newton(operand_a []u32, operand_b []u32, mut quotient []u32, mut remainder []u32) {
	for index in 0 .. operand_a.len {
		remainder << operand_a[index]
	}

	len_diff := operand_a.len - operand_b.len
	assert len_diff >= 0

	// we must do in place shift and operations.
	mut divisor := []u32{cap: operand_b.len}
	for _ in 0 .. len_diff {
		divisor << u32(0)
	}
	for index in 0 .. operand_b.len {
		divisor << operand_b[index]
	}
	for _ in 0 .. len_diff + 1 {
		quotient << u32(0)
	}

	lead_zer_remainder := u32(bits.leading_zeros_32(remainder.last()))
	lead_zer_divisor := u32(bits.leading_zeros_32(divisor.last()))
	bit_offset := (u32(32) * u32(len_diff)) + (lead_zer_divisor - lead_zer_remainder)

	// align
	if lead_zer_remainder < lead_zer_divisor {
		lshift_in_place(mut divisor, lead_zer_divisor - lead_zer_remainder)
	} else if lead_zer_remainder > lead_zer_divisor {
		lshift_in_place(mut remainder, lead_zer_remainder - lead_zer_divisor)
	}

	assert left_align_p(divisor[divisor.len - 1], remainder[remainder.len - 1])
	for bit_idx := int(bit_offset); bit_idx >= 0; bit_idx-- {
		if greater_equal_from_end(remainder, divisor) {
			bit_set(mut quotient, bit_idx)
			subtract_in_place(mut remainder, divisor)
		}
		rshift_in_place(mut divisor, 1)
	}

	// ajust
	if lead_zer_remainder > lead_zer_divisor {
		// rshift_in_place(mut quotient, lead_zer_remainder - lead_zer_divisor)
		rshift_in_place(mut remainder, lead_zer_remainder - lead_zer_divisor)
	}
	for remainder.len > 0 && remainder.last() == 0 {
		remainder.delete_last()
	}
	for quotient.len > 0 && quotient.last() == 0 {
		quotient.delete_last()
	}
}

