#pragma once

#include <string>

#include "token.hh"

class Lexer {
public:
	Lexer(std::string const& path);

	Token next();

	char current();
	char peek_char(size_t offset = 1);

private:
	std::string m_file_data;

	size_t m_idx;
	size_t m_line;
};
