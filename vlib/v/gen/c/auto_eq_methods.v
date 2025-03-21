// Copyright (c) 2019-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license that can be found in the LICENSE file.
module c

import strings
import v.ast

fn (mut g Gen) gen_sumtype_equality_fn(left_type ast.Type) string {
	left := g.unwrap(left_type)
	ptr_styp := g.typ(left.typ.set_nr_muls(0))
	if ptr_styp in g.sumtype_fn_definitions {
		return ptr_styp
	}
	g.sumtype_fn_definitions << ptr_styp
	info := left.sym.sumtype_info()
	g.type_definitions.writeln('static bool ${ptr_styp}_sumtype_eq($ptr_styp a, $ptr_styp b); // auto')

	mut fn_builder := strings.new_builder(512)
	fn_builder.writeln('static bool ${ptr_styp}_sumtype_eq($ptr_styp a, $ptr_styp b) {')
	fn_builder.writeln('\tif (a._typ != b._typ) { return false; }')
	for typ in info.variants {
		variant := g.unwrap(typ)
		fn_builder.writeln('\tif (a._typ == $variant.typ) {')
		name := '_$variant.sym.cname'
		if variant.sym.kind == .string {
			fn_builder.writeln('\t\treturn string__eq(*a.$name, *b.$name);')
		} else if variant.sym.kind == .sum_type && !typ.is_ptr() {
			eq_fn := g.gen_sumtype_equality_fn(typ)
			fn_builder.writeln('\t\treturn ${eq_fn}_sumtype_eq(*a.$name, *b.$name);')
		} else if variant.sym.kind == .struct_ && !typ.is_ptr() {
			eq_fn := g.gen_struct_equality_fn(typ)
			fn_builder.writeln('\t\treturn ${eq_fn}_struct_eq(*a.$name, *b.$name);')
		} else if variant.sym.kind == .array && !typ.is_ptr() {
			eq_fn := g.gen_array_equality_fn(typ)
			fn_builder.writeln('\t\treturn ${eq_fn}_arr_eq(*a.$name, *b.$name);')
		} else if variant.sym.kind == .array_fixed && !typ.is_ptr() {
			eq_fn := g.gen_fixed_array_equality_fn(typ)
			fn_builder.writeln('\t\treturn ${eq_fn}_arr_eq(*a.$name, *b.$name);')
		} else if variant.sym.kind == .map && !typ.is_ptr() {
			eq_fn := g.gen_map_equality_fn(typ)
			fn_builder.writeln('\t\treturn ${eq_fn}_map_eq(*a.$name, *b.$name);')
		} else if variant.sym.kind == .alias && !typ.is_ptr() {
			eq_fn := g.gen_alias_equality_fn(typ)
			fn_builder.writeln('\t\treturn ${eq_fn}_alias_eq(*a.$name, *b.$name);')
		} else if variant.sym.kind == .function {
			fn_builder.writeln('\t\treturn *((voidptr*)(*a.$name)) == *((voidptr*)(*b.$name));')
		} else {
			fn_builder.writeln('\t\treturn *a.$name == *b.$name;')
		}
		fn_builder.writeln('\t}')
	}
	fn_builder.writeln('\treturn false;')
	fn_builder.writeln('}')
	g.auto_fn_definitions << fn_builder.str()
	return ptr_styp
}

fn (mut g Gen) gen_struct_equality_fn(left_type ast.Type) string {
	left := g.unwrap(left_type)
	ptr_styp := g.typ(left.typ.set_nr_muls(0))
	fn_name := ptr_styp.replace('struct ', '')
	if fn_name in g.struct_fn_definitions {
		return fn_name
	}
	g.struct_fn_definitions << fn_name
	info := left.sym.struct_info()
	g.type_definitions.writeln('static bool ${fn_name}_struct_eq($ptr_styp a, $ptr_styp b); // auto')

	mut fn_builder := strings.new_builder(512)
	defer {
		g.auto_fn_definitions << fn_builder.str()
	}
	fn_builder.writeln('static bool ${fn_name}_struct_eq($ptr_styp a, $ptr_styp b) {')

	// overloaded
	if left.sym.has_method('==') {
		fn_builder.writeln('\treturn ${fn_name}__eq(a, b);')
		fn_builder.writeln('}')
		return fn_name
	}

	fn_builder.write_string('\treturn ')
	if info.fields.len > 0 {
		for i, field in info.fields {
			if i > 0 {
				fn_builder.write_string('\n\t\t&& ')
			}
			field_type := g.unwrap(field.typ)
			field_name := c_name(field.name)
			if field_type.sym.kind == .string {
				fn_builder.write_string('string__eq(a.$field_name, b.$field_name)')
			} else if field_type.sym.kind == .sum_type && !field.typ.is_ptr() {
				eq_fn := g.gen_sumtype_equality_fn(field.typ)
				fn_builder.write_string('${eq_fn}_sumtype_eq(a.$field_name, b.$field_name)')
			} else if field_type.sym.kind == .struct_ && !field.typ.is_ptr() {
				eq_fn := g.gen_struct_equality_fn(field.typ)
				fn_builder.write_string('${eq_fn}_struct_eq(a.$field_name, b.$field_name)')
			} else if field_type.sym.kind == .array && !field.typ.is_ptr() {
				eq_fn := g.gen_array_equality_fn(field.typ)
				fn_builder.write_string('${eq_fn}_arr_eq(a.$field_name, b.$field_name)')
			} else if field_type.sym.kind == .array_fixed && !field.typ.is_ptr() {
				eq_fn := g.gen_fixed_array_equality_fn(field.typ)
				fn_builder.write_string('${eq_fn}_arr_eq(a.$field_name, b.$field_name)')
			} else if field_type.sym.kind == .map && !field.typ.is_ptr() {
				eq_fn := g.gen_map_equality_fn(field.typ)
				fn_builder.write_string('${eq_fn}_map_eq(a.$field_name, b.$field_name)')
			} else if field_type.sym.kind == .alias && !field.typ.is_ptr() {
				eq_fn := g.gen_alias_equality_fn(field.typ)
				fn_builder.write_string('${eq_fn}_alias_eq(a.$field_name, b.$field_name)')
			} else if field_type.sym.kind == .function {
				fn_builder.write_string('*((voidptr*)(a.$field_name)) == *((voidptr*)(b.$field_name))')
			} else {
				fn_builder.write_string('a.$field_name == b.$field_name')
			}
		}
	} else {
		fn_builder.write_string('true')
	}
	fn_builder.writeln(';')
	fn_builder.writeln('}')
	return fn_name
}

fn (mut g Gen) gen_alias_equality_fn(left_type ast.Type) string {
	left := g.unwrap(left_type)
	ptr_styp := g.typ(left.typ.set_nr_muls(0))
	if ptr_styp in g.alias_fn_definitions {
		return ptr_styp
	}
	g.alias_fn_definitions << ptr_styp
	info := left.sym.info as ast.Alias
	g.type_definitions.writeln('static bool ${ptr_styp}_alias_eq($ptr_styp a, $ptr_styp b); // auto')

	mut fn_builder := strings.new_builder(512)
	fn_builder.writeln('static bool ${ptr_styp}_alias_eq($ptr_styp a, $ptr_styp b) {')
	sym := g.table.get_type_symbol(info.parent_type)
	if sym.kind == .string {
		fn_builder.writeln('\treturn string__eq(a, b);')
	} else if sym.kind == .sum_type && !left.typ.is_ptr() {
		eq_fn := g.gen_sumtype_equality_fn(info.parent_type)
		fn_builder.writeln('\treturn ${eq_fn}_sumtype_eq(a, b);')
	} else if sym.kind == .struct_ && !left.typ.is_ptr() {
		eq_fn := g.gen_struct_equality_fn(info.parent_type)
		fn_builder.writeln('\treturn ${eq_fn}_struct_eq(a, b);')
	} else if sym.kind == .array && !left.typ.is_ptr() {
		eq_fn := g.gen_array_equality_fn(info.parent_type)
		fn_builder.writeln('\treturn ${eq_fn}_arr_eq(a, b);')
	} else if sym.kind == .array_fixed && !left.typ.is_ptr() {
		eq_fn := g.gen_fixed_array_equality_fn(info.parent_type)
		fn_builder.writeln('\treturn ${eq_fn}_arr_eq(a, b);')
	} else if sym.kind == .map && !left.typ.is_ptr() {
		eq_fn := g.gen_map_equality_fn(info.parent_type)
		fn_builder.writeln('\treturn ${eq_fn}_map_eq(a, b);')
	} else if sym.kind == .function {
		fn_builder.writeln('\treturn *((voidptr*)(a)) == *((voidptr*)(b));')
	} else {
		fn_builder.writeln('\treturn a == b;')
	}
	fn_builder.writeln('}')
	g.auto_fn_definitions << fn_builder.str()
	return ptr_styp
}

fn (mut g Gen) gen_array_equality_fn(left_type ast.Type) string {
	left := g.unwrap(left_type)
	ptr_styp := g.typ(left.typ.set_nr_muls(0))
	if ptr_styp in g.array_fn_definitions {
		return ptr_styp
	}
	g.array_fn_definitions << ptr_styp
	elem := g.unwrap(left.sym.array_info().elem_type)
	ptr_elem_styp := g.typ(elem.typ)
	g.type_definitions.writeln('static bool ${ptr_styp}_arr_eq($ptr_styp a, $ptr_styp b); // auto')

	mut fn_builder := strings.new_builder(512)
	fn_builder.writeln('static bool ${ptr_styp}_arr_eq($ptr_styp a, $ptr_styp b) {')
	fn_builder.writeln('\tif (a.len != b.len) {')
	fn_builder.writeln('\t\treturn false;')
	fn_builder.writeln('\t}')
	fn_builder.writeln('\tfor (int i = 0; i < a.len; ++i) {')
	// compare every pair of elements of the two arrays
	if elem.sym.kind == .string {
		fn_builder.writeln('\t\tif (!string__eq(*(($ptr_elem_styp*)((byte*)a.data+(i*a.element_size))), *(($ptr_elem_styp*)((byte*)b.data+(i*b.element_size))))) {')
	} else if elem.sym.kind == .sum_type && !elem.typ.is_ptr() {
		eq_fn := g.gen_sumtype_equality_fn(elem.typ)
		fn_builder.writeln('\t\tif (!${eq_fn}_sumtype_eq((($ptr_elem_styp*)a.data)[i], (($ptr_elem_styp*)b.data)[i])) {')
	} else if elem.sym.kind == .struct_ && !elem.typ.is_ptr() {
		eq_fn := g.gen_struct_equality_fn(elem.typ)
		fn_builder.writeln('\t\tif (!${eq_fn}_struct_eq((($ptr_elem_styp*)a.data)[i], (($ptr_elem_styp*)b.data)[i])) {')
	} else if elem.sym.kind == .array && !elem.typ.is_ptr() {
		eq_fn := g.gen_array_equality_fn(elem.typ)
		fn_builder.writeln('\t\tif (!${eq_fn}_arr_eq((($ptr_elem_styp*)a.data)[i], (($ptr_elem_styp*)b.data)[i])) {')
	} else if elem.sym.kind == .array_fixed && !elem.typ.is_ptr() {
		eq_fn := g.gen_fixed_array_equality_fn(elem.typ)
		fn_builder.writeln('\t\tif (!${eq_fn}_arr_eq((($ptr_elem_styp*)a.data)[i], (($ptr_elem_styp*)b.data)[i])) {')
	} else if elem.sym.kind == .map && !elem.typ.is_ptr() {
		eq_fn := g.gen_map_equality_fn(elem.typ)
		fn_builder.writeln('\t\tif (!${eq_fn}_map_eq((($ptr_elem_styp*)a.data)[i], (($ptr_elem_styp*)b.data)[i])) {')
	} else if elem.sym.kind == .alias && !elem.typ.is_ptr() {
		eq_fn := g.gen_alias_equality_fn(elem.typ)
		fn_builder.writeln('\t\tif (!${eq_fn}_alias_eq((($ptr_elem_styp*)a.data)[i], (($ptr_elem_styp*)b.data)[i])) {')
	} else if elem.sym.kind == .function {
		fn_builder.writeln('\t\tif (*((voidptr*)((byte*)a.data+(i*a.element_size))) != *((voidptr*)((byte*)b.data+(i*b.element_size)))) {')
	} else {
		fn_builder.writeln('\t\tif (*(($ptr_elem_styp*)((byte*)a.data+(i*a.element_size))) != *(($ptr_elem_styp*)((byte*)b.data+(i*b.element_size)))) {')
	}
	fn_builder.writeln('\t\t\treturn false;')
	fn_builder.writeln('\t\t}')
	fn_builder.writeln('\t}')
	fn_builder.writeln('\treturn true;')
	fn_builder.writeln('}')
	g.auto_fn_definitions << fn_builder.str()
	return ptr_styp
}

fn (mut g Gen) gen_fixed_array_equality_fn(left_type ast.Type) string {
	left := g.unwrap(left_type)
	ptr_styp := g.typ(left.typ.set_nr_muls(0))
	if ptr_styp in g.array_fn_definitions {
		return ptr_styp
	}
	g.array_fn_definitions << ptr_styp
	elem_info := left.sym.array_fixed_info()
	elem := g.unwrap(elem_info.elem_type)
	size := elem_info.size
	g.type_definitions.writeln('static bool ${ptr_styp}_arr_eq($ptr_styp a, $ptr_styp b); // auto')

	mut fn_builder := strings.new_builder(512)
	fn_builder.writeln('static bool ${ptr_styp}_arr_eq($ptr_styp a, $ptr_styp b) {')
	fn_builder.writeln('\tfor (int i = 0; i < $size; ++i) {')
	// compare every pair of elements of the two fixed arrays
	if elem.sym.kind == .string {
		fn_builder.writeln('\t\tif (!string__eq(a[i], b[i])) {')
	} else if elem.sym.kind == .sum_type && !elem.typ.is_ptr() {
		eq_fn := g.gen_sumtype_equality_fn(elem.typ)
		fn_builder.writeln('\t\tif (!${eq_fn}_sumtype_eq(a[i], b[i])) {')
	} else if elem.sym.kind == .struct_ && !elem.typ.is_ptr() {
		eq_fn := g.gen_struct_equality_fn(elem.typ)
		fn_builder.writeln('\t\tif (!${eq_fn}_struct_eq(a[i], b[i])) {')
	} else if elem.sym.kind == .array && !elem.typ.is_ptr() {
		eq_fn := g.gen_array_equality_fn(elem.typ)
		fn_builder.writeln('\t\tif (!${eq_fn}_arr_eq(a[i], b[i])) {')
	} else if elem.sym.kind == .array_fixed && !elem.typ.is_ptr() {
		eq_fn := g.gen_fixed_array_equality_fn(elem.typ)
		fn_builder.writeln('\t\tif (!${eq_fn}_arr_eq(a[i], b[i])) {')
	} else if elem.sym.kind == .map && !elem.typ.is_ptr() {
		eq_fn := g.gen_map_equality_fn(elem.typ)
		fn_builder.writeln('\t\tif (!${eq_fn}_map_eq(a[i], b[i])) {')
	} else if elem.sym.kind == .alias && !elem.typ.is_ptr() {
		eq_fn := g.gen_alias_equality_fn(elem.typ)
		fn_builder.writeln('\t\tif (!${eq_fn}_alias_eq(a[i], b[i])) {')
	} else if elem.sym.kind == .function {
		fn_builder.writeln('\t\tif (a[i] != b[i]) {')
	} else {
		fn_builder.writeln('\t\tif (a[i] != b[i]) {')
	}
	fn_builder.writeln('\t\t\treturn false;')
	fn_builder.writeln('\t\t}')
	fn_builder.writeln('\t}')
	fn_builder.writeln('\treturn true;')
	fn_builder.writeln('}')
	g.auto_fn_definitions << fn_builder.str()
	return ptr_styp
}

fn (mut g Gen) gen_map_equality_fn(left_type ast.Type) string {
	left := g.unwrap(left_type)
	ptr_styp := g.typ(left.typ.set_nr_muls(0))
	if ptr_styp in g.map_fn_definitions {
		return ptr_styp
	}
	g.map_fn_definitions << ptr_styp
	value := g.unwrap(left.sym.map_info().value_type)
	ptr_value_styp := g.typ(value.typ)
	g.type_definitions.writeln('static bool ${ptr_styp}_map_eq($ptr_styp a, $ptr_styp b); // auto')

	mut fn_builder := strings.new_builder(512)
	fn_builder.writeln('static bool ${ptr_styp}_map_eq($ptr_styp a, $ptr_styp b) {')
	fn_builder.writeln('\tif (a.len != b.len) {')
	fn_builder.writeln('\t\treturn false;')
	fn_builder.writeln('\t}')
	fn_builder.writeln('\tfor (int i = 0; i < a.key_values.len; ++i) {')
	fn_builder.writeln('\t\tif (!DenseArray_has_index(&a.key_values, i)) continue;')
	fn_builder.writeln('\t\tvoidptr k = DenseArray_key(&a.key_values, i);')
	fn_builder.writeln('\t\tif (!map_exists(&b, k)) return false;')
	kind := g.table.type_kind(value.typ)
	if kind == .function {
		func := value.sym.info as ast.FnType
		ret_styp := g.typ(func.func.return_type)
		fn_builder.write_string('\t\t$ret_styp (*v) (')
		arg_len := func.func.params.len
		for j, arg in func.func.params {
			arg_styp := g.typ(arg.typ)
			fn_builder.write_string('$arg_styp $arg.name')
			if j < arg_len - 1 {
				fn_builder.write_string(', ')
			}
		}
		fn_builder.writeln(') = *(voidptr*)map_get(&a, k, &(voidptr[]){ 0 });')
	} else {
		fn_builder.writeln('\t\t$ptr_value_styp v = *($ptr_value_styp*)map_get(&a, k, &($ptr_value_styp[]){ 0 });')
	}
	match kind {
		.string {
			fn_builder.writeln('\t\tif (!fast_string_eq(*(string*)map_get(&b, k, &(string[]){_SLIT("")}), v)) {')
		}
		.sum_type {
			eq_fn := g.gen_sumtype_equality_fn(value.typ)
			fn_builder.writeln('\t\tif (!${eq_fn}_sumtype_eq(*($ptr_value_styp*)map_get(&b, k, &($ptr_value_styp[]){ 0 }), v)) {')
		}
		.struct_ {
			eq_fn := g.gen_struct_equality_fn(value.typ)
			fn_builder.writeln('\t\tif (!${eq_fn}_struct_eq(*($ptr_value_styp*)map_get(&b, k, &($ptr_value_styp[]){ 0 }), v)) {')
		}
		.array {
			eq_fn := g.gen_array_equality_fn(value.typ)
			fn_builder.writeln('\t\tif (!${eq_fn}_arr_eq(*($ptr_value_styp*)map_get(&b, k, &($ptr_value_styp[]){ 0 }), v)) {')
		}
		.array_fixed {
			eq_fn := g.gen_fixed_array_equality_fn(value.typ)
			fn_builder.writeln('\t\tif (!${eq_fn}_arr_eq(*($ptr_value_styp*)map_get(&b, k, &($ptr_value_styp[]){ 0 }), v)) {')
		}
		.map {
			eq_fn := g.gen_map_equality_fn(value.typ)
			fn_builder.writeln('\t\tif (!${eq_fn}_map_eq(*($ptr_value_styp*)map_get(&b, k, &($ptr_value_styp[]){ 0 }), v)) {')
		}
		.alias {
			eq_fn := g.gen_alias_equality_fn(value.typ)
			fn_builder.writeln('\t\tif (!${eq_fn}_alias_eq(*($ptr_value_styp*)map_get(&b, k, &($ptr_value_styp[]){ 0 }), v)) {')
		}
		.function {
			fn_builder.writeln('\t\tif (*(voidptr*)map_get(&b, k, &(voidptr[]){ 0 }) != v) {')
		}
		else {
			fn_builder.writeln('\t\tif (*($ptr_value_styp*)map_get(&b, k, &($ptr_value_styp[]){ 0 }) != v) {')
		}
	}
	fn_builder.writeln('\t\t\treturn false;')
	fn_builder.writeln('\t\t}')
	fn_builder.writeln('\t}')
	fn_builder.writeln('\treturn true;')
	fn_builder.writeln('}')
	g.auto_fn_definitions << fn_builder.str()
	return ptr_styp
}
