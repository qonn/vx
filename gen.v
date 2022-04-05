module gen

import ast

pub fn run(ast ast.Program) string {
	mut statements := []string{}

	for statement in ast.statements {
		statements << gen_statement(statement)
	}

	return statements.join('\n')
}

pub fn gen_statements(statements_ []ast.Statement) []string {
	mut statements := []string{}

	for statement in statements_ {
		statements << gen_statement(statement)
	}

	return statements
}

pub fn gen_statement(ast ast.Statement) string {
	return match ast {
		ast.Variable {
			id := gen_identifier(ast.id)
			expr := gen_expression(ast.expr)
			'let $id = $expr'
		}

		ast.Function {
			gen_function(ast)
		}

		ast.If {
			gen_if(ast)
		}

		ast.Return {
			gen_return(ast)
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

pub fn gen_if(ast ast.If) string {
	test := gen_expression(ast.test)

	mut true_ := gen_statements(ast.true_)

	true_ = indent(true_)

	mut false_ := gen_statements(ast.false_)

	false_ = indent(false_)

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

pub fn gen_return(ast ast.Return) string {
	expr := gen_expression(ast.expr)
	return 'return $expr'
}

pub fn gen_function(ast ast.Function) string {
	id := gen_identifier(ast.id)

	mut statements_ := []string{}

	for statement_ in ast.statements {
		statements_ << gen_statement(statement_)
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

	return 'function ${id}() {$statements}'
}

pub fn gen_identifier(ast ast.Identifier) string {
	return ast.value
}

pub fn gen_expression(ast ast.Expression) string {
	return match ast {
		ast.Number {
			gen_number(ast)
		}

		ast.String {
			gen_string(ast)
		}

		ast.Identifier {
			gen_identifier(ast)
		}

		ast.BinaryExpression {
			gen_binary_expression(ast)
		}

		ast.Array {
			gen_array(ast)
		}
		ast.Noop {
			''
		}
	}
}

pub fn gen_binary_expression(ast ast.BinaryExpression) string {
	op := match ast.op {
		.add { '+' }
		.sub { '-' }
		.div { '/' }
		.mul { '*' }
		.lt  { '<' }
		.gt  { '>' }
		.eq  { '==' }
	}

	mut left := gen_expression(ast.left)
	mut right := gen_expression(ast.right)

	if ast.left is ast.BinaryExpression {
		left = '($left)'
	}

	if ast.right is ast.BinaryExpression {
		right = '($right)'
	}

	return '$left $op $right'
}

pub fn gen_array(ast ast.Array) string {
	mut items := []string{}

	for item in ast.items {
		gened_item := gen_expression(item)
		items << gened_item
	}

	j_items := items.join(', ')
	return '[$j_items]'
}

pub fn gen_number(ast ast.Number) string {
	return ast.value
}

pub fn gen_string(ast ast.String) string {
	value := ast.value
	return '`$value`'
}

pub fn indent(strs []string) []string {
	mut strs_ := strs.clone()

	for i, _ in strs_ {
		strs_[i] = '  ${strs_[i]}'
	}

	return strs_
}