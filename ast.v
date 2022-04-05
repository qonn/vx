module ast

import lex

struct Noop {}

struct Identifier {
pub:
	value string
}

struct String {
pub:
	value string
}

struct Number {
pub:
	value string
}

type Expression =
	String |
	Number |
	Identifier |
	BinaryExpression |
	Array |
	Noop

struct Array {
pub:
	items []Expression
}

struct BinaryExpression {
pub:
	op   Operator
	left Expression
	right Expression
}

pub enum Operator {
	add
	sub
	div
	mul
	lt
	gt
	eq
}

struct FunctionArgument {
pub:
	id         Identifier
	type_      ?Identifier
}

struct Function {
pub:
	id         Identifier
	args       []FunctionArgument
	statements []Statement
}

struct Variable {
pub:
	id   Identifier
	expr Expression
}

struct If {
pub:
	test   Expression
	true_  []Statement
	false_ []Statement
}

struct Return {
pub:
	expr Expression
}

type Statement =
	Variable |
	Expression |
	Function |
	If |
	Return |
	Noop

struct Program {
pub:
	statements []Statement
}

pub fn gen(input string) Program {
	mut lex := lex.new(input)

	return Program {
		statements: gen_statements(mut lex)
	}
}

pub fn gen_statements(mut l lex.Lexer) []Statement {
	mut statements := []Statement{}

	for {
		if l.eof() || l.curr().v == .r_brace {
			break
		}

		if l.curr().v == .new_line {
			l.eat(.new_line)
		}

		statement := gen_statement(mut l) or {
			continue
		}

		statements << statement
	}

	return statements
}

pub fn gen_statement(mut l lex.Lexer) ?Statement {
	token := l.curr()

	return match token.v {
		.let {
			Statement(gen_variable(mut l))
		}
		.fn_ {
			Statement(gen_function(mut l))
		}
		.if_ {
			Statement(gen_if(mut l))
		}
		.return_ {
			Statement(gen_return(mut l))
		}
		.new_line {
			Statement(Noop{})
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

pub fn gen_variable(mut l lex.Lexer) Variable {
	l.eat(.let)

	id := gen_identifier(mut l)

	l.eat(.eq)

	expr := gen_expression(mut l)

	return Variable {
		id,
		expr,
	}
}

pub fn gen_function(mut l lex.Lexer) Function {
	l.eat(.fn_)

	id := gen_identifier(mut l)

	l.eat(.l_paren)

	mut args := []FunctionArgument{}

	l.eat(.r_paren)

	l.eat(.l_brace)

	mut statements := []Statement{}

	for {
		if l.eof() || l.curr().v == .r_brace {
			break
		}

		if l.curr().v == .new_line {
			l.eat(.new_line)
		}

		statement := gen_statement(mut l) or {
			continue
		}

		statements << statement
	}

	l.eat(.r_brace)

	return Function {
		id,
		args,
		statements
	}
}

pub fn gen_if(mut l lex.Lexer) If {
	l.eat(.if_)

	test := gen_expression(mut l)
	true_ := gen_if_block(mut l)

	mut false_ := []Statement{}

	if l.curr().v == .else_ {
		l.eat(.else_)

		if l.curr().v == .if_ {
			false_ << Statement(gen_if(mut l))
		} else if l.curr().v == .l_brace {
			false_ = gen_if_block(mut l)
		}
	}

	return If {
		test,
		true_,
		false_
	}
}

pub fn gen_if_block(mut l lex.Lexer) []Statement {
	mut statements := []Statement{}

	l.eat(.l_brace)

	statements = gen_statements(mut l)

	l.eat(.r_brace)

	return statements
}

pub fn gen_return(mut l lex.Lexer) Return {
	l.eat(.return_)

	expr := gen_expression(mut l)

	return Return {
		expr
	}
}

pub fn gen_identifier(mut l lex.Lexer) Identifier {
	token := l.curr()

	l.eat(.id)

	match token.v {
		.id {
			return Identifier {
				value: token.value
			}
		}

		else {
			panic("Unexpected token $token")
		}
	}
}

pub fn gen_expression(mut l lex.Lexer) Expression {
	mut token := l.curr()

	if token.v == .l_paren {
		token = l.eat(.l_paren)
	}

	mut expr := match token.v {
		.number {
			Expression(gen_number(mut l))
		}

		.string_ {
			Expression(gen_string(mut l))
		}

		.id {
			Expression(gen_identifier(mut l))
		}

		.l_square {
			Expression(gen_array(mut l))
		}

		else {
			panic("Unexpected token $token")
			Expression(Noop {})
		}
	}

	token  = l.curr()

	expr  = match token.v {
		.add, .sub, .mul, .div, .lt, .gt, .eqeq {
			gen_binary_expression(mut l, expr)
		}
		else {
			expr
		}
	}

	if token.v == .r_paren {
		token = l.eat(.r_paren)
	}

	return expr
}

pub fn gen_array(mut l lex.Lexer) Array {
	l.eat(.l_square)

	mut items := []Expression{}

	for {
		if l.curr().v == .eof || l.curr().v == .r_square {
			break
		}

		item := gen_expression(mut l)

		items << item

		if l.curr().v == .r_square {
			break
		}

		l.eat(.comma)
	}

	l.eat(.r_square)

	return Array {
		items
	}
}

pub fn gen_binary_expression(mut l lex.Lexer, left Expression) BinaryExpression {
	op_token := l.curr()

	op := match op_token.v {
		.add {
			l.eat(.add)
			Operator.add
		}
		.sub {
			l.eat(.sub)
			Operator.sub
		}
		.div {
			l.eat(.div)
			Operator.div
		}
		.mul {
			l.eat(.mul)
			Operator.mul
		}
		.lt {
			l.eat(.lt)
			Operator.lt
		}
		.gt {
			l.eat(.gt)
			Operator.gt
		}
		.eqeq {
			l.eat(.eqeq)
			Operator.eq
		}
		else {
			panic('Unexpected token $op_token')
		}
	}

	right := gen_expression(mut l)

	return BinaryExpression {
		op,
		left,
		right,
	}
}

pub fn gen_number(mut l lex.Lexer) Number {
	value := l.curr().value

	l.eat(.number)

	return Number {
		value
	}
}

pub fn gen_string(mut l lex.Lexer) String {
	value := l.curr().value

	l.eat(.string_)

	return String {
		value
	}
}