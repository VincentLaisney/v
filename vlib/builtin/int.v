// Copyright (c) 2019-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module builtin

//
// ----- value to string functions -----
//

type u8 = byte
type i32 = int

// ptr_str returns the address of `ptr` as a `string`.
pub fn ptr_str(ptr voidptr) string {
	buf1 := u64(ptr).hex()
	return buf1
}

pub fn (x isize) str() string {
	return i64(x).str()
}

pub fn (x usize) str() string {
	return u64(x).str()
}

// pub fn (x size_t) str() string {
// 	return u64(x).str()
// }

pub fn (cptr &char) str() string {
	return u64(cptr).hex()
}

const (
	// digit pairs in reverse order
	digit_pairs = '00102030405060708090011121314151617181910212223242526272829203132333435363738393041424344454647484940515253545556575859506162636465666768696071727374757677787970818283848586878889809192939495969798999'
)

// This implementation is the quickest with gcc -O2
// str_l returns the string representation of the integer nn with max chars.
[direct_array_access; inline]
fn (nn int) str_l(max int) string {
	unsafe {
		mut n := i64(nn)
		mut d := 0
		if n == 0 {
			return '0'
		}

		mut is_neg := false
		if n < 0 {
			n = -n
			is_neg = true
		}
		mut index := max
		mut buf := malloc_noscan(max + 1)
		buf[index] = 0
		index--

		for n > 0 {
			n1 := int(n / 100)
			// calculate the digit_pairs start index
			d = ((int(n) - (n1 * 100)) << 1)
			n = n1
			buf[index] = digit_pairs.str[d]
			index--
			d++
			buf[index] = digit_pairs.str[d]
			index--
		}
		index++
		// remove head zero
		if d < 20 {
			index++
		}
		// Prepend - if it's negative
		if is_neg {
			index--
			buf[index] = `-`
		}
		diff := max - index
		vmemmove(buf, buf + index, diff + 1)
		/*
		// === manual memory move for bare metal ===
		mut c:= 0
		for c < diff {
			buf[c] = buf[c+index]
			c++
		}
		buf[c] = 0
		*/
		return tos(buf, diff)

		// return tos(memdup(&buf[0] + index, (max - index)), (max - index))
	}
}

// str returns the value of the `i8` as a `string`.
// Example: assert i8(-2).str() == '-2'
pub fn (n i8) str() string {
	return int(n).str_l(5)
}

// str returns the value of the `i16` as a `string`.
// Example: assert i16(-20).str() == '-20'
pub fn (n i16) str() string {
	return int(n).str_l(7)
}

// str returns the value of the `u16` as a `string`.
// Example: assert u16(20).str() == '20'
pub fn (n u16) str() string {
	return int(n).str_l(7)
}

// str returns the value of the `int` as a `string`.
// Example: assert int(-2020).str() == '-2020'
pub fn (n int) str() string {
	return n.str_l(12)
}

// str returns the value of the `u32` as a `string`.
// Example: assert u32(20000).str() == '20000'
[direct_array_access; inline]
pub fn (nn u32) str() string {
	unsafe {
		mut n := nn
		mut d := u32(0)
		if n == 0 {
			return '0'
		}
		max := 12
		mut buf := malloc_noscan(max + 1)
		mut index := max
		buf[index] = 0
		index--
		for n > 0 {
			n1 := n / u32(100)
			d = ((n - (n1 * u32(100))) << u32(1))
			n = n1
			buf[index] = digit_pairs[d]
			index--
			d++
			buf[index] = digit_pairs[d]
			index--
		}
		index++
		// remove head zero
		if d < u32(20) {
			index++
		}
		diff := max - index
		vmemmove(buf, buf + index, diff + 1)
		return tos(buf, diff)

		// return tos(memdup(&buf[0] + index, (max - index)), (max - index))
	}
}

// str returns the value of the `int_literal` as a `string`.
[inline]
pub fn (n int_literal) str() string {
	return i64(n).str()
}

// str returns the value of the `i64` as a `string`.
// Example: assert i64(-200000).str() == '-200000'
[direct_array_access; inline]
pub fn (nn i64) str() string {
	unsafe {
		mut n := nn
		mut d := i64(0)
		if n == 0 {
			return '0'
		}
		max := 20
		mut buf := malloc_noscan(max + 1)
		mut is_neg := false
		if n < 0 {
			n = -n
			is_neg = true
		}
		mut index := max
		buf[index] = 0
		index--
		for n > 0 {
			n1 := n / i64(100)
			d = ((n - (n1 * i64(100))) << i64(1))
			n = n1
			buf[index] = digit_pairs[d]
			index--
			d++
			buf[index] = digit_pairs[d]
			index--
		}
		index++
		// remove head zero
		if d < i64(20) {
			index++
		}
		// Prepend - if it's negative
		if is_neg {
			index--
			buf[index] = `-`
		}
		diff := max - index
		vmemmove(buf, buf + index, diff + 1)
		return tos(buf, diff)
		// return tos(memdup(&buf[0] + index, (max - index)), (max - index))
	}
}

// str returns the value of the `u64` as a `string`.
// Example: assert u64(2000000).str() == '2000000'
[direct_array_access; inline]
pub fn (nn u64) str() string {
	unsafe {
		mut n := nn
		mut d := u64(0)
		if n == 0 {
			return '0'
		}
		max := 20
		mut buf := malloc_noscan(max + 1)
		mut index := max
		buf[index] = 0
		index--
		for n > 0 {
			n1 := n / 100
			d = ((n - (n1 * 100)) << 1)
			n = n1
			buf[index] = digit_pairs[d]
			index--
			d++
			buf[index] = digit_pairs[d]
			index--
		}
		index++
		// remove head zero
		if d < 20 {
			index++
		}
		diff := max - index
		vmemmove(buf, buf + index, diff + 1)
		return tos(buf, diff)
		// return tos(memdup(&buf[0] + index, (max - index)), (max - index))
	}
}

// str returns the value of the `bool` as a `string`.
// Example: assert (2 > 1).str() == 'true'
pub fn (b bool) str() string {
	if b {
		return 'true'
	}
	return 'false'
}

//
// ----- value to hex string functions -----
//

// u64_to_hex converts the number `nn` to a (zero padded if necessary) hexadecimal `string`.
[direct_array_access; inline]
fn u64_to_hex(nn u64, len byte) string {
	mut n := nn
	mut buf := [17]byte{}
	buf[len] = 0
	mut i := 0
	for i = len - 1; i >= 0; i-- {
		d := byte(n & 0xF)
		buf[i] = if d < 10 { d + `0` } else { d + 87 }
		n = n >> 4
	}
	return unsafe { tos(memdup(&buf[0], len + 1), len) }
}

// u64_to_hex_no_leading_zeros converts the number `nn` to hexadecimal `string`.
[direct_array_access; inline]
fn u64_to_hex_no_leading_zeros(nn u64, len byte) string {
	mut n := nn
	mut buf := [17]byte{}
	buf[len] = 0
	mut i := 0
	for i = len - 1; i >= 0; i-- {
		d := byte(n & 0xF)
		buf[i] = if d < 10 { d + `0` } else { d + 87 }
		n = n >> 4
		if n == 0 {
			break
		}
	}
	res_len := len - i
	return unsafe { tos(memdup(&buf[i], res_len + 1), res_len) }
}

// hex returns the value of the `byte` as a hexadecimal `string`.
// Note that the output is zero padded for values below 16.
// Example: assert byte(2).hex() == '02'
// Example: assert byte(15).hex() == '0f'
// Example: assert byte(255).hex() == 'ff'
pub fn (nn byte) hex() string {
	if nn == 0 {
		return '00'
	}
	return u64_to_hex(nn, 2)
}

// hex returns the value of the `i8` as a hexadecimal `string`.
// Note that the output is zero padded for values below 16.
// Example: assert i8(8).hex() == '08'
// Example: assert i8(10).hex() == '0a'
// Example: assert i8(15).hex() == '0f'
pub fn (nn i8) hex() string {
	if nn == 0 {
		return '00'
	}
	return u64_to_hex(u64(nn), 2)
	//return byte(nn).hex()
}

// hex returns the value of the `u16` as a hexadecimal `string`.
// Note that the output is ***not*** zero padded.
// Example: assert u16(2).hex() == '2'
// Example: assert u16(200).hex() == 'c8'
pub fn (nn u16) hex() string {
	if nn == 0 {
		return '0'
	}
	return u64_to_hex_no_leading_zeros(nn, 4)
}

// hex returns the value of the `i16` as a hexadecimal `string`.
// Note that the output is ***not*** zero padded.
// Example: assert i16(2).hex() == '2'
// Example: assert i16(200).hex() == 'c8'
pub fn (nn i16) hex() string {
	return u16(nn).hex()
}

// hex returns the value of the `u32` as a hexadecimal `string`.
// Note that the output is ***not*** zero padded.
// Example: assert u32(2).hex() == '2'
// Example: assert u32(200).hex() == 'c8'
pub fn (nn u32) hex() string {
	if nn == 0 {
		return '0'
	}
	return u64_to_hex_no_leading_zeros(nn, 8)
}

// hex returns the value of the `int` as a hexadecimal `string`.
// Note that the output is ***not*** zero padded.
// Example: assert int(2).hex() == '2'
// Example: assert int(200).hex() == 'c8'
pub fn (nn int) hex() string {
	return u32(nn).hex()
}

// hex2 returns the value of the `int` as a `0x`-prefixed hexadecimal `string`.
// Note that the output after `0x` is ***not*** zero padded.
// Example: assert int(8).hex2() == '0x8'
// Example: assert int(15).hex2() == '0xf'
// Example: assert int(18).hex2() == '0x12'
pub fn (n int) hex2() string {
	return '0x' + n.hex()
}

// hex returns the value of the `u64` as a hexadecimal `string`.
// Note that the output is ***not*** zero padded.
// Example: assert u64(2).hex() == '2'
// Example: assert u64(2000).hex() == '7d0'
pub fn (nn u64) hex() string {
	if nn == 0 {
		return '0'
	}
	return u64_to_hex_no_leading_zeros(nn, 16)
}

// hex returns the value of the `i64` as a hexadecimal `string`.
// Note that the output is ***not*** zero padded.
// Example: assert i64(2).hex() == '2'
// Example: assert i64(-200).hex() == 'ffffffffffffff38'
// Example: assert i64(2021).hex() == '7e5'
pub fn (nn i64) hex() string {
	return u64(nn).hex()
}

// hex returns the value of the `int_literal` as a hexadecimal `string`.
// Note that the output is ***not*** zero padded.
pub fn (nn int_literal) hex() string {
	return u64(nn).hex()
}

// hex returns the value of the `voidptr` as a hexadecimal `string`.
// Note that the output is ***not*** zero padded.
pub fn (nn voidptr) str() string {
	return u64(nn).hex()
}

// hex returns the value of the `byteptr` as a hexadecimal `string`.
// Note that the output is ***not*** zero padded.
// pub fn (nn byteptr) str() string {
pub fn (nn byteptr) str() string {
	return u64(nn).hex()
}

pub fn (nn byte) hex_full() string {
	return u64_to_hex(u64(nn), 2)
}

pub fn (nn i8) hex_full() string {
	return u64_to_hex(u64(nn), 2)
}

pub fn (nn u16) hex_full() string {
	return u64_to_hex(u64(nn), 4)
}

pub fn (nn i16) hex_full() string {
	return u64_to_hex(u64(nn), 4)
}

pub fn (nn u32) hex_full() string {
	return u64_to_hex(u64(nn), 8)
}

pub fn (nn int) hex_full() string {
	return u64_to_hex(u64(nn), 8)
}

pub fn (nn i64) hex_full() string {
	return u64_to_hex(u64(nn), 16)
}

pub fn (nn voidptr) hex_full() string {
	return u64_to_hex(u64(nn), 16)
}

pub fn (nn int_literal) hex_full() string {
	return u64_to_hex(u64(nn), 16)
}

// hex_full returns the value of the `u64` as a *full* 16-digit hexadecimal `string`.
// Example: assert u64(2).hex_full() == '0000000000000002'
// Example: assert u64(255).hex_full() == '00000000000000ff'
pub fn (nn u64) hex_full() string {
	return u64_to_hex(nn, 16)
}

// str returns the contents of `byte` as a zero terminated `string`.
// Example: assert byte(111).str() == '111'
pub fn (b byte) str() string {
	return int(b).str_l(7)
}

// ascii_str returns the contents of `byte` as a zero terminated ASCII `string` character.
// Example: assert byte(97).ascii_str() == 'a'
pub fn (b byte) ascii_str() string {
	mut str := string{
		str: unsafe { malloc_noscan(2) }
		len: 1
	}
	unsafe {
		str.str[0] = b
		str.str[1] = 0
	}
	// println(str)
	return str
}

// str_escaped returns the contents of `byte` as an escaped `string`.
// Example: assert byte(0).str_escaped() == r'`\0`'
pub fn (b byte) str_escaped() string {
	str := match b {
		0 { r'`\0`' }
		7 { r'`\a`' }
		8 { r'`\b`' }
		9 { r'`\t`' }
		10 { r'`\n`' }
		11 { r'`\v`' }
		12 { r'`\f`' }
		13 { r'`\r`' }
		27 { r'`\e`' }
		32...126 { b.ascii_str() }
		else { '0x' + b.hex() }
	}
	return str
}
