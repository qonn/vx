module parse

import ast
import lex

pub fn run(input string) ast.Program {
	mut lex := lex.new(input)

	return ast.Program {
		statements: par_statements(mut lex)
	}
}

fn par_statements(mut l lex.Lexer) []ast.Statement {
	mut statements := []ast.Statement{}

	for {
		if l.eof() || l.curr().v == .r_brace {
			break
		}

		if l.curr().v == .new_line {
			l.eat(.new_line)
		}

		statement := par_statement(mut l) or {
			continue
		}

		statements << statement
	}

	return statements
}

fn par_statement(mut l lex.Lexer) ?ast.Statement {
	token := l.curr()

	return match token.v {
		.mod {
			ast.Statement(par_module(mut l))
		}
		.let {
			ast.Statement(par_variable(mut l))
		}
		.fn_ {
			ast.Statement(par_function(mut l))
		}
		.if_ {
			ast.Statement(par_if(mut l))
		}
		.return_ {
			ast.Statement(par_return(mut l))
		}
		.new_line {
			ast.Statement(ast.Noop{})
		}
		.eof {
			none
		}
		.r_brace {
			none
		}
		else {
			panic('Unexpected token $token, expecting let, fn')
			none
		}
	}
}

fn par_module(mut l lex.Lexer) ast.Module {
	l.eat(.mod)

	mut ids := []string{}

	for {
		token := l.curr()

		if l.eof() || token.v == .l_brace {
			break
		}

		if token.v == .id {
			ids << token.value
			l.eat(.id)
		}

		if token.v == .dot {
			l.eat(.dot)
		}
	}

	l.eat(.l_brace)

	statements := par_statements(mut l)

	l.eat(.r_brace)

	id := ids.join(".")

	return ast.Module {
		id,
		statements
	}
}

fn par_variable(mut l lex.Lexer) ast.Variable {
	l.eat(.let)

	id := par_identifier(mut l)

	l.eat(.eq)

	expr := par_expression(mut l)

	return ast.Variable {
		id,
		expr,
	}
}

fn par_function(mut l lex.Lexer) ast.Function {
	l.eat(.fn_)

	id := par_identifier(mut l)

	mut args := par_function_arguments(mut l)

	mut returning := ast.Type(ast.AutoInfer{})

	if l.curr().v == .colon {
		l.eat(.colon)
		returning = ast.Type(par_identifier(mut l))
	}

	l.eat(.l_brace)

	mut statements := []ast.Statement{}

	for {
		if l.eof() || l.curr().v == .r_brace {
			break
		}

		if l.curr().v == .new_line {
			l.eat(.new_line)
		}

		statement := par_statement(mut l) or {
			continue
		}

		statements << statement
	}

	l.eat(.r_brace)

	return ast.Function {
		id,
		args,
		statements,
		returning
	}
}

fn par_function_arguments(mut l lex.Lexer) []ast.FunctionArgument {
	mut args := []ast.FunctionArgument{}

	l.eat(.l_paren)

	for {
		if l.eof() || l.curr().v == .r_paren {
			break
		}

		if l.curr().v == .new_line {
			l.eat(.new_line)
		}

		args << par_function_argument(mut l)
	}

	l.eat(.r_paren)

	return args
}

fn par_function_argument(mut l lex.Lexer) ast.FunctionArgument {
	id := par_identifier(mut l)

	mut type_ := ast.Type(ast.AutoInfer {})

	if l.curr().v == .colon {
		l.eat(.colon)
		type_ = ast.Type(par_identifier(mut l))
	}

	fa := ast.FunctionArgument {
		id,
		type_
	}

	return fa
}

fn par_if(mut l lex.Lexer) ast.If {
	l.eat(.if_)

	test := par_expression(mut l)
	true_ := par_if_block(mut l)

	mut false_ := []ast.Statement{}

	if l.curr().v == .else_ {
		l.eat(.else_)

		if l.curr().v == .if_ {
			false_ << ast.Statement(par_if(mut l))
		} else if l.curr().v == .l_brace {
			false_ = par_if_block(mut l)
		}
	}

	return ast.If {
		test,
		true_,
		false_
	}
}

fn par_if_block(mut l lex.Lexer) []ast.Statement {
	mut statements := []ast.Statement{}

	l.eat(.l_brace)

	statements = par_statements(mut l)

	l.eat(.r_brace)

	return statements
}

fn par_return(mut l lex.Lexer) ast.Return {
	l.eat(.return_)

	expr := par_expression(mut l)

	return ast.Return {
		expr
	}
}

fn par_identifier(mut l lex.Lexer) ast.Identifier {
	token := l.curr()

	l.eat(.id)

	match token.v {
		.id {
			return ast.Identifier {
				value: token.value
			}
		}

		else {
			panic("Unexpected token $token")
		}
	}
}

fn par_expression(mut l lex.Lexer) ast.Expression {
	mut token := l.curr()

	if l.curr().v == .new_line {
		token = l.eat_new_lines()
	}

	if token.v == .l_paren {
		token = l.eat(.l_paren)
	}

	mut expr := match token.v {
		.js {
			ast.Expression(par_js(mut l))
		}

		.number {
			ast.Expression(par_number(mut l))
		}

		.string_ {
			ast.Expression(par_string(mut l))
		}

		.id {
			ast.Expression(par_identifier(mut l))
		}

		.l_square {
			ast.Expression(par_array(mut l))
		}

		else {
			panic("Unexpected token $token")
			ast.Expression(ast.Noop {})
		}
	}

	token  = l.curr()

	expr  = match token.v {
		.add, .sub, .mul, .div, .lt, .gt, .eqeq {
			par_binary_expression(mut l, expr)
		}
		else {
			expr
		}
	}

	if token.v == .r_paren {
		token = l.eat(.r_paren)
	}

	if l.curr().v == .new_line {
		l.eat_new_lines()
	}

	return expr
}

fn par_array(mut l lex.Lexer) ast.Array {
	l.eat(.l_square)

	mut items := []ast.Expression{}

	for {
		if l.curr().v == .new_line {
			l.eat_new_lines()
		}

		if l.curr().v == .eof || l.curr().v == .r_square {
			break
		}

		item := par_expression(mut l)

		items << item

		if l.curr().v == .r_square {
			break
		}

		if l.curr().v != .comma {
			break
		}

		l.eat(.comma)
	}

	l.eat(.r_square)

	return ast.Array {
		items
	}
}

fn par_binary_expression(mut l lex.Lexer, left ast.Expression) ast.BinaryExpression {
	op_token := l.curr()

	op := match op_token.v {
		.add {
			l.eat(.add)
			ast.Operator.add
		}
		.sub {
			l.eat(.sub)
			ast.Operator.sub
		}
		.div {
			l.eat(.div)
			ast.Operator.div
		}
		.mul {
			l.eat(.mul)
			ast.Operator.mul
		}
		.lt {
			l.eat(.lt)
			ast.Operator.lt
		}
		.gt {
			l.eat(.gt)
			ast.Operator.gt
		}
		.eqeq {
			l.eat(.eqeq)
			ast.Operator.eq
		}
		else {
			panic('Unexpected token $op_token')
		}
	}

	right := par_expression(mut l)

	return ast.BinaryExpression {
		op,
		left,
		right,
	}
}

fn par_js(mut l lex.Lexer) ast.Js {
	value := l.curr().value

	l.eat(.js)

	return ast.Js {
		value
	}
}

fn par_number(mut l lex.Lexer) ast.Number {
	value := l.curr().value

	l.eat(.number)

	return ast.Number {
		value
	}
}

fn par_string(mut l lex.Lexer) ast.String {
	value := l.curr().value

	l.eat(.string_)

	return ast.String {
		value
	}
}