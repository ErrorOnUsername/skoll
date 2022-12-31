cmake_minimum_required( VERSION 3.9 )
project( amds CXX )

set( CMAKE_EXPORT_COMPILE_COMMANDS 1 )
set( CMAKE_CXX_STANDARD 20 )

set( SRCS
	compiler.cc
	main.cc
	lexer.cc
	parser.cc
	token.cc
)

add_executable( amds ${SRCS} )

add_custom_target( run
	COMMAND ./amds
	VERBATIM
	DEPENDS amds
)
