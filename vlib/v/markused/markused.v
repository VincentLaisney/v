// Copyright (c) 2019-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license that can be found in the LICENSE file.
module markused

import v.ast
import v.util
import v.pref

// mark_used walks the AST, starting at main() and marks all used fns transitively
pub fn mark_used(mut table ast.Table, pref &pref.Preferences, ast_files []&ast.File) {
	mut all_fns, all_consts, all_globals := all_fn_const_and_global(ast_files)
	util.timing_start(@METHOD)
	defer {
		util.timing_measure(@METHOD)
	}
	mut all_fn_root_names := [
		'main.main',
		'__new_array',
		'str_intp',
		'format_sb',
		'__new_array_with_default',
		'__new_array_with_array_default',
		'v_realloc' /* needed for _STR */,
		'malloc',
		'malloc_noscan',
		'vcalloc',
		'vcalloc_noscan',
		'new_array_from_c_array',
		'v_fixed_index',
		'memdup',
		'vstrlen',
		'__as_cast',
		'tos',
		'tos2',
		'tos3',
		'isnil',
		'opt_ok',
		'error',
		'__print_assert_failure',
		// utf8_str_visible_length is used by c/str.v
		'utf8_str_visible_length',
		'compare_ints',
		'compare_u64s',
		'compare_strings',
		'compare_ints_reverse',
		'compare_u64s_reverse',
		'compare_strings_reverse',
		'builtin_init',
		// byteptr and charptr
		'3.vstring',
		'3.vstring_with_len',
		'3.vstring_literal',
		'4.vstring',
		'4.vstring_with_len',
		'4.vstring_literal',
		// byte. methods
		'10.str_escaped',
		// string. methods
		'20.add',
		'20.trim_space',
		'20.repeat',
		'20.replace',
		'20.clone',
		'20.clone_static',
		'20.trim',
		'20.substr',
		'20.at',
		'20.at_with_check',
		'20.index_kmp',
		// string. ==, !=, etc...
		'20.eq',
		'20.ne',
		'20.lt',
		'20.gt',
		'20.le',
		'20.ge',
		'fast_string_eq',
		// other array methods
		'22.get',
		'22.set',
		'22.get_unsafe',
		'22.set_unsafe',
		'22.get_with_check' /* used for `x := a[i] or {}` */,
		'22.clone_static_to_depth',
		'22.clone_to_depth',
		'22.first',
		'22.last',
		'22.pointers' /* TODO: handle generic methods calling array primitives more precisely in pool_test.v */,
		'22.reverse',
		'22.repeat_to_depth',
		'22.slice',
		'22.slice2',
		'61.get',
		'61.set',
		'65558.last',
		'65558.pop',
		'65558.push',
		'65558.insert_many',
		'65558.prepend_many',
		'65558.reverse',
		'65558.set',
		'65558.set_unsafe',
		// TODO: process the _vinit const initializations automatically too
		'json.decode_string',
		'json.decode_int',
		'json.decode_bool',
		'json.decode_u64',
		'json.encode_int',
		'json.encode_string',
		'json.encode_bool',
		'json.encode_u64',
		'json.json_print',
		'json.json_parse',
		'main.cb_propagate_test_error',
		'os.getwd',
		'os.init_os_args',
		'os.init_os_args_wide',
		'v.embed_file.find_index_entry_by_path',
	]

	if pref.is_bare {
		all_fn_root_names << [
			'strlen',
			'memcmp',
			'memcpy',
			'realloc',
			'vsnprintf',
			'vsprintf',
		]
	}

	if pref.gc_mode in [.boehm_full_opt, .boehm_incr_opt] {
		all_fn_root_names << [
			'memdup_noscan',
			'__new_array_noscan',
			'__new_array_with_default_noscan',
			'__new_array_with_array_default_noscan',
			'new_array_from_c_array_noscan',
			'22.clone_static_to_depth_noscan',
			'22.clone_to_depth_noscan',
			'22.reverse_noscan',
			'22.repeat_to_depth_noscan',
			'65558.pop_noscan',
			'65558.push_noscan',
			'65558.push_many_noscan',
			'65558.insert_noscan',
			'65558.insert_many_noscan',
			'65558.prepend_noscan',
			'65558.prepend_many_noscan',
			'65558.reverse_noscan',
			'65558.grow_cap_noscan',
			'65558.grow_len_noscan',
		]
	}

	for k, mut mfn in all_fns {
		$if trace_skip_unused_all_fns ? {
			println('k: $k | mfn: $mfn.name')
		}
		mut method_receiver_typename := ''
		if mfn.is_method {
			method_receiver_typename = table.type_to_str(mfn.receiver.typ)
		}
		if method_receiver_typename == '&wyrand.WyRandRNG' {
			// WyRandRNG is the default rand pseudo random generator
			all_fn_root_names << k
			continue
		}
		if method_receiver_typename == '&strings.Builder' {
			// implicit string builders are generated in auto_eq_methods.v
			all_fn_root_names << k
			continue
		}
		// auto generated string interpolation functions, may
		// call .str or .auto_str methods for user types:
		if k.ends_with('.str') || k.ends_with('.auto_str') {
			all_fn_root_names << k
			continue
		}
		if k.ends_with('.init') {
			all_fn_root_names << k
			continue
		}
		if k.ends_with('.free') {
			all_fn_root_names << k
			continue
		}

		// sync:
		if k == 'sync.new_channel_st' {
			all_fn_root_names << k
			continue
		}
		if k == 'sync.channel_select' {
			all_fn_root_names << k
			continue
		}
		if method_receiver_typename == '&sync.Channel' {
			all_fn_root_names << k
			continue
		}
		if k.ends_with('.lock') || k.ends_with('.unlock') || k.ends_with('.rlock')
			|| k.ends_with('.runlock') {
			all_fn_root_names << k
			continue
		}
		// testing framework:
		if pref.is_test {
			if k.starts_with('test_') || k.contains('.test_') {
				all_fn_root_names << k
				continue
			}
			if k.starts_with('testsuite_') || k.contains('.testsuite_') {
				// eprintln('>>> test suite: $k')
				all_fn_root_names << k
				continue
			}
		}
		// public/exported functions can not be skipped,
		// especially when producing a shared library:
		if mfn.is_pub && pref.is_shared {
			all_fn_root_names << k
			continue
		}
		if mfn.name in ['+', '-', '*', '%', '/', '<', '=='] {
			// TODO: mark the used operators in the checker
			all_fn_root_names << k
			continue
		}
		if pref.prealloc && k.starts_with('prealloc_') {
			all_fn_root_names << k
			continue
		}
	}

	// handle assertions and testing framework callbacks:
	if pref.is_debug {
		all_fn_root_names << 'panic_debug'
	}
	all_fn_root_names << 'panic_optional_not_set'
	if pref.is_test {
		all_fn_root_names << 'main.cb_assertion_ok'
		all_fn_root_names << 'main.cb_assertion_failed'
		if benched_tests_sym := table.find_type('main.BenchedTests') {
			bts_type := benched_tests_sym.methods[0].params[0].typ
			all_fn_root_names << '${bts_type}.testing_step_start'
			all_fn_root_names << '${bts_type}.testing_step_end'
			all_fn_root_names << '${bts_type}.end_testing'
			all_fn_root_names << 'main.start_testing'
		}
	}

	// handle interface implementation methods:
	for isym in table.type_symbols {
		if isym.kind != .interface_ {
			continue
		}
		interface_info := isym.info as ast.Interface
		if interface_info.methods.len == 0 {
			continue
		}
		for itype in interface_info.types {
			pitype := itype.set_nr_muls(1)
			mut itypes := [itype]
			if pitype != itype {
				itypes << pitype
			}
			for method in interface_info.methods {
				for typ in itypes {
					interface_implementation_method_name := '${int(typ)}.$method.name'
					$if trace_skip_unused_interface_methods ? {
						eprintln('>> isym.name: $isym.name | interface_implementation_method_name: $interface_implementation_method_name')
					}
					all_fn_root_names << interface_implementation_method_name
				}
			}
		}
	}

	// handle vweb magic router methods:
	typ_vweb_result := table.find_type_idx('vweb.Result')
	if typ_vweb_result != 0 {
		all_fn_root_names << 'vweb.filter'
		typ_vweb_context := ast.Type(table.find_type_idx('vweb.Context')).set_nr_muls(1)
		all_fn_root_names << '${int(typ_vweb_context)}.html'
		for vgt in table.used_vweb_types {
			sym_app := table.get_type_symbol(vgt)
			for m in sym_app.methods {
				if m.return_type == typ_vweb_result {
					pvgt := vgt.set_nr_muls(1)
					// eprintln('vgt: $vgt | pvgt: $pvgt | sym_app.name: $sym_app.name | m.name: $m.name')
					all_fn_root_names << '${int(pvgt)}.$m.name'
				}
			}
		}
	}

	// handle ORM drivers:
	orm_connection_implementations := table.iface_types['orm.Connection'] or { []ast.Type{} }
	if orm_connection_implementations.len > 0 {
		for k, _ in all_fns {
			if k.starts_with('orm.') {
				all_fn_root_names << k
			}
		}
		for orm_type in orm_connection_implementations {
			all_fn_root_names << '${int(orm_type)}.select'
			all_fn_root_names << '${int(orm_type)}.insert'
			all_fn_root_names << '${int(orm_type)}.update'
			all_fn_root_names << '${int(orm_type)}.delete'
			all_fn_root_names << '${int(orm_type)}.create'
			all_fn_root_names << '${int(orm_type)}.drop'
			all_fn_root_names << '${int(orm_type)}.last_id'
		}
	}

	// handle -live main programs:
	if pref.is_livemain {
		all_fn_root_names << 'v.live.executable.start_reloader'
		all_fn_root_names << 'v.live.executable.new_live_reload_info'
	}

	mut walker := Walker{
		table: table
		files: ast_files
		all_fns: all_fns
		all_consts: all_consts
		all_globals: all_globals
		pref: pref
	}
	// println( all_fns.keys() )
	walker.mark_exported_fns()
	walker.mark_root_fns(all_fn_root_names)

	if walker.n_asserts > 0 {
		walker.fn_decl(mut all_fns['__print_assert_failure'])
	}
	if table.used_maps > 0 {
		for k, mut mfn in all_fns {
			mut method_receiver_typename := ''
			if mfn.is_method {
				method_receiver_typename = table.type_to_str(mfn.receiver.typ)
			}
			if k in ['new_map', 'new_map_init', 'map_hash_string']
				|| method_receiver_typename == '&map' || method_receiver_typename == '&DenseArray'
				|| k.starts_with('map_') {
				walker.fn_decl(mut mfn)
			}
			if pref.gc_mode in [.boehm_full_opt, .boehm_incr_opt] {
				if k in ['new_map_noscan_key', 'new_map_noscan_value', 'new_map_noscan_key_value',
					'new_map_init_noscan_key', 'new_map_init_noscan_value',
					'new_map_init_noscan_key_value',
				] {
					walker.fn_decl(mut mfn)
				}
			}
		}
	} else {
		for map_fn_name in ['new_map', 'new_map_init', 'map_hash_string', 'new_dense_array'] {
			walker.used_fns.delete(map_fn_name)
		}
		for k, mut mfn in all_fns {
			if !mfn.is_method {
				continue
			}
			method_receiver_typename := table.type_to_str(mfn.receiver.typ)
			if method_receiver_typename in ['&map', '&mapnode', '&SortedMap', '&DenseArray'] {
				walker.used_fns.delete(k)
			}
		}
	}

	$if trace_skip_unused_fn_names ? {
		for key, _ in walker.used_fns {
			println('> used fn key: $key')
		}
	}

	table.used_fns = walker.used_fns.move()
	table.used_consts = walker.used_consts.move()
	table.used_globals = walker.used_globals.move()

	$if trace_skip_unused ? {
		eprintln('>> t.used_fns: $table.used_fns.keys()')
		eprintln('>> t.used_consts: $table.used_consts.keys()')
		eprintln('>> t.used_globals: $table.used_globals.keys()')
		eprintln('>> walker.table.used_maps: $walker.table.used_maps')
	}
}

fn all_fn_const_and_global(ast_files []&ast.File) (map[string]ast.FnDecl, map[string]ast.ConstField, map[string]ast.GlobalField) {
	util.timing_start(@METHOD)
	defer {
		util.timing_measure(@METHOD)
	}
	mut all_fns := map[string]ast.FnDecl{}
	mut all_consts := map[string]ast.ConstField{}
	mut all_globals := map[string]ast.GlobalField{}
	for i in 0 .. ast_files.len {
		file := ast_files[i]
		for node in file.stmts {
			match node {
				ast.FnDecl {
					fkey := node.fkey()
					all_fns[fkey] = node
				}
				ast.ConstDecl {
					for cfield in node.fields {
						ckey := cfield.name
						all_consts[ckey] = cfield
					}
				}
				ast.GlobalDecl {
					for gfield in node.fields {
						gkey := gfield.name
						all_globals[gkey] = gfield
					}
				}
				else {}
			}
		}
	}
	return all_fns, all_consts, all_globals
}
