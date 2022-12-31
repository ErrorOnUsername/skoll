#include "compiler.hh"
#include <cstdio>
#include <cstdarg>
#include <cstdlib>

void Compiler::panic(const char* msg, ...)
{
	va_list args;
	va_start(args, msg);

	printf("\x1b[32;1m");
	vprintf(msg, args);
	printf("\x1b[0m");

	va_end(args);
	std::exit(1);
}
