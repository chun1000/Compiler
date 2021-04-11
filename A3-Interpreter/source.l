%{
#include "y.tab.h"
#include <stdlib.h>
#include "struct.h"

extern symbolTable* st;
int lineCounter = 1;
int isLexicalError = 0;
int symbolIndex = 1;
int symbol_table_size = 4;

char* cutDouble(char* input);
int putSymbolTable(char *input);

%}
PRINT print
WHILE while
IF if
ELSE else
LPAREN \(
RPAREN \)
LBRAKET \{
RBRAKET \}
COMMA ,
SEMI ;
PLUSOP \+
MINUSOP -
MULTOP \*
DIVOP \/
NEWLINE \n
WHITESPACE (\ |\t)+
SINGLECOMMENT \/\/.*
MULTICOMMENT \/\*([^\*]|(\*+[^\*\/]))*\*+\/
GE >=
GT >
LE <=
LT <
EQ ==
NE !=
ASSIGNOP =
ID ([a-zA-Z]|(_+([a-zA-Z]|[0-9])))([a-zA-Z_]|[0-9])*
INTEGER (([1-9][0-9]*)|0)
DOUBLE [0-9]+(((\.[0-9]+E)|E)((\+|-)?[0-9]+)|\.[0-9]+)


%%
{PRINT} return PRINT;
{WHILE} return WHILE;
{IF} return IF;
{ELSE} return ELSE;
{LPAREN} return yytext[0];
{RPAREN} return yytext[0];
{LBRAKET} return yytext[0];
{RBRAKET} return yytext[0];
{COMMA} return yytext[0];
{SEMI} return yytext[0];
{PLUSOP} return yytext[0];
{MINUSOP} return yytext[0];
{MULTOP} return yytext[0];
{DIVOP} return yytext[0];
{WHITESPACE} ; //do nothing
{SINGLECOMMENT} ;
{MULTICOMMENT} ;
{GE} return GE;
{GT} return GT;
{LE} return LE;
{LT} return LT;
{EQ} return EQ;
{NE} return NE;
{ASSIGNOP} return yytext[0];
{ID} {
		yylval.inum = putSymbolTable(yytext);
		return ID;
	 }
{INTEGER} {
			char val[20]; int i;
			if(yyleng >= 16) 
			{
				for(i=16; i >=0; i--) val[i] = yytext[yyleng-(16-i)];
				yylval.inum = atoi(val);
			}
			else yylval.inum = atoi(yytext);
			return INTEGER;
		  }
{DOUBLE} {
			char *str; double tmp;
			str = cutDouble(yytext);
			tmp = atof(str);
			yylval.dnum = tmp;
			free(str);
			return DOUBLE;
		 }
{NEWLINE} lineCounter++;
. {isLexicalError = 1; fprintf(stderr, "[Lexical Error]: line %d\n", lineCounter);}

%%

void initTable()
{
	st = (symbolTable*)malloc(sizeof(symbolTable)*symbol_table_size);
}

int putSymbolTable(char* input)
{

	int index, i;
	char *idBuffer = (char*)malloc(sizeof(char)*17);

	if(symbolIndex >=  symbol_table_size)
	{
		int before_size = symbol_table_size;
		symbol_table_size *= 2;
		st = (symbolTable*)realloc(st, sizeof(symbolTable)*symbol_table_size);
	}
	
	strncpy(idBuffer, input, 16);
	idBuffer[16] = '\0';

	for(i=1; i<symbolIndex; i++)
	{
		if(strcmp(idBuffer, st[i].id)==0)
		{
			free(idBuffer);
			return i;
		}
	}
	
	strcpy(st[symbolIndex].id, idBuffer);
	st[symbolIndex].isInteger = -1;
	free(idBuffer);
	symbolIndex++;
	
	index = symbolIndex -1;
	return index;
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
