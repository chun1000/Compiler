#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "struct.h"
#define MAX_TOKEN_TABLE_SIZE 1000

extern int yylex();
extern void initTable();
extern void printToken(token tok);
extern token analysisLex(int val);
extern void printSymbolTable();
extern int symbolIndex;
extern int isLexError;
extern symbolTable *symbol_table;
token tokenTable[MAX_TOKEN_TABLE_SIZE];
int tokenTableIndex, lookahead;
int isSyntaxError, isDefineError;
char defineErrorTemp[20];

typedef struct _syntaxTreeNode {
	token tok;
	struct _syntaxTreeNode* parent;
	struct _syntaxTreeNode* leftChild;
	struct _syntaxTreeNode* rightChild;
	double value;
} syntaxTreeNode;

typedef struct _syntaxTree{
	syntaxTreeNode* root;
} syntaxTree;

syntaxTree uniteTree(token tok, syntaxTree left, syntaxTree right)
{
	syntaxTree newTree;
	syntaxTreeNode* newRoot = (syntaxTreeNode*)malloc(sizeof(syntaxTreeNode));
	newRoot->leftChild = left.root;
	newRoot->rightChild = right.root;
	newRoot->parent = NULL;
	newRoot->tok = tok;
	newRoot->value =0;

	if(left.root != NULL) left.root->parent = newRoot;
	if(right.root != NULL) right.root->parent = newRoot;

	newTree.root = newRoot;
	return newTree;
}

syntaxTree makeNewNode(token tok)
{
	syntaxTree newTree;
	syntaxTreeNode* newNode = (syntaxTreeNode*)malloc(sizeof(syntaxTreeNode));
	newNode->leftChild = NULL; newNode->rightChild = NULL;
	newNode->parent = NULL;
	newNode->tok = tok;
	newNode->value = 0;

	newTree.root = newNode;
	return newTree;
}

syntaxTree makeNullNode()
{
	syntaxTree newTree;
	syntaxTreeNode* newNode = (syntaxTreeNode*)malloc(sizeof(syntaxTreeNode));
	newNode->leftChild = NULL; newNode->rightChild=NULL;
	newNode->parent=NULL;

	strcpy(newNode->tok.name, "");
	strcpy(newNode->tok.value, "");
	newNode->value = 0;

	newTree.root = newNode;
	
	return newTree;
}

void releaseTree(syntaxTreeNode *root)
{
	if(root->leftChild != NULL) releaseTree(root->leftChild);
	if(root->rightChild != NULL) releaseTree(root->rightChild);
	free(root);
	
}


void initState()
{
	tokenTableIndex = 0;
	lookahead = 0; isSyntaxError = 0; isDefineError = 0; isLexError = 0;
	strcpy(tokenTable[0].name, "NEWLINE"); //NewLine is treated like a "$"
}

void printNumber(double d)
{
	if(d - (int)d == 0)
	{
		printf("%d\n", (int)d);
	}
	else printf("%lf\n", d);
}

void printTokenTable()
{
	int i = 0;

	do	{
		printf("%s\t%s\n", tokenTable[i].name, tokenTable[i].value); i++;
	}
	while(strcmp(tokenTable[i].name, "NEWLINE") != 0);
	printf("%s\t%s\n", tokenTable[i].name, tokenTable[i].value); i++;
}

void error()
{
	isSyntaxError = 1;
}

token match(char *input)
{
	token tok;
	strcpy(tok.name, ""); strcpy(tok.value, "");

	if(strcmp(tokenTable[lookahead].name, input) == 0) 
	{
		lookahead++;
		return tokenTable[lookahead-1];
	}
	else isSyntaxError =1;
	return tok;
}

int compareLookahead(char* input)
{
	if(strcmp(tokenTable[lookahead].name, input) == 0) return 1;
	else return 0;
}


//------------------------------------//
syntaxTree restassign(syntaxTree parameterTree);
syntaxTree restfactor();
syntaxTree restterm(syntaxTree parameterTree);
syntaxTree restexpr(syntaxTree parameterTree);
syntaxTree term();
syntaxTree factor();


//-----------------------------------//
//Recursive Decent Parsing Part//

syntaxTree assign()
{
	token tmptok;
	syntaxTree newSyntaxTree;
	syntaxTree receivedTree;
	syntaxTree receivedTree2;

	if(compareLookahead("ID"))
	{
		tmptok = match("ID"); 
		newSyntaxTree = makeNewNode(tmptok);
		return restassign(newSyntaxTree);
	}
	else if(compareLookahead("LPAREN")||compareLookahead("INTEGER")||compareLookahead("DOUBLE") || compareLookahead("MINUSOP"))
	{
		receivedTree = restfactor();
		receivedTree2 = restterm(receivedTree);
		return restexpr(receivedTree2);
	}
	else
	{
		error();
		return makeNullNode();
	}
}

syntaxTree restassign(syntaxTree parameterTree)
{
	token tmptok;
	syntaxTree receivedTree;
	
	if(compareLookahead("ASSIGNOP"))
	{
		tmptok = match("ASSIGNOP"); 

		if(compareLookahead("LPAREN"))
		{
			match("LPAREN");
			receivedTree = assign();
			match("RPAREN");
			return uniteTree(tmptok, parameterTree, receivedTree);
		}
		else
		{
			receivedTree = assign();
			return uniteTree(tmptok, parameterTree, receivedTree);
		}
	}
	else if(compareLookahead("MULTOP")||compareLookahead("DIVOP")||compareLookahead("MINUSOP")||compareLookahead("PLUSOP")||compareLookahead("RPAREN")||compareLookahead("NEWLINE"))
	{
		receivedTree = restterm(parameterTree); 
		return restexpr(receivedTree);
	}
	else
	{
		error();
		releaseTree(parameterTree.root);
		return makeNullNode();
	}
}

syntaxTree expr()
{
	syntaxTree receivedTree;
	
	if(compareLookahead("ID")||compareLookahead("LPAREN")||compareLookahead("INTEGER")||compareLookahead("DOUBLE")||compareLookahead("MINUSOP"))
	{
		receivedTree = term(); 
		return restexpr(receivedTree);
	}
	else
	{
		error();
		return makeNullNode();
	}
}

syntaxTree restexpr(syntaxTree parameterTree)
{
	token tmptok;
	syntaxTree receivedTree, unitedTree;

	if(compareLookahead("PLUSOP"))
	{
		tmptok = match("PLUSOP"); 
		receivedTree = term(); 
		unitedTree = uniteTree(tmptok, parameterTree, receivedTree);
		return restexpr(unitedTree);
	}
	else if(compareLookahead("MINUSOP"))
	{
		tmptok = match("MINUSOP");
		receivedTree = term();
		unitedTree = uniteTree(tmptok, parameterTree, receivedTree);
		return restexpr(unitedTree);
	}
	else if(compareLookahead("RPAREN")||compareLookahead("NEWLINE"))
	{
		return parameterTree;
	}
	else
	{
		error();
		releaseTree(parameterTree.root);
		return makeNullNode();
	}
}

syntaxTree term()
{
	syntaxTree receivedTree;
		
	if(compareLookahead("ID")||compareLookahead("LPAREN")||compareLookahead("INTEGER")||compareLookahead("DOUBLE")||compareLookahead("MINUSOP"))
	{
		receivedTree = factor(); 
		return restterm(receivedTree);
	}
	else
	{
		error();
		return makeNullNode();
	}
}

syntaxTree restterm(syntaxTree parameterTree)
{
	token tmptok;
	syntaxTree receivedTree;
	syntaxTree unitedTree;

	if(compareLookahead("MULTOP"))
	{
		tmptok = match("MULTOP"); 
		receivedTree = factor();
		unitedTree = uniteTree(tmptok, parameterTree, receivedTree);
		return restterm(unitedTree);
	}
	else if(compareLookahead("DIVOP"))
	{
		tmptok = match("DIVOP");
		receivedTree = factor();
		unitedTree = uniteTree(tmptok, parameterTree, receivedTree);
		return restterm(unitedTree);
	}
	else if(compareLookahead("MINUSOP")||compareLookahead("PLUSOP")||compareLookahead("RPAREN")||compareLookahead("NEWLINE"))
	{
		return parameterTree;
	}
	else 
	{
		error();
		releaseTree(parameterTree.root);
		return makeNullNode();
	}
}

syntaxTree factor()
{

	if(compareLookahead("ID"))
	{
	 return makeNewNode(match("ID"));
	}
	else if(compareLookahead("ID")||compareLookahead("LPAREN")||compareLookahead("INTEGER")||compareLookahead("DOUBLE")||compareLookahead("MINUSOP"))
	{
		restfactor();
	}
	else
	{
		error(); 
		return makeNullNode();
	}
}

syntaxTree restfactor()
{
	syntaxTree receivedTree;
	token tmptok;

	if(compareLookahead("LPAREN"))
	{
		match("LPAREN"); receivedTree = assign(); match("RPAREN"); return receivedTree;
	}
	else if(compareLookahead("DOUBLE"))
	{
		return makeNewNode(match("DOUBLE")); 
	}
	else if(compareLookahead("INTEGER"))
	{
		return makeNewNode(match("INTEGER"));
	}
	else if(compareLookahead("MINUSOP"))
	{
		tmptok = match("MINUSOP"); receivedTree = factor();
		syntaxTree nullNode; nullNode.root = NULL;
		return uniteTree(tmptok, receivedTree, nullNode);
	}
	else
	{
		error();
		return makeNullNode();
	}
}
//---------------------------------------------------------//


//---------------------------------------------------------//
//Algorithm of Calculate

double getIdValue(token tok)
{
	double tmp = 0;

	if(symbol_table[atoi(tok.value)].hasValue != 0)
	{
		return symbol_table[atoi(tok.value)].value;
	}
	else
	{
		isDefineError = 1;
		strcpy(defineErrorTemp, symbol_table[atoi(tok.value)].id);
		return tmp;
	}
}

double getNumberValue(token tok)
{
	return atof(tok.value);
}

void recursiveCalculate(syntaxTreeNode *t)
{
	if(t->leftChild == NULL && t->rightChild == NULL)
	{
		if(strcmp(t->tok.name, "ID") == 0) t->value = getIdValue(t->tok);
		else t->value = getNumberValue(t->tok);
	}
	else if(strcmp(t->tok.name, "ASSIGNOP") == 0)
	{
		recursiveCalculate(t->rightChild);
		symbol_table[atoi(t->leftChild->tok.value)].value = t->rightChild->value;
		symbol_table[atoi(t->leftChild->tok.value)].hasValue = 1;
		t->value = t->rightChild->value;

	}
	else if(strcmp(t->tok.name, "MINUSOP")==0 && t->rightChild == NULL)
	{
		recursiveCalculate(t->leftChild);
		t->value = -(t->leftChild->value);
	}
	else
	{
		recursiveCalculate(t->leftChild);
		recursiveCalculate(t->rightChild);

		if(strcmp(t->tok.name, "PLUSOP") == 0)
		{
			t->value = t->leftChild->value + t->rightChild->value;
		}
		else if(strcmp(t->tok.name, "MINUSOP") == 0)
		{
			t->value = t->leftChild->value - t->rightChild->value;
		}
		else if(strcmp(t->tok.name, "DIVOP") == 0)
		{
			t->value = t->leftChild->value / t->rightChild->value;
		}
		else if(strcmp(t->tok.name, "MULTOP") == 0)
		{
			t->value = t->leftChild->value * t->rightChild->value;
		}
	}
}

//---------------------------------------------------------//

int main(int argc, char* argv[])
{
	initTable();
	int val; token tok;

	while(1)
	{
		printf(">");
		initState(); // init index, detected error, lookahead, tokentable.
		while((val=yylex())!=0)
		{
			tok = analysisLex(val);
			if(!(strcmp(tok.name, "") == 0 && strcmp(tok.value, "") == 0)) tokenTable[tokenTableIndex++] = tok;
			if(strcmp(tok.name, "NEWLINE") == 0) break;
		}

		if(isLexError == 0)
		{
			syntaxTree t = assign();
			if(isSyntaxError == 0&&strcmp(tokenTable[lookahead].name,  "NEWLINE") == 0)
			{
				recursiveCalculate(t.root);
				if(isDefineError ==0) printNumber(t.root->value);
				else printf("%s는 정의되지 않음.\n",defineErrorTemp);
			}
			else printf("error: syntax error\n");

			releaseTree(t.root);
		}
		else printf("error: lexical error\n");
		
	}
	
	free(symbol_table);
	return 0;
}


