module builtin

import strings
// used to generate JS throw statements.

pub fn js_throw(s any) {
	#throw s
}

#let globalPrint;
$if js_freestanding {
	#globalPrint = globalThis.print
}

pub fn println(s string) {
	$if js_freestanding {
		#globalPrint(s.str)
	} $else {
		#console.log(s.str)
	}
}

pub fn print(s string) {
	$if js_node {
		#$process.stdout.write(s.str)
	} $else {
		panic('Cannot `print` in a browser, use `println` instead')
	}
}

pub fn eprintln(s string) {
	$if js_freestanding {
		#globalPrint(s.str)
	} $else {
		#console.error(s.str)
	}
}

pub fn eprint(s string) {
	$if js_node {
		#$process.stderr.write(s.str)
	} $else {
		panic('Cannot `eprint` in a browser, use `println` instead')
	}
}

// Exits the process in node, and halts execution in the browser
// because `process.exit` is undefined. Workaround for not having
// a 'real' way to exit in the browser.
pub fn exit(c int) {
	JS.process.exit(c)
	js_throw('exit($c)')
}

fn opt_ok(data voidptr, option Option) {
	#option.state = 0
	#option.err = none__
	#option.data = data
}

pub fn unwrap(opt string) string {
	mut o := Option{}
	#o = opt
	if o.state != 0 {
		js_throw(o.err)
	}

	mut res := ''
	#res = opt.data

	return res
}

pub fn (r rune) str() string {
	res := ''
	mut sb := strings.new_builder(5)
	#res.str = r.valueOf().toString()
	sb.write_string(res)

	return sb.str()
}
