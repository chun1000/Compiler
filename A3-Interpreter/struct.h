#ifndef STRUCT
#define STRUCT

typedef union _uval{
	int ival;
	double dval;
} uval;

typedef struct _symbolTable{
	char id[17];
	uval val;
	int isInteger; //-1 : Error(Unknown) 0 : double 1 : Integer
} symbolTable;

typedef struct _syntaxTree{
	char symbol;
	struct _syntaxTree** child;
	int childNum;
	int childTableSize;
	uval val;
	int isInteger; //-1 : Error(Unknown) 0 : double 1: Integer
} syntaxTree;

#endif
