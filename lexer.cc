#include "lexer.hh"

#include <cmath>
#include <fstream>
#include <iostream>
#include <vector>

#include "assert.hh"

#define ROOT_WITH_SDA_FORM(l, bare_kind, copy_kind, assign_kind) \
	Token tk(TK_INVAL, m_idx, m_line); \
	m_idx++; \
	if(current() == l) { \
		m_idx++; \
		tk.set_kind(copy_kind); \
	} else if(current() == '=') { \
		m_idx++; \
		tk.set_kind(assign_kind); \
	} else { \
		tk.set_kind(bare_kind); \
	} \
	tk.set_end_idx(m_idx); \
	return tk;

#define ROOT_WITH_SD_FORM(l, bare_kind, copy_kind) \
	Token tk(TK_INVAL, m_idx, m_line); \
	m_idx++; \
	if(current() == l) { \
		m_idx++; \
		tk.set_kind(copy_kind); \
	} else { \
		tk.set_kind(bare_kind); \
	} \
	tk.set_end_idx(m_idx); \
	return tk;

#define ROOT_WITH_BARE_FORM(bare_kind) \
	Token tk(bare_kind, m_idx, m_line); \
	m_idx++; \
	tk.set_end_idx(m_idx); \
	return tk;

Lexer::Lexer(std::string const& path)
	: m_idx(0)
	, m_line(0)
{
	std::ifstream file(path, std::ios::binary | std::ios::ate);

	size_t size = file.tellg();
	file.seekg(0, std::ios::beg);

	std::vector<char> raw(size);
	file.read(raw.data(), size);

	m_file_data = std::string(raw.data(), size);

	std::cout << "File data:" << std::endl;
	std::cout << m_file_data << std::endl;
}

Token Lexer::next()
{
	while(m_idx < m_file_data.size()) {
		switch(current()) {
			case '\n':
				m_line++;
			case ' ':
			case '\t':
			case '\v':
			case '\r':
				m_idx++;
				break;

			case '"': return tokenize_string_literal();
			case '\'': return tokenize_char_literal();

			case '0':
			case '1':
			case '2':
			case '3':
			case '4':
			case '5':
			case '6':
			case '7':
			case '8':
			case '9':
				return tokenize_number();

			case '(': { ROOT_WITH_BARE_FORM(TK_L_PAREN); }
			case ')': { ROOT_WITH_BARE_FORM(TK_R_PAREN); }
			case '{': { ROOT_WITH_BARE_FORM(TK_L_CURLY); }
			case '}': { ROOT_WITH_BARE_FORM(TK_R_CURLY); }
			case '[': { ROOT_WITH_BARE_FORM(TK_L_SQUARE); }
			case ']': { ROOT_WITH_BARE_FORM(TK_R_SQUARE); }

			case '<': { ROOT_WITH_SDA_FORM('<', TK_L_ANGLE, TK_L_SHIFT, TK_LEQ); }
			case '>': { ROOT_WITH_SDA_FORM('>', TK_R_ANGLE, TK_R_SHIFT, TK_GEQ); }
			case ':': { ROOT_WITH_SDA_FORM(':', TK_COLON, TK_DOUBLE_COLON, TK_COLON_ASSIGN); }
			case ';': { ROOT_WITH_BARE_FORM(TK_SEMICOLON); }
			case '$': { ROOT_WITH_BARE_FORM(TK_DOLLAR); }
			case ',': { ROOT_WITH_BARE_FORM(TK_COMMA); }
			case '.': { ROOT_WITH_SD_FORM('.', TK_DOT, TK_DOT_DOT); }
			case '#': { ROOT_WITH_BARE_FORM(TK_HASH); }

			// NOTE: Not how this macro is supposed to be used, but idc
			case '!': { ROOT_WITH_SD_FORM('=', TK_BANG, TK_NEQ); }
			case '?': { ROOT_WITH_BARE_FORM(TK_QUESTION_MARK); }

			// NOTE: Not how this macro is supposed to be used, but idc
			case '~': { ROOT_WITH_SD_FORM('=', TK_TILDE, TK_TILDE_ASSIGN); }

			case '&': { ROOT_WITH_SDA_FORM('&', TK_AMPERSAND, TK_DOUBLE_AMPERSAND, TK_AMPERSAND_ASSIGN); }
			case '|': { ROOT_WITH_SDA_FORM('|', TK_PIPE, TK_DOUBLE_PIPE, TK_PIPE_ASSIGN); }
			case '^': { ROOT_WITH_SDA_FORM('^', TK_CARET, TK_DOUBLE_CARET, TK_CARET_ASSIGN); }

			// NOTE: Not how this macro is supposed to be used, but idc
			case '*': { ROOT_WITH_SD_FORM('=', TK_STAR, TK_STAR_ASSIGN); }
			case '+': { ROOT_WITH_SDA_FORM('+', TK_PLUS, TK_PLUS_PLUS, TK_PLUS_ASSIGN); }

			case '/': {
				Token tk(TK_SLASH, m_idx, m_line);
				m_idx++;

				if(current() == '/') {
					// Line comment
					while(!at_eof() && current() != '\n')
						m_idx++;
					continue;
				} else if(current() == '*') {
					// Block comment
					while(!at_eof()) {
						if(current() == '/' && peek_char(-1) == '*') {
							m_idx++;
							break;
						}
					}

					continue;
				} else if(current() == '=') {
					m_idx++;
					tk.set_kind(TK_SLASH_ASSIGN);
				}

				tk.set_end_idx(m_idx);
				return tk;
			}
			case '=': {
				Token tk(TK_ASSIGN, m_idx, m_line);
				m_idx++;
				if(current() == '=') {
					m_idx++;
					tk.set_kind(TK_EQ);
				} else if(current() == '>') {
					m_idx++;
					tk.set_kind(TK_THICC_ARROW);
				}

				tk.set_end_idx(m_idx);
				return tk;
			}

			case '-': {
				Token tk(TK_MINUS, m_idx, m_line);
				m_idx++;
				if(current() == '-') {
					m_idx++;
					tk.set_kind(TK_MINUS_MINUS);
				} else if(current() == '=') {
					m_idx++;
					tk.set_kind(TK_MINUS_ASSIGN);
				} else if(current() == '>') {
					m_idx++;
					tk.set_kind(TK_THIN_ARROW);
				}

				tk.set_end_idx(m_idx);
				return tk;
			}

			default: return tokenize_ident_or_keyword();
		}
	}
	return Token(TK_EOF, 0, 0);
}

char Lexer::current()
{
	return peek_char(0);
}

char Lexer::peek_char(size_t offset)
{
	if(m_idx + offset >= m_file_data.size()) return 0;
	return m_file_data[m_idx + offset];
}

bool Lexer::at_eof()
{
	return m_idx >= m_file_data.size();
}

Token Lexer::tokenize_string_literal()
{
	ASSERT(current() == '"', "[Line %lu] Expected \", got '%c'", m_line, current());

	m_idx++;

	Token tk(TK_STR_LIT, m_idx, m_line);
	std::string str;

	while(!at_eof() && !(current() == '"' || current() == '\n')) {
		if(current() == '\\') {
			if(peek_char() == 'x') {
				Compiler::panic("Add support for hex literals in strings");
			} else if(peek_char() == 'b') {
				Compiler::panic("Add support for binary literals in strings");
			} else if(peek_char() == 'n') {
				m_idx += 2;
				str.push_back('\n');
			} else if(peek_char() == 'r') {
				m_idx += 2;
				str.push_back('\r');
			} else if(peek_char() == 't') {
				m_idx += 2;
				str.push_back('\t');
			} else if(peek_char() == 'v') {
				m_idx += 2;
				str.push_back('\v');
			} else {
				str.push_back(peek_char());
				m_idx += 2;
			}
		} else {
			str.push_back(current());
			m_idx++;
		}
	}

	ASSERT(current() == '"', "[Line %lu] Unterminated string literal", m_line);
	m_idx++;
	tk.set_end_idx(m_idx);
	tk.set_str_data(str);

	return tk;
}

Token Lexer::tokenize_char_literal()
{
	ASSERT(current() == '\'', "[Line %lu] Unterminated char literal", m_line);
	m_idx++;

	Token tk(TK_CHAR_LIT, m_idx, m_line);
	std::string str;

	if(!at_eof() && !(current() == '\n' || current() == '\'')) {
		if(current() == '\\') {
			if(peek_char() == 'x') {
				Compiler::panic("Add support for hex literals in strings");
			} else if(peek_char() == 'b') {
				Compiler::panic("Add support for binary literals in strings");
			} else if(peek_char() == 'n') {
				m_idx += 2;
				str.push_back('\n');
			} else if(peek_char() == 'r') {
				m_idx += 2;
				str.push_back('\r');
			} else if(peek_char() == 't') {
				m_idx += 2;
				str.push_back('\t');
			} else if(peek_char() == 'v') {
				m_idx += 2;
				str.push_back('\v');
			} else {
				str.push_back(peek_char());
				m_idx += 2;
			}
		} else {
			str.push_back(current());
			m_idx++;
		}
	}

	ASSERT(current() == '\'', "[Line %lu] Unterminated char literal", m_line);
	m_idx++;
	tk.set_end_idx(m_idx);
	tk.set_str_data(str);

	return tk;
}

static bool is_digit(char c)
{
	return (c >= '0' && c <= '9') ||
	       (c >= 'A' && c <= 'F') ||
	       (c >= 'a' && c <= 'f');
}

static uint8_t char_to_number(char digit)
{
	if(digit >= '0' && digit <= '9')
		return digit - '0';
	else if(digit >= 'A' && digit <= 'F')
		return digit - ('A' + 10);
	else if(digit >= 'a' && digit <= 'f')
		return digit - ('a' + 10);
	else
		Compiler::panic("Invalid digit char '%c'", digit);

	return 0;
}

Token Lexer::tokenize_number()
{
	ASSERT(is_digit(current()), "[Line %lu] Number literal must start with digit");
	Token tk(TK_NUMBER, m_idx, m_line);

	uint64_t i_num    = 0;
	double   f_num    = 0.0;
	bool     is_float = false;

	uint64_t decimal_lead    = 0;
	uint64_t fractional_tail = 0;
	uint64_t e_power         = 0;
	int      radix           = 10;

	if(current() == '0') {
		if(peek_char() == 'x')
			radix = 16;
		else if(peek_char() == 'o')
			radix = 8;
		else if(peek_char() == 'b')
			radix = 2;
		else if(peek_char() != '.')
			Compiler::panic("[Line %lu] Unknown radix marker '%c'", m_line, peek_char());
		m_idx += 2;
	}

	while(!at_eof() && is_digit(current())) {
		if((current() == 'e' || current() == 'E') && radix == 10)
			break;

		uint64_t n = char_to_number(current());
		ASSERT(n < radix, "[Line %lu] Digit '%c' not in radix '%d'", m_line, current(), radix);

		decimal_lead *= radix;
		decimal_lead |= n;

		m_idx++;
	}

	f_num = decimal_lead;

	if(current() == '.') {
		ASSERT(radix == 10, "[Line %lu] Floating point numbers must be in base 10", m_line);
		is_float = true;
		m_idx++;

		int place = 1;

		while(!at_eof() && is_digit(current())) {
			uint64_t n = char_to_number(current());
			ASSERT(n < radix, "[Line %lu] Digit '%c' not in radix '%d'", m_line, current(), radix);

			fractional_tail *= radix;
			fractional_tail |= n;

			m_idx++;
			place++;
		}

		f_num += fractional_tail / pow(10, place);
	}

	if(current() == 'e' || current() == 'E') {
		ASSERT(radix == 10, "[Line %lu] Floating point numbers must be in base 10", m_line);
		is_float = true;
		m_idx++;

		while(!at_eof() && is_digit(current())) {
			uint64_t n = char_to_number(current());
			ASSERT(n < radix, "[Line %lu] Digit '%c' not in radix '%d'", m_line, current(), radix);

			e_power *= radix;
			e_power |= n;

			m_idx++;
		}

		f_num *= pow(10, e_power);
	}

	tk.set_end_idx(m_idx);

	if(is_float)
		tk.set_data_float(f_num);
	else
		tk.set_data_uint(i_num);

	return tk;
}

bool is_valid_ident_char(char c)
{
	return (c >= 'A' && c <= 'Z') ||
	       (c >= 'a' && c <= 'z') ||
	       (c == '_')             ||
	       is_digit(c);
}

static std::pair<char const*, TokenKind> keyword_map[] = {
	{ "decl",     TK_KW_DECL     },
	{ "let",      TK_KW_LET      },
	{ "struct",   TK_KW_STRUCT   },
	{ "enum",     TK_KW_ENUM     },
	{ "match",    TK_KW_MATCH    },
	{ "if",       TK_KW_IF       },
	{ "else",     TK_KW_ELSE     },
	{ "for",      TK_KW_FOR      },
	{ "while",    TK_KW_WHILE    },
	{ "loop",     TK_KW_LOOP     },
	{ "in",       TK_KW_IN       },
	{ "continue", TK_KW_CONTINUE },
	{ "break",    TK_KW_BREAK    },
	{ "return",   TK_KW_RETURN   },
	{ "as",       TK_KW_AS       },
	{ "nothing",  TK_TY_NOTHING  },
	{ "rawptr",   TK_TY_RAWPTR   },
	{ "bool",     TK_TY_BOOL     },
	{ "char",     TK_TY_CHAR     },
	{ "u8",       TK_TY_U8       },
	{ "i8",       TK_TY_I8       },
	{ "u16",      TK_TY_U16      },
	{ "i16",      TK_TY_I16      },
	{ "u32",      TK_TY_U32      },
	{ "i32",      TK_TY_I32      },
	{ "u64",      TK_TY_U64      },
	{ "i64",      TK_TY_I64      },
	{ "f32",      TK_TY_F32      },
	{ "f64",      TK_TY_F64      },
	{ "string",   TK_TY_STR      },
};

Token Lexer::tokenize_ident_or_keyword()
{
	ASSERT(is_valid_ident_char(current()), "[Line %lu] '%c' is not a valid identifier char", m_line, current());

	Token tk(TK_IDENT, m_idx, m_line);
	std::string str;

	while(!at_eof() && is_valid_ident_char(current())) {
		str.push_back(current());
		m_idx++;
	}

	tk.set_end_idx(m_idx);

	for(int i = 0; i < 30; i++) {
		auto const& [w, k] = keyword_map[i];
		if(str == w) {
			tk.set_kind(k);
		}
	}

	tk.set_str_data(str);
	return tk;
}
