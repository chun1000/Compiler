#ifndef STRUCT
#define STRUCT


typedef struct _token{
	char name[10];
	char value[25];
} token;

typedef struct _symbolTable{
	char id[17];
	double value;
	int hasValue;
} symbolTable;

#endif
