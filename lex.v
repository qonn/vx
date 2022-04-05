module lex

import tok
import regex

struct Lexer {
	len     i64
	content string
mut:
	pos  i64
	re   map[string]regex.RE
	curr tok.Token
}

pub fn new(input string) Lexer {
	mut l := Lexer {
		pos: 0
		len: input.len
		content: input
		re: init_re()
	}

	l.curr = l.next()

	return l
}

fn init_re() map[string]regex.RE {
	return {
		'return': regex.regex_opt('^return ') or {
			panic(err)
		}
		'enum': regex.regex_opt('^enum ') or {
			panic(err)
		}
		'rec': regex.regex_opt('^rec ') or {
			panic(err)
		}
		'pub': regex.regex_opt('^pub ') or {
			panic(err)
		}
		'mod': regex.regex_opt('^mod ') or {
			panic(err)
		}
		'fn': regex.regex_opt('^fn ') or {
			panic(err)
		}
		'if': regex.regex_opt('^if ') or {
			panic(err)
		}
		'else': regex.regex_opt('^else ') or {
			panic(err)
		}
		'let': regex.regex_opt('^let ') or {
			panic(err)
		}
		'eqeq': regex.regex_opt('^==') or {
			panic(err)
		}
		'number': regex.regex_opt('^[0-9\.]+') or {
			panic(err)
		}
		'string': regex.regex_opt('^\'[a-zA-Z0-9_\\s]+\'') or {
			panic(err)
		}
		'id': regex.regex_opt('^[a-zA-Z0-9_]+') or {
			panic(err)
		}
	}
}

pub fn(mut l Lexer) eat(v tok.Variant) tok.Token {
	curr := l.curr
	curr_v := curr.v

	if curr.v == .eof {
		return l.curr
	}

	if curr.v != v {
		panic('Unexpected token $curr_v, expecting $v')
	}

	l.curr = l.next()

	return l.curr
}

pub fn(mut l Lexer) next() tok.Token {
	for {
		if l.pos >= l.len {
			break
		}

		for key, mut re in l.re {
			re_start, re_end := re.match_string(l.content[l.pos..])

			if re_start >= 0 {
				match key {
					'return' {
						return l.advance_with_token(.return_, re_end - 1)
					}
					'rec' {
						return l.advance_with_token(.rec, re_end - 1)
					}
					'enum' {
						return l.advance_with_token(.enum_, re_end - 1)
					}
					'pub' {
						return l.advance_with_token(.pub_, re_end - 1)
					}
					'mod' {
						return l.advance_with_token(.mod, re_end - 1)
					}
					'fn' {
						return l.advance_with_token(.fn_, re_end - 1)
					}
					'if' {
						return l.advance_with_token(.if_, re_end - 1)
					}
					'else' {
						return l.advance_with_token(.else_, re_end - 1)
					}
					'let' {
						return l.advance_with_token(.let, re_end - 1)
					}
					'eqeq' {
						return l.advance_with_token(.eqeq, re_end)
					}
					'number' {
						raw   := l.content[l.pos..(l.pos + re_end)]
						value := raw[0..(raw.len)].str()
						return l.advance_with_token_2(.number, re_end, raw, value)
					}
					'string' {
						raw   := l.content[l.pos..(l.pos + re_end)]
						value := raw[1..(raw.len - 1)]
						return l.advance_with_token_2(.string_, re_end, raw, value)
					}
					'id' {
						raw   := l.content[l.pos..(l.pos + re_end)]
						value := raw[0..(raw.len)].str()
						return l.advance_with_token_2(.id, re_end, raw, value)
					}
					else { }
				}
			}
		}

		content_single_char := l.content[l.pos..(l.pos + 1)]

		match content_single_char {
			'\n' {
				return l.advance_with_token(.new_line, 1)
			}
			'=' {
				return l.advance_with_token(.eq, 1)
			}
			':' {
				return l.advance_with_token(.colon, 1)
			}
			'(' {
				return l.advance_with_token(.l_paren, 1)
			}
			')' {
				return l.advance_with_token(.r_paren, 1)
			}
			'{' {
				return l.advance_with_token(.l_brace, 1)
			}
			'}' {
				return l.advance_with_token(.r_brace, 1)
			}
			'[' {
				return l.advance_with_token(.l_square, 1)
			}
			']' {
				return l.advance_with_token(.r_square, 1)
			}
			'<' {
				return l.advance_with_token(.lt, 1)
			}
			'>' {
				return l.advance_with_token(.gt, 1)
			}
			'+' {
				return l.advance_with_token(.add, 1)
			}
			'-' {
				return l.advance_with_token(.sub, 1)
			}
			'/' {
				return l.advance_with_token(.div, 1)
			}
			'*' {
				return l.advance_with_token(.mul, 1)
			}
			',' {
				return l.advance_with_token(.comma, 1)
			}
			else {
				l.pos += 1
			}
		}

	}

	return tok.new(.eof, tok.Span { l.pos, l.pos }, '', '')
}

pub fn(mut l Lexer) advance_with_token(v tok.Variant, len i64) tok.Token {
	start := l.pos
	end   := start + len
	span  := tok.Span { start, end }
	l.pos += len
	return tok.new(v, span, '', '')
}

pub fn(mut l Lexer) advance_with_token_2(v tok.Variant, len i64, raw string, value string) tok.Token {
	start   := l.pos
	end     := start + len
	span    := tok.Span { start, end }
	l.pos   += len
	return tok.new(v, span, raw, value)
}

pub fn(l Lexer) eof() bool {
	return l.pos >= l.len
}

pub fn (mut l Lexer) curr() tok.Token {
	return l.curr
}