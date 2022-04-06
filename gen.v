module gen

import ast
import regex

struct Context {
mut:
	mod ast.Module
}

pub fn run(ast ast.Program) string {
	mut ctx := Context{}

	mut statements := []string{}

	for statement in ast.statements {
		statements << gen_statement(mut ctx, statement)
	}

	return statements.join('\n')
}

pub fn gen_statements(mut ctx Context, statements_ []ast.Statement) []string {
	mut statements := []string{}

	for statement in statements_ {
		statements << gen_statement(mut ctx, statement)
	}

	return statements
}

pub fn gen_statement(mut ctx Context, ast ast.Statement) string {
	return match ast {
		ast.Module {
			ctx.mod = ast
			gen_statements(mut ctx, ast.statements).join('\n')
		}

		ast.Variable {
			id := gen_identifier(mut ctx, ast.id)
			expr := gen_expression(mut ctx, ast.expr)
			'let $id = $expr'
		}

		ast.Function {
			gen_function(mut ctx, ast)
		}

		ast.If {
			gen_if(mut ctx, ast)
		}

		ast.Return {
			gen_return(mut ctx, ast)
		}

		ast.Noop {
			''
		}

		else {
			panic('Unexpected statement ast $ast')
			''
		}
	}
}

pub fn gen_if(mut ctx Context, ast ast.If) string {
	test := gen_expression(mut ctx, ast.test)

	mut true_ := gen_statements(mut ctx, ast.true_)

	true_ = gen_indent(mut ctx, true_)

	mut false_ := gen_statements(mut ctx, ast.false_)

	false_ = gen_indent(mut ctx, false_)

	if !(ast.false_[0] is ast.If) {
		false_[0] = '{\n${false_[0]}\n}'
	} else {
		false_[0] = false_[0].trim(' ')
	}

	true__ := true_.join('\n')
	false__ := false_.join('\n')

	if_ := 'if ($test) {\n$true__\n} else $false__'

	return if_
}

pub fn gen_return(mut ctx Context, ast ast.Return) string {
	expr := gen_expression(mut ctx, ast.expr)
	return 'return $expr'
}

pub fn gen_function(mut ctx Context, ast ast.Function) string {
	mod := ctx.mod.id.replace('.', '_')

	id := '${mod}_${gen_identifier(mut ctx, ast.id)}'

	mut arguments_ := []string{}

	for argument_ in ast.args {
		arguments_ << argument_.id.value
	}

	arguments := arguments_.join(', ')

	mut statements_ := []string{}

	for statement_ in ast.statements {
		statements_ << gen_statement(mut ctx, statement_)
	}

	statements_ = statements_.join('\n').split('\n')

	if statements_.len > 1 {
		for i, _ in statements_ {
			statements_[i] = '  ${statements_[i]}'
		}
	}

	mut statements := statements_.join('\n')

	if statements_.len > 1 {
		statements = '\n$statements\n'
	}

	return 'function ${id}(${arguments}) {$statements}'
}

pub fn gen_identifier(mut ctx Context, ast ast.Identifier) string {
	return ast.value
}

pub fn gen_expression(mut ctx Context, ast ast.Expression) string {
	return match ast {
		ast.Js {
			gen_js(mut ctx, ast)
		}
		ast.Number {
			gen_number(mut ctx, ast)
		}
		ast.String {
			gen_string(mut ctx, ast)
		}
		ast.Identifier {
			gen_identifier(mut ctx, ast)
		}
		ast.BinaryExpression {
			gen_binary_expression(mut ctx, ast)
		}
		ast.Array {
			gen_array(mut ctx, ast)
		}
		ast.Noop {
			''
		}
	}
}

pub fn gen_binary_expression(mut ctx Context, ast ast.BinaryExpression) string {
	op := match ast.op {
		.add { '+' }
		.sub { '-' }
		.div { '/' }
		.mul { '*' }
		.lt  { '<' }
		.gt  { '>' }
		.eq  { '===' }
	}

	mut left := gen_expression(mut ctx, ast.left)
	mut right := gen_expression(mut ctx, ast.right)

	if ast.left is ast.BinaryExpression {
		left = '($left)'
	}

	if ast.right is ast.BinaryExpression {
		right = '($right)'
	}

	return '$left $op $right'
}

pub fn gen_array(mut ctx Context, ast ast.Array) string {
	mut items := []string{}

	for item in ast.items {
		gened_item := gen_expression(mut ctx, item)
		items << gened_item
	}

	j_items := items.join(', ')
	return '[$j_items]'
}

pub fn gen_js(mut ctx Context, ast ast.Js) string {
	mut value := ast.value

	mut re := regex.regex_opt('#\\{(.+)\\}') or {
		panic(err)
	}

	mut start, mut end := re.match_string(value)

	for start > -1 {
		group_list := re.get_group_list()

		replace_from := value[start..end]
		replace_to   := value[group_list[0].start..group_list[0].end]

		value = value.replace(replace_from, replace_to)

		start, end = re.match_string(value)
	}

	return value
}

pub fn gen_number(mut ctx Context, ast ast.Number) string {
	return ast.value
}

pub fn gen_string(mut ctx Context, ast ast.String) string {
	value := ast.value
	return '`$value`'
}

pub fn gen_indent(mut ctx Context, strs []string) []string {
	mut strs_ := strs.clone()

	for i, _ in strs_ {
		strs_[i] = '  ${strs_[i]}'
	}

	return strs_
}