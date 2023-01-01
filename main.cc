#include <iostream>
#include <filesystem>

#include "lexer.hh"
#include "parser.hh"

int main()
{
	std::string test_path = std::filesystem::canonical("../tests/test.amds");
	std::cout << "path: " << test_path << std::endl;

	Lexer lexer(test_path);

	std::cout << "tokens:" << std::endl;
	Token tk = lexer.next();

	while(tk.kind() != TK_EOF) {
		std::cout << tk.as_str() << " ";

		if(tk.kind() == TK_IDENT) {
			std::cout << tk.str_data();
		}

		std::cout << std::endl;
		tk = lexer.next();
	}
}
