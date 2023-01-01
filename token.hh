#pragma once

#include <cstddef>
#include <cstdint>
#include <string>

struct Span {
	size_t start_idx;
	size_t start_line;
	size_t end_idx;
	size_t end_line;
};

enum TokenKind {
	TK_INVAL,
	TK_EOF,
	TK_EOL,

	TK_IDENT,
	TK_STR_LIT,
	TK_CHAR_LIT,
	TK_NUMBER,
	TK_BOOL_LIT,

	TK_L_PAREN,
	TK_R_PAREN,
	TK_L_CURLY,
	TK_R_CURLY,
	TK_L_SQUARE,
	TK_R_SQUARE,
	TK_L_ANGLE,
	TK_R_ANGLE,
	TK_ASSIGN,
	TK_COLON,
	TK_DOUBLE_COLON,
	TK_COLON_ASSIGN,
	TK_SEMICOLON,
	TK_THIN_ARROW,
	TK_THICC_ARROW,
	TK_DOLLAR,
	TK_COMMA,
	TK_DOT,
	TK_DOT_DOT,
	TK_HASH,
	TK_BANG,
	TK_QUESTION_MARK,
	TK_TILDE,
	TK_TILDE_ASSIGN,
	TK_AMPERSAND,
	TK_AMPERSAND_ASSIGN,
	TK_DOUBLE_AMPERSAND,
	TK_PIPE,
	TK_PIPE_ASSIGN,
	TK_DOUBLE_PIPE,
	TK_CARET,
	TK_CARET_ASSIGN,
	TK_DOUBLE_CARET,

	TK_R_SHIFT,
	TK_R_SHIFT_ASSIGN,
	TK_L_SHIFT,
	TK_L_SHIFT_ASSIGN,
	TK_LEQ,
	TK_GEQ,
	TK_EQ,
	TK_NEQ,

	TK_MINUS,
	TK_MINUS_MINUS,
	TK_MINUS_ASSIGN,
	TK_PLUS,
	TK_PLUS_PLUS,
	TK_PLUS_ASSIGN,
	TK_STAR,
	TK_STAR_ASSIGN,
	TK_SLASH,
	TK_SLASH_ASSIGN,
	TK_PERCENT,
	TK_PERCENT_ASSIGN,

	TK_KW_DECL,
	TK_KW_LET,
	TK_KW_STRUCT,
	TK_KW_ENUM,
	TK_KW_MATCH,
	TK_KW_IF,
	TK_KW_ELSE,
	TK_KW_FOR,
	TK_KW_WHILE,
	TK_KW_LOOP,
	TK_KW_IN,
	TK_KW_CONTINUE,
	TK_KW_BREAK,
	TK_KW_RETURN,
	TK_KW_AS,
};

enum NumberKind {
	NK_NONE,
	NK_FLOAT,
	NK_UINT,
	NK_INT,
};

struct ParsedNumber {
	NumberKind kind;
	union {
		double   foating_point;
		uint64_t uint;
		int64_t  sint;
	};
};

union TokenData {
	std::string  str;
	ParsedNumber number;

	TokenData()
		: str()
	{ }

	TokenData(TokenData const& o)
	{
		if(o.number.kind == NK_NONE)
			str = o.str;
		else
			number = o.number;
	}

	~TokenData() {}
};

class Token {
public:
	Token(TokenKind kind, size_t start_idx, size_t start_line)
		: m_kind(kind)
		, m_span(Span {
			.start_idx = start_idx,
			.start_line = start_line,
			.end_idx = 0,
			.end_line = 0,
		})
		, m_data()
	{ }

	inline TokenKind kind() const { return m_kind; }
	inline void set_kind(TokenKind kind) { m_kind = kind; }

	inline Span& span() { return m_span; }

	inline size_t start_idx() const { return m_span.start_idx; }
	inline void   set_start_idx(size_t idx) { m_span.start_idx = idx; }
	inline size_t start_line() const { return m_span.start_line; }
	inline void   set_start_line(size_t line) { m_span.start_line= line; }

	inline size_t end_idx() const { return m_span.end_idx; }
	inline void   set_end_idx(size_t idx) { m_span.end_idx = idx; }
	inline size_t end_line() const { return m_span.end_line; }
	inline void   set_end_line(size_t line) { m_span.end_line= line; }

	inline void set_data_str(std::string&& str)
	{
		m_data.number.kind = NK_NONE;
		m_data.str = std::move(str);
	}

	inline void set_data_float(double f)
	{
		m_data.number.kind = NK_FLOAT;
		m_data.number.foating_point = f;
	}

	inline void set_data_uint(uint64_t u)
	{
		m_data.number.kind = NK_UINT;
		m_data.number.uint = u;
	}

	inline void set_data_int(int64_t i)
	{
		m_data.number.kind = NK_INT;
		m_data.number.uint = i;
	}

private:
	TokenKind m_kind;
	Span m_span;

	TokenData m_data;
};

namespace std {
	string to_string(Token tk);
}
