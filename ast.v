module ast

pub struct Program {
pub:
	statements []Statement
}

type Statement =
	Module |
	Variable |
	Expression |
	Function |
	If |
	Return |
	Noop

pub struct Module {
pub:
	id         string
	statements []Statement
}

pub struct Variable {
pub:
	id   Identifier
	expr Expression
}

pub struct Identifier {
pub:
	value string
}

type Expression =
	String |
	Number |
	Js |
	Identifier |
	BinaryExpression |
	Array |
	Noop

pub struct Function {
pub:
	id         Identifier
	args       []FunctionArgument
	statements []Statement
	returning  Type
}

pub struct FunctionArgument {
pub:
	id         Identifier
mut:
	type_      Type
}

type Type =
	Identifier | AutoInfer

pub struct If {
pub:
	test   Expression
	true_  []Statement
	false_ []Statement
}

pub struct BinaryExpression {
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

pub struct Return {
pub:
	expr Expression
}

pub struct String {
pub:
	value string
}

pub struct Number {
pub:
	value string
}

pub struct Js {
pub:
	value string
}

pub struct Array {
pub:
	items []Expression
}

pub struct AutoInfer {}
pub struct Noop {}