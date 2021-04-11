a : source.l main.c struct.h
	flex source.l
	gcc -o a.out -g main.c lex.yy.c -lfl
clean :
	rm a.out
	rm lex.yy.c
