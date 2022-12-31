#include "lexer.hh"

#include <fstream>
#include <iostream>
#include <vector>

#define ROOT_WITH_SDA_FORM(l, bare_kind, copy_kind, assign_kind) \
	Token tk(TK_INVAL, m_idx, m_line); \
	m_idx++; \
	if(current() == l) { \
		m_idx++; \
		tk.set_kind(copy_kind); \
	} else if(current() == '=') { \
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
			case '=': { ROOT_WITH_SD_FORM('=', TK_ASSIGN, TK_EQ); }
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
			case '/': { ROOT_WITH_SD_FORM('=', TK_CARET, TK_STAR_ASSIGN); }

			case '+': return tokenize_plus();
			case '-': return tokenize_minus();

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
