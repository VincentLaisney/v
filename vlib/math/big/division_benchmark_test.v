module big

import rand
import benchmark

import gmp
import libbf.big.integer as bf

fn random_numbers(length int) (Integer, gmp.Bigint, bf.Bigint) {
	numbers := '0123456789'
	mut stri := ''
	for _ in 0 .. length {
		i := rand.intn(10)
		nr := numbers[i]
		stri = stri + nr.ascii_str()
	}
	res1 := integer_from_string(stri) or { panic('error in random_numbers') }
	res2 := gmp.from_str(stri) or { panic('error in random_numbers') }
	res3 := bf.from_str(stri) or { panic('error in random_numbers') }
	return res1, res2, res3
}

fn bench_work_v(a_operands []Integer, b_operands []Integer, fun fn (Integer, Integer) (Integer, Integer)) {
	for i, a in a_operands {
		for j, b in b_operands {
			q, r := fun(a, b)
		}
	}
}

fn bench_work_gmp(a_operands []gmp.Bigint, b_operands []gmp.Bigint) {
	for i, a in a_operands {
		for j, b in b_operands {
			q, r := gmp.divmod(a, b)
		}
	}
}

fn bench_work_libbf(a_operands []bf.Bigint, b_operands []bf.Bigint) {
	for i, a in a_operands {
		for j, b in b_operands {
			q, r := bf.divrem(a, b)
		}
	}
}

fn div_mod(a Integer, b Integer) (Integer, Integer) {
	return a.div_mod(b)
}

// fn div_mod_binary_wrap(a Integer, b Integer) (Integer, Integer) {
// 	return a.div_mod_binary(b)
// }

fn test_bench() {
	mut rand_a_operand := []Integer{}
	mut rand_b_operand := []Integer{}
	mut gmp_a_operand := []gmp.Bigint{}
	mut gmp_b_operand := []gmp.Bigint{}
	mut libbf_a_operand := []bf.Bigint{}
	mut libbf_b_operand := []bf.Bigint{}
	length := 15
	for _ in 0 .. 100 {
		a_operand, a_gmp, a_libbf := random_numbers(length)
		b_operand, b_gmp, b_libbf := random_numbers(length / 2)
		rand_a_operand << a_operand
		rand_b_operand << b_operand
		gmp_a_operand << a_gmp
		gmp_b_operand << b_gmp
		libbf_a_operand << a_libbf
		libbf_b_operand << b_libbf
	}

	// From Benchmark.README.md
	mut b := benchmark.start()
	bench_work_v(rand_a_operand, rand_b_operand, div_mod)
	b.measure('original division')
	bench_work_gmp(gmp_a_operand, gmp_b_operand)
	b.measure('gmp division')
	bench_work_libbf(libbf_a_operand, libbf_b_operand)
	b.measure('libbf division')
}
