#include "io.h"

int main(){
	int i = 0;
	for ( ; i < 65; i++) {
		outb('a');
		outb('b');
		outb('c');
		outb('d');
		outb('e');
		outb('f');
		outb('g');
		outb('h');
		outb('i');
		outb('j');
		outb('k');
		outb('l');
		outb('m');
		outb('n');
		outb('o');
		outb('p');
	}
	outb('g');
	return 0;
}
