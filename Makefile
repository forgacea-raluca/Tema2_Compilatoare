
all:
	yacc -d tema2.y
	flex tema2.l
	g++ -std=c++11 -g lex.yy.c y.tab.c -o tema2 -lfl

clean:
	rm tema2 *.tab.c *.tab.h lex.yy.c 

