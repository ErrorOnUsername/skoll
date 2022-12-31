#pragma once
#include "compiler.hh"

#define ASSERT(cond, msg...) \
	if(!(cond)) { \
		Compiler::panic(msg); \
	}
