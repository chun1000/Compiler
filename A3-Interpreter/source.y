%{
#include <stdio.h>
#include <stdlib.h>
#include "struct.h"
#include <string.h>


extern int yylex();
extern int yyerror();
extern void initTable();
extern int symbolIndex;
extern int lineCounter;
extern int isLexicalError;
int isSyntaxError = 0;
int syntaxErrorLine;
extern FILE* yyin;
symbolTable *st;
syntaxTree *prgm;

syntaxTree *makeNode(char symbol);
syntaxTree *makeLeaf(char *type, uval val);
void addChild(syntaxTree *parent, syntaxTree *child);

%}
 
%union {
	int inum;
	double dnum;
	struct _syntaxTree *node;
}

%token GE   
%token GT   
%token LE   
%token LT   
%token EQ   
%token NE   
%token WHILE
%token IF
%token ELSE
%token PRINT
%token <inum> ID 
%token <inum> INTEGER 
%token <dnum> DOUBLE 

%type <node> stmts
%type <node> stmt
%type <node> assign
%type <node> block
%type <node> whileStmt
%type <node> ifStmt
%type <node> printStmt
%type <node> equrel
%type <node> cmprel
%type <node> expr
%type <node> term
%type <node> factor


%%

start : stmts { prgm = $1;}
	  ;

stmts : stmts stmt {addChild($1, $2); $$ = $1;} 
	  | {syntaxTree *tmp = makeNode('s'); $$ = tmp;}
	  ;

stmt : assign ';' {syntaxTree *tmp = makeNode('a'); addChild(tmp, $1); $$ = tmp;}
	 | block
	 | whileStmt
	 | ifStmt
	 | printStmt {/* do nothing */}
	 | ';' {syntaxTree *tmp = makeNode('s'); $$ = tmp;}
	 | error ';'  { syntaxTree *tmp = makeNode('s'); $$ = tmp;}
	 ; 

whileStmt : WHILE '(' assign ')' stmt {syntaxTree *atmp = makeNode('a'); addChild(atmp, $3); syntaxTree *tmp = makeNode('w'); addChild(tmp, atmp); addChild(tmp, $5); $$ = tmp;}
		  ;

ifStmt : IF '(' assign ')' stmt ELSE stmt {syntaxTree *atmp = makeNode('a'); addChild(atmp, $3); syntaxTree *tmp = makeNode('i'); addChild(tmp, atmp); addChild(tmp, $5); addChild(tmp, $7); $$ = tmp;}
	   ;

printStmt : PRINT assign ';' {syntaxTree *tmp = makeNode('a'); addChild(tmp, $2); syntaxTree *tmp2 = makeNode('p'); addChild(tmp2, tmp); $$ = tmp2;}

block : '{' stmts '}' {$$ = $2;}
	  ;
 

assign : ID '=' assign {syntaxTree *tmp = makeNode('='); uval val; val.ival = $1; syntaxTree *idNode = makeLeaf("ID", val);  addChild(tmp, idNode); addChild(tmp, $3); $$ = tmp;} 
	   | equrel {$$ = $1;}
	   ;
equrel : equrel GE cmprel {syntaxTree *tmp = makeNode('G'); addChild(tmp, $1); addChild(tmp, $3); $$ = tmp;}
	   | equrel GT cmprel {syntaxTree *tmp = makeNode('g'); addChild(tmp, $1); addChild(tmp, $3); $$ = tmp;}
	   | equrel LE cmprel {syntaxTree *tmp = makeNode('L'); addChild(tmp, $1); addChild(tmp, $3); $$ = tmp;}
	   | equrel LT cmprel {syntaxTree *tmp = makeNode('l'); addChild(tmp, $1); addChild(tmp, $3); $$ = tmp;}
	   | cmprel {$$ = $1;}
	   ;

cmprel : cmprel EQ expr {syntaxTree *tmp = makeNode('e'); addChild(tmp, $1); addChild(tmp, $3); $$ = tmp;}
	   | cmprel NE expr { syntaxTree *tmp = makeNode('n'); addChild(tmp, $1); addChild(tmp, $3); $$ = tmp;}
	   | expr { $$ = $1;}
	   ;

expr : expr '+' term {syntaxTree *tmp = makeNode('+'); addChild(tmp, $1); addChild(tmp, $3); $$ = tmp;}
	 | expr '-' term {syntaxTree *tmp = makeNode('-'); addChild(tmp, $1); addChild(tmp, $3); $$ = tmp;}
	 | term {$$ = $1;}
	 ;

term : term '*' factor {syntaxTree *tmp = makeNode('*'); addChild(tmp, $1); addChild(tmp, $3); $$ = tmp;}
	 | term '/' factor {syntaxTree *tmp = makeNode('/'); addChild(tmp, $1); addChild(tmp, $3); $$ = tmp;}
	 | factor {$$ = $1;}
	 ;

factor : '(' assign ')' {$$ = $2;}
	   | DOUBLE {uval val; val.dval = $1; $$ = makeLeaf("DOUBLE", val);}
	   | INTEGER {uval val; val.ival = $1;  $$ = makeLeaf("INTEGER", val);}
	   | ID {uval val; val.ival = $1; $$ = makeLeaf("ID", val); } 
	   ;


%%


syntaxTree *makeNode(char symbol)
{
	syntaxTree* node = (syntaxTree*)malloc(sizeof(syntaxTree));
	node->symbol = symbol;
	node->child = (syntaxTree**)malloc(sizeof(syntaxTree*)*2);
	node->child[0] = NULL; node->child[1] = NULL;
	node->childNum = 0;
	node->childTableSize = 2;
	node->isInteger = -1;
}

syntaxTree *makeLeaf(char *type, uval val)
{
	syntaxTree* node = (syntaxTree*)malloc(sizeof(syntaxTree));
	node->childNum = 0;
	node->child = NULL;
	node->childTableSize = 0;

	if(strcmp(type, "INTEGER") == 0)
	{
		node->symbol = '#';
		node->val.ival = val.ival;
		node->isInteger = 1;
	}
	else if(strcmp(type, "DOUBLE") == 0)
	{
		node->symbol = '#';
		node->val.dval = val.dval;
		node->isInteger = 0;
	}
	else if(strcmp(type, "ID") == 0)
	{
		node->symbol = '@';
		node->val.ival = val.ival;
		node->isInteger = -1;
	}

	return node;
}

void addChild(syntaxTree *parent, syntaxTree *child)
{
	if(parent->childNum >= parent->childTableSize)
	{
		parent->childTableSize *= 2;
		parent->child = (syntaxTree**)realloc(parent->child, sizeof(syntaxTree*)*parent->childTableSize);
	}

	parent->child[parent->childNum] = child;
	parent->childNum += 1;
}

void freeTree(syntaxTree *node)
{
	int i;
	for(i=0; i<node->childNum;i++) freeTree(node->child[i]);
	free(node->child);
	free(node);
}

uval getValueOfId(int index, int *isInteger)
{
	if(st[index].isInteger == 0)
	{
		*isInteger = 0;
		return st[index].val;
	}
	else if(st[index].isInteger == 1)
	{
		*isInteger = 1;
		return st[index].val;
	}
	else
	{
		uval val;
		val.ival = 0;
		*isInteger = 1;
		return val;
	}
}

void copyNodeForCalculate(syntaxTree *dest, syntaxTree *source)
{
	dest->symbol = source->symbol;
	dest->val = source->val;
	dest->isInteger = source->isInteger;
}


void processChildNodeForCalculate(syntaxTree *calNode1, syntaxTree *calNode2)
{
	int i;

	if(calNode1->symbol == '@')
	{
		calNode1->symbol = '#';
		calNode1->val = getValueOfId(calNode1->val.ival, &(calNode1->isInteger));

	}
	if(calNode2->symbol == '@')
	{
		calNode2->symbol = '#';
		calNode2->val = getValueOfId(calNode2->val.ival, &(calNode2->isInteger));
	}
	
	if(calNode1->isInteger == 0 && calNode2->isInteger == 1)
	{
		calNode2->isInteger = 0;
		calNode2->val.dval = (double)calNode2->val.ival;
	}
	else if(calNode1->isInteger == 1 && calNode2->isInteger ==0)
	{
		calNode1->isInteger = 0;
		calNode1->val.dval = (double)calNode1->val.ival;
	}
}

void recursiveTreeProcessing(syntaxTree *node);
void processExpression(char symbol, syntaxTree *node)
{
		recursiveTreeProcessing(node->child[0]);
		recursiveTreeProcessing(node->child[1]);

		syntaxTree *calNode1 = (syntaxTree*)malloc(sizeof(syntaxTree));
		syntaxTree *calNode2 = (syntaxTree*)malloc(sizeof(syntaxTree));

		copyNodeForCalculate(calNode1, node->child[0]);
		copyNodeForCalculate(calNode2, node->child[1]);

		processChildNodeForCalculate(calNode1, calNode2);

		switch(symbol)
		{
		case '+':
			if(calNode1->isInteger == 0)
			{
				node->isInteger = 0;
				node->val.dval = calNode1->val.dval + calNode2->val.dval;
			}
			else
			{
				node->isInteger = 1;
				node->val.ival = calNode1->val.ival + calNode2->val.ival;
			}
			free(calNode1); free(calNode2);
			break;
		case '-':
			if(calNode1->isInteger == 0)
			{
				node->isInteger = 0;
				node->val.dval = calNode1->val.dval - calNode2->val.dval;
			}
			else
			{
				node->isInteger = 1;
				node->val.ival = calNode1->val.ival - calNode2->val.ival;
			}
			free(calNode1); free(calNode2);
			break;
		case '/':
			if(calNode1->isInteger == 0)
			{
				node->isInteger = 0;
				node->val.dval = calNode1->val.dval / calNode2->val.dval;
			}
			else
			{
				node->isInteger = 1;
				node->val.ival = calNode1->val.ival / calNode2->val.ival;
			}
			free(calNode1); free(calNode2);
			break;
		case '*':
			if(calNode1->isInteger == 0)
			{
				node->isInteger = 0;
				node->val.dval = calNode1->val.dval * calNode2->val.dval;
			}
			else
			{
				node->isInteger = 1;
				node->val.ival = calNode1->val.ival * calNode2->val.ival;
			}
			free(calNode1); free(calNode2);
			break;
		case 'g': //>
			if(calNode1->isInteger == 0)
			{
				node->isInteger = 1;
				if(calNode1->val.dval > calNode2->val.dval) node->val.ival = 1;
				else node->val.ival = 0;
			}
			else
			{
				node->isInteger = 1;
				if(calNode1->val.ival > calNode2->val.ival) node->val.ival = 1;
				else node->val.ival = 0;
			}
			free(calNode1); free(calNode2);
			break;
		case 'G': //>=
			if(calNode1->isInteger == 0)
			{
				node->isInteger = 1;
				if(calNode1->val.dval >= calNode2->val.dval) node->val.ival = 1;
				else node->val.ival = 0;
			}
			else
			{
				node->isInteger = 1;
				if(calNode1->val.ival >= calNode2->val.ival) node->val.ival = 1;
				else node->val.ival = 0;
			}
			free(calNode1); free(calNode2);
			break;
		case 'l': //<
			if(calNode1->isInteger == 0)
			{
				node->isInteger = 1;
				if(calNode1->val.dval < calNode2->val.dval) node->val.ival = 1;
				else node->val.ival = 0;
			}
			else
			{
				node->isInteger = 1;
				if(calNode1->val.ival < calNode2->val.ival) node->val.ival = 1;
				else node->val.ival = 0;
			}
			free(calNode1); free(calNode2);
			break;
		case 'L': //<=
			if(calNode1->isInteger == 0)
			{
				node->isInteger = 1;
				if(calNode1->val.dval <= calNode2->val.dval) node->val.ival = 1;
				else node->val.ival = 0;
			}
			else
			{
				node->isInteger = 1;
				if(calNode1->val.ival <= calNode2->val.ival) node->val.ival = 1;
				else node->val.ival = 0;
			}
			free(calNode1); free(calNode2);
			break;
		case 'e': //==
			if(calNode1->isInteger == 0)
			{
				node->isInteger = 1;
				if(calNode1->val.dval == calNode2->val.dval) node->val.ival = 1;
				else node->val.ival = 0;
			}
			else
			{
				node->isInteger = 1;
				if(calNode1->val.ival == calNode2->val.ival) node->val.ival = 1;
				else node->val.ival = 0;
			}
			free(calNode1); free(calNode2);
			break;
		case 'n': //!=
			if(calNode1->isInteger == 0)
			{
				node->isInteger = 1;
				if(calNode1->val.dval != calNode2->val.dval) node->val.ival = 1;
				else node->val.ival = 0;
			}
			else
			{
				node->isInteger = 1;
				if(calNode1->val.ival != calNode2->val.ival) node->val.ival = 1;
				else node->val.ival = 0;
			}
			free(calNode1); free(calNode2);
			break;
		}

}

void recursiveTreeProcessing(syntaxTree *node)
{
	int i, isInteger;

	switch(node->symbol)
	{
	case 's': //stmts
		for(i = 0; i < node->childNum; i++)
		{
			recursiveTreeProcessing(node->child[i]);
		}
		break;
	case 'a': //expression statment
		recursiveTreeProcessing(node->child[0]);
		if(node->child[0]->symbol == '@')
		{
			node->val = getValueOfId(node->child[0]->val.ival, &(node->isInteger));
		}
		else if(node->child[0]->isInteger == 0)
		{
			node->val.dval = node->child[0]->val.dval;
			node->isInteger = 0;
		}
		else
		{
			node->val.ival = node->child[0]->val.ival;
			node->isInteger = 1;
		}
		break;
	case '+':
		processExpression('+', node);
		break;
	case '-':
		processExpression('-', node);
		break;	
	case '*':	
		processExpression('*', node);
		break;
	case '/':
		processExpression('/', node);
		break;
	case 'g': //>
		processExpression('g', node);
		break;
	case 'G': //>=
		processExpression('G', node);
		break;
	case 'l': //<
		processExpression('l', node);
		break;
	case 'L': //<=
		processExpression('L', node);
		break;
	case 'e': //==
		processExpression('e', node);
		break;
	case 'n': //!=
		processExpression('n', node);
		break;
	case '=': 
		recursiveTreeProcessing(node->child[1]);
		if(node->child[1]->symbol == '@')
		{
			st[node->child[0]->val.ival].val = getValueOfId(node->child[1]->val.ival, &(st[node->child[0]->val.ival].isInteger));
			node->val = getValueOfId(node->child[1]->val.ival, &(node->isInteger));
		}
		else if(node->child[1]->isInteger == 0)
		{
			st[node->child[0]->val.ival].val.dval = node->child[1]->val.dval;
			st[node->child[0]->val.ival].isInteger = 0;

			node->val = node->child[1]->val;
			node->isInteger =node->child[1]->isInteger;
		}
		else
		{
			st[node->child[0]->val.ival].val.ival = node->child[1]->val.ival;
			st[node->child[0]->val.ival].isInteger = 1;
			node->val = node->child[1]->val;
			node->isInteger = node->child[1]->isInteger;
		}
		break;
	case 'w': //while
		recursiveTreeProcessing(node->child[0]);
		if(node->child[0]->isInteger == 0)
		{
			node->child[0]->isInteger = 1;
			node->child[0]->val.ival =(int) node->child[0]->val.dval;
		}

		while(node->child[0]->val.ival != 0)
		{
			recursiveTreeProcessing(node->child[1]);
			recursiveTreeProcessing(node->child[0]);

			if(node->child[0]->isInteger == 0)
			{
				node->child[0]->isInteger =1;
				node->child[0]->val.ival = (int)node->child[0]->val.dval;
			}
		}
		break;
	case 'i': //if
		recursiveTreeProcessing(node->child[0]);
		if(node->child[0]->isInteger == 0)
		{
			node->child[0]->isInteger = 1;
			node->child[0]->val.ival = (int)node->child[0]->val.dval;
		}
		if(node->child[0]->val.ival == 0)
		{
			recursiveTreeProcessing(node->child[2]);
		}
		else
		{
			recursiveTreeProcessing(node->child[1]);
		}
		break;
	case 'p': //print
		recursiveTreeProcessing(node->child[0]);
		if(node->child[0]->isInteger == 0)
		{
			printf("%lf\n", node->child[0]->val.dval);
		}
		else
		{
			printf("%d\n", node->child[0]->val.ival);
		}
		break;
	case '#': //number leaf node
		break;
	case '@': //id leaf node
		break;
	}	
}

int yyerror(char *msg)
{
	fprintf(stderr, "[Syntax Error]: line %d\n",lineCounter);
	isSyntaxError = 1;
	return -1;
}

void printSymbolTable()
{
	for(int i =1; i < symbolIndex; i++) 
	{
		printf("%d %s ", i, st[i].id);
		if(st[i].isInteger == 0) printf("%lf\n", st[i].val.dval);
		else if(st[i].isInteger == 1) printf("%d\n", st[i].val.ival);
		else printf("\n");
	}
} // unused

int main(int argc, char *argv[])
{
	prgm = makeNode('s');
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

	yyparse();
	if(isSyntaxError == 0 && isLexicalError == 0)recursiveTreeProcessing(prgm);
	freeTree(prgm);
	return 0;
}
