// input: 1 2 3 4
#include "io.h"
int a[4];
int *pa = a;
int main()
{
    int b[4][4];
    int *pb[4];
	int i;
	pb[0] = pa;
	pb[1] = pa;
	pb[2] = pa;
	pb[3] = pa;
	outl(4);
    NL
	for (i = 0; i < 4; i++)
		pb[0][i] = inl();
	for (i = 0; i < 4; i++)
		outl(pb[1][i]);
	println("");
	for (i = 0; i < 4; i++)
		pb[2][i] = 0;
	for (i = 0; i < 4; i++)
		outl(pb[3][i]);
}
