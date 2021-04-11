%{
#define LPAREN 1
#define RPAREN 2
#define LBRAKET 3
#define RBRAKET 4
#define COMMA 5
#define SEMI 6
#define PLUSOP 7
#define MINUSOP 8
#define MULTOP 9
#define DIVOP 10
#define WHITESPACE 11
#define SINGLECOMMENT 12
#define MULTICOMMENT 13
#define GE 14
#define GT 15
#define LE 16
#define LT 17
#define EQ 18
#define NE 19
#define ASSIGNOP 20
#define ID 21
#define INTEGER 22
#define DOUBLE 23
#define STRING 24
#define UNKNOWN 25
#define KEY_NUM 8

int symbolIndex = 1, stringIndex = 1;
int symbol_table_size = 4; int string_table_size = 4;
int lineCount = 1;

char **symbol_table;
char **string_table;

typedef struct _token{
	char name[10];
	char value[25];
} token;

typedef struct _keyword_table {
	char keyword[15];
	char token[15];
} keyword_table;

keyword_table keyword[KEY_NUM] = {{"int", "INT"}, {"double", "DOUBLE"}, {"str", "STR"}, {"print", "PRINT"}, {"return", "RETURN"}, {"if", "IF"}, {"else", "ELSE"}, {"while", "WHILE"}};
%}

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
WHITESPACE (\ |\t|\n)+
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
INTEGER [0-9]+
DOUBLE [0-9]+(((\.[0-9]+E)|E)((\+|-)?[0-9]+)|\.[0-9]+)
STRING \"([^\n\"]|(\\(.|\n)))*\"

%%
{LPAREN} return LPAREN;
{RPAREN} return RPAREN;
{LBRAKET} return LBRAKET;
{RBRAKET} return RBRAKET;
{COMMA} return COMMA;
{SEMI} return SEMI;
{PLUSOP} return PLUSOP;
{MINUSOP} return MINUSOP;
{MULTOP} return MULTOP;
{DIVOP} return DIVOP;
{WHITESPACE} return WHITESPACE;
{SINGLECOMMENT} {return SINGLECOMMENT;}
{MULTICOMMENT} return MULTICOMMENT;
{GE} return GE;
{GT} return GT;
{LE} return LE;
{LT} return LT;
{EQ} return EQ;
{NE} return NE;
{ASSIGNOP} return ASSIGNOP;
{ID} return ID;
{INTEGER} return INTEGER;
{DOUBLE} return DOUBLE;
{STRING} return STRING;
. return UNKNOWN;
%%

int countNewLine(char *input)
{
	int i, count;
	for(i=0; i<yyleng; i++)
	{
		if(input[i] == '\n') count++;
	}
	return count;
}

void initTable()
{
	symbol_table = (char**)malloc(sizeof(char**)*symbol_table_size);
	string_table = (char**)malloc(sizeof(char**)*string_table_size);

	int i;

	for(i = 1; i<symbol_table_size; i++) symbol_table[i] = (char*)calloc(17,sizeof(char));
}

int isKeyword(char *input)
{
	int i;
	for(i=0; i < KEY_NUM; i++)
	{
		if(strcmp(input, keyword[i].keyword) == 0)
		{
			return i;
		}
	}
	return -1;
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
		symbol_table = (char**)realloc(symbol_table, sizeof(char*)*symbol_table_size);

		for(i = before_size; i<symbol_table_size; i++)
		{
			symbol_table[i] = (char*)calloc(17,sizeof(char));
		}
	}
	
	strncpy(idBuffer, input, 16);
	idBuffer[16] = '\0';

	for(i=1; i<symbolIndex; i++)
	{
		if(strcmp(idBuffer, symbol_table[i])==0)
		{
			sprintf(str, "%d", i);
			free(idBuffer);
			return str;
		}
	}
	
	strcpy(symbol_table[symbolIndex], idBuffer);
	free(idBuffer);
	symbolIndex++;
	
	sprintf(str, "%d", symbolIndex-1);
	return str;
}

char* putStringTable(char *input)
{
	int i;
	char *str = (char*)malloc(sizeof(char)*25);
	for(i=1; i<stringIndex; i++)
	{
		if(strcmp(input, string_table[i]) == 0)
		{
			sprintf(str, "%d", i);
			return str;
		}
	}

	if(stringIndex >= string_table_size)
	{
		int before_size = string_table_size;
		string_table_size *= 2;
		string_table = (char**)realloc(string_table, sizeof(char*)*string_table_size);
	}

	string_table[stringIndex] = (char*)calloc(yyleng+1, sizeof(char));
	strcpy(string_table[stringIndex], input);
	stringIndex++;
	sprintf(str, "%d", stringIndex-1);
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

char*  processMultilineString(char* input)
{
	char* output; char* ptr;
	output = (char*)calloc(yyleng+1, sizeof(char));
	int inputIndex = 1, outputIndex =0;

	while(inputIndex <  yyleng)
	{
		if(input[inputIndex] == '\\' && input[inputIndex+1] == '\n')
		{
			inputIndex += 2;
			lineCount++;
		}
		else 
		{
			output[outputIndex++] = input[inputIndex++];
		}
	}

	output[strlen(output)-1] = '\0';
	return output;

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
		case LPAREN:
			strcpy(t.name, "LPAREN");
			break;
		case RPAREN:
			strcpy(t.name, "RPAREN");
			break;
		case LBRAKET:
			strcpy(t.name, "LBRAKET");
			break;
		case RBRAKET:
			strcpy(t.name, "RBRAKET");
			break;
		case COMMA:
			strcpy(t.name, "COMMA");
			break;
		case SEMI:
			strcpy(t.name, "SEMI");
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
		case GE:
			strcpy(t.name, "RELOP");
			strcpy(t.value, "GE");
			break;
		case GT:
			strcpy(t.name, "RELOP");
			strcpy(t.value, "GT");
			break;
		case LE:
			strcpy(t.name, "RELOP");
			strcpy(t.value, "LE");
			break;
		case LT:
			strcpy(t.name, "RELOP");
			strcpy(t.value, "LT");
			break;
		case EQ:
			strcpy(t.name, "RELOP");
			strcpy(t.value, "EQ");
			break;
		case NE:
			strcpy(t.name, "RELOP");
			strcpy(t.value, "NE");
			break;
		case ASSIGNOP:
			strcpy(t.name, "ASSIGNOP");
			break;
		case ID:
			if(isKeyword(yytext)==-1)
			{
				strcpy(t.name, "ID");
				
				str = putSymbolTable(yytext);
				strcpy(t.value, str);
				free(str);
			}
			else
			{
				strcpy(t.name, keyword[isKeyword(yytext)].token);
			}
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
		case STRING:
			strcpy(t.name, "STRING");
			buf = processMultilineString(yytext);
			str = putStringTable(buf);
			strcpy(t.value, str);
			free(buf);
			free(str);
			break;
		case SINGLECOMMENT:
			strcpy(t.name, "COMMENTS");
			break;
		case MULTICOMMENT:
			strcpy(t.name, "COMMENTS");
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
		printf("%d\t\t\"%s\"\n", i, symbol_table[i]);
	}

	for(i=1; i<symbol_table_size; i++) free(symbol_table[i]);

	free(symbol_table);
}

void printStringTable()
{
	int i;
	printf("index\t\tstrings\n");

	for(i=1; i<stringIndex; i++)
	{
		printf("%d\t\t%s\n", i, string_table[i]);
	}

	for(i=1; i<stringIndex; i++) free(string_table[i]);
	free(string_table);
}

int main(int argc, char* argv[])
{
	initTable();
	if(argc > 1) 
	{
		FILE* fp;
		fp = fopen(argv[1], "r");
		if(!fp)
		{
			fprintf(stderr, "ERROR: CANNOT OPEN FILE\n");
			exit(1);
		}
		yyin = fp;
	}

	int val; token tok;
	printf("TOKEN\t\tLEXEME\n");

	while((val=yylex())!= 0)
	{	
		if(val==WHITESPACE)
		{
			lineCount += countNewLine(yytext);
		}
		else if(val == MULTICOMMENT)
		{
			lineCount += countNewLine(yytext);
		}
		else if(val == UNKNOWN)
		{
			fprintf(stderr, "ERROR: [line:%d] CANNONT RECOGNIZE TOKEN: %s\n",lineCount,  yytext);
		}
		else if(val == INTEGER)
		{
			if(isDecimalNum(yytext))
			{
				tok = getToken(val);
				printToken(tok);
			}
			else
			{
				fprintf(stderr, "ERROR: [line:%d] NOT DECIMAL NUMBER %s\n", lineCount, yytext);
			}
		}
		else
		{
			
			tok = getToken(val);
			printToken(tok);
		}
	}
	printf("\n\n-------------------------SYMBOL-TABLE---------------------------\n\n");
	printSymbolTable();
	printf("\n\n-------------------------STRING-TABLE---------------------------\n\n");
	printStringTable();

	return 0;
}
