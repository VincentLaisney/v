// does not do anything yet
// just test that the 128 types are recognized

pub fn addition(a u128, b u128, c f128) u128 {
	return a
}

pub fn main() {
	a := u128(1)
	b := u128(2)
	c := a + b
	d := i128(-10)
	e := i128(43)
	f := d * e
	g := f128(45.0)
	h := g * g
//	println(c)  // could not generate string method u128_str for type 'u128'
}
