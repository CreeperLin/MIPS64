#include "io.h"
#include "lib.h"

int main() {
	int a = 10000;
	int b = 0;
	int c = 2800;
	int d = 0;
	int e = 0;
	int f[2801];
	int g = 0;

	for (;b-c!=0;) 
		f[b++] = div(a,5);
	for (;; e = mod(d,a)){
		d = 0;
		g = c<<1;
		if (g==0) break;
		
		for (b=c;;d=mul(d,b)){
			d=d+mul(f[b],a);
			f[b] = mod(d,--g);
			d=div(d,g--);
			if (--b==0) break;
		}
		
		c = c-14;
		outl(e+div(d,a));
	}
	
  print("\n");
  return 0;
}
