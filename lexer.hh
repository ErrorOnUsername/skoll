#pragma once

#include <string>

#include "token.hh"

class Lexer {
public:
	Lexer(std::string const& path);

	Token next();

	char current();
	char peek_char(size_t offset = 1);
	bool at_eof();

	Token tokenize_string_literal();
	Token tokenize_char_literal();
	Token tokenize_number();
	Token tokenize_ident_or_keyword();

private:
	std::string m_file_data;

	size_t m_idx;
	size_t m_line;
};
