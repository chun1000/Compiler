%{
#include "struct.h"
#define LPAREN 1
#define RPAREN 2
#define PLUSOP 3
#define MINUSOP 4
#define MULTOP 5
#define DIVOP 6
#define ASSIGNOP 7
#define WHITESPACE 8
#define ID 9
#define INTEGER 10
#define DOUBLE 11
#define NEWLINE 12
#define UNKNOWN 13


int symbolIndex = 1;
int symbol_table_size = 4;
int isLexError;
//char **symbol_table;
symbolTable *symbol_table;
%}

LPAREN \(
RPAREN \)
PLUSOP \+
MINUSOP -
MULTOP \*
DIVOP \/
WHITESPACE (\ |\t)+
ASSIGNOP =
ID ([a-zA-Z]|(_+([a-zA-Z]|[0-9])))([a-zA-Z_]|[0-9])*
INTEGER [0-9]+
DOUBLE [0-9]+(((\.[0-9]+E)|E)((\+|-)?[0-9]+)|\.[0-9]+)
NEWLINE \n

%%
{LPAREN} return LPAREN;
{RPAREN} return RPAREN;
{PLUSOP} return PLUSOP;
{MINUSOP} return MINUSOP;
{MULTOP} return MULTOP;
{DIVOP} return DIVOP;
{WHITESPACE} return WHITESPACE;
{ASSIGNOP} return ASSIGNOP;
{ID} return ID;
{INTEGER} return INTEGER;
{DOUBLE} return DOUBLE;
{NEWLINE} return NEWLINE;
. return UNKNOWN;
%%


void initTable()
{
	int i;
	symbol_table = (symbolTable*)malloc(sizeof(symbolTable)*symbol_table_size);
	for(i =1; i < symbol_table_size; i++) 
	{
		symbol_table[i].hasValue = 0;
	}

	/* old version symboltable;
	symbol_table = (char**)malloc(sizeof(char**)*symbol_table_size);
	int i;
	for(i = 1; i<symbol_table_size; i++) symbol_table[i] = (char*)calloc(17,sizeof(char));
	*/
}

char* putSymbolTable(char* input)
{
	int i;
	char *str = (char*)malloc(sizeof(char)*25);
	char *idBuffer = (char*)malloc(sizeof(char)*17);

	if(symbolIndex >=  symbol_table_size)
	{
		int before_size = symbol_table_size;
		symbol_table_size *= 2;
		symbol_table = (symbolTable*)realloc(symbol_table, sizeof(symbolTable)*symbol_table_size);
		
		/* old version symboltable;
		symbol_table = (char**)realloc(symbol_table, sizeof(char*)*symbol_table_size);

		for(i = before_size; i<symbol_table_size; i++)
		{
			symbol_table[i] = (char*)calloc(17,sizeof(char));
		}
		*/
	}
	
	strncpy(idBuffer, input, 16);
	idBuffer[16] = '\0';

	for(i=1; i<symbolIndex; i++)
	{
		if(strcmp(idBuffer, symbol_table[i].id)==0)
		{
			sprintf(str, "%d", i);
			free(idBuffer);
			return str;
		}
	}
	
	strcpy(symbol_table[symbolIndex].id, idBuffer);
	free(idBuffer);
	symbolIndex++;
	
	sprintf(str, "%d", symbolIndex-1);
	return str;
}

char* cutDouble(char* input)
{
	int inputIndex = 0;
	int strIndex = 0;
	int sig = 0;
	int exp = 0;
	char* str = (char*)malloc(sizeof(char)*25);
	while((inputIndex < yyleng)&&(input[inputIndex] != 'E'))
	{
		if((input[inputIndex] >= '0')&&(input[inputIndex] <= '9')) sig++;
		

		if(sig <= 17) str[strIndex++] = input[inputIndex++];
		else inputIndex++;
	}
	
	str[strIndex++] = input[inputIndex++]; //put E
	while(inputIndex < yyleng && strIndex < 25)
	{
		str[strIndex++] = input[inputIndex++];
	}
	
	str[24] = '\0';
	return str;
}

int isDecimalNum(char *input)
{
	if(input[0] == '0' && strlen(input) > 2) return 0;
	else return 1;
}

token getToken(int type)
{
	int i, tmp;
	token t;
	strcpy(t.name, "");
	strcpy(t.value, "");
	char *str; char* buf;

	switch(type)
	{
		case WHITESPACE:
			break;
		case LPAREN:
			strcpy(t.name, "LPAREN");
			break;
		case RPAREN:
			strcpy(t.name, "RPAREN");
			break;
		case PLUSOP:
			strcpy(t.name, "PLUSOP");
			break;
		case MINUSOP:
			strcpy(t.name, "MINUSOP");
			break;
		case DIVOP:
			strcpy(t.name, "DIVOP");
			break;
		case MULTOP:
			strcpy(t.name, "MULTOP");
			break;
		case ASSIGNOP:
			strcpy(t.name, "ASSIGNOP");
			break;
		case ID:
				strcpy(t.name, "ID");	
				str = putSymbolTable(yytext);
				strcpy(t.value, str);
				free(str);
			break;
		case INTEGER:
			strcpy(t.name, "INTEGER");
			if( yyleng >= 16)
			{
				for(i=16; i >= 0; i--)
				{
					t.value[i] = yytext[yyleng-(16-i)];
				}
			}
			else strcpy(t.value, yytext);
			break;
		case DOUBLE:
			strcpy(t.name, "DOUBLE");
			str = cutDouble(yytext);
			strcpy(t.value, str);
			free(str);
			break;
		case NEWLINE:
			strcpy(t.name, "NEWLINE");
			break;
		default:
			break;
	}

	return t;
}

void printToken(token t)
{
	printf("<%s, %s>", t.name, t.value);
	printf("\t\t%s\n", yytext);
}

void printSymbolTable()
{
	int i;
	char teststr[256];
	printf("index\t\tsymbols\n");
	for(i=1; i<symbolIndex; i++)
	{
		printf("%d\t\t\"%s\"\n", i, symbol_table[i].id);
	}
	free(symbol_table);
}

token analysisLex(int val)
{
	token tok;
	strcpy(tok.name, "");
	strcpy(tok.value, "");
	if(val == UNKNOWN) isLexError = 1;
	else if(val == INTEGER)
	{
		if(isDecimalNum(yytext)) tok = getToken(val);
		else isLexError = 1;
	}
	else tok = getToken(val);

	return tok;
}


/*
int main(int argc, char* argv[])
{
	initTable();

	int val; token tok;
	while((val=yylex())!=0)
	{
		tok = analysisLex(val);
		printToken(tok);
	}



	printf("\n\n-------------------------SYMBOL-TABLE---------------------------\n\n");
	printSymbolTable();

	return 0;
}

*/
