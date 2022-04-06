module tok

pub struct Token {
pub:
	v     Variant
	raw   string
	value string
	span  Span [required]
}

pub enum Variant {
	new_line
	return_
	enum_
	js
	rec
	fn_
	if_
	else_
	pub_
	mod
	let
	eq
	eqeq
	colon
	l_paren
	r_paren
	l_brace
	r_brace
	l_square
	r_square
	lt
	gt
	add
	sub
	div
	mul
	string_
	number
	id
	comma
	dot
	eof
}

pub struct Span {
pub:
	start i64
	end   i64
}

pub fn new(v Variant, span Span, raw string, value string) Token {
	return Token {
		v,
		raw,
		value,
		span
	}
}