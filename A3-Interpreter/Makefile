a : source.l source.y struct.h
	flex source.l
	bison -d -b y -v source.y
	gcc -o a.out y.tab.c lex.yy.c -lfl
clean :
	rm lex.yy.c
	rm y.tab.c
	rm y.tab.h
	rm y.output
