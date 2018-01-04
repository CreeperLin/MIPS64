// Target: Simulate a Bulgarian-solitaire game.
// Possible opitimization: Dead code elimination, common expression, inline function, loop unrolling, etc.
// REMARKS: A funny game. If you like, you can try to prove that when n=1+2+..+i(i>0), the game will always stop
//          and converge to the only solution: {1,2,...i}.   :)
#include "io.h"
#include "lib.h"
int n;
int h;
int now;
int a[100];
int A = 48271;
int M = 2147483647;
int Q;
int R;
int seed=1;
int random() {
    int tempseed = mul(A, mod(seed, Q)) - mul(R,div(seed, Q));
    if (tempseed >= 0)
		seed = tempseed;
    else
		seed = tempseed + M;
	return seed;
}
void initialize(int val) {
    seed = val;
}
void swap(int x,int y) {
    int temp = a[x];
    a[x] = a[y];
    a[y] = temp;
}
int pd(int x) {
    for (;h <= x; ++h)
        if (x == mul(h, (h + 1))>>1)
			return 1;
    return 0;
}
void show() {
    int i;
    for (i = 0; i < now; ++i)
    {
        outl(a[i]);
        print(" ");
    }
    println("");
}
int win()
{
    int i;
	int j;
	int  b[100];
	int temp;
    if (now != h)
		return 0;
    for (j = 0; j < now; ++j)
        b[j] = a[j];
    for (i = 0;i < now - 1; ++i)
        for (j = i + 1;j < now; ++j)
            if (b[i] > b[j]) {
                temp = b[i];
                b[i] = b[j];
                b[j] = temp;
            }
    for (i = 0; i < now; ++i)
        if (b[i] != i + 1)
			return 0;
    return 1;
}
void merge()
{
    int i;
    for (i = 0;i < now; ++i)
        if (a[i] == 0) {
            int j;
            for (j = i+1; j < now; ++j)
                if (a[j] != 0) {
                    swap(i,j);
                    break;
                }
        }
    for (i=0;i<now;++i)
        if (a[i] == 0) {
            now = i;
            break;
        }
}
void move() {
    int i = 0;
    for (; i < now; ) {
        --a[i];
        i = i + 1;
    }
    a[now] = now;
    now++;
}
int main() {
    int i = 0;
	int temp = 0;
	int count = 0;
	n = mul(mul(3, 7),10);
	h = 0;
    Q = div(M, A);
    R = mod(M, A);
    if (!pd(n)) {
        println("Sorry, the number n must be a number s.t. there exists i satisfying n=1+2+...+i");
        return 1;
    }
    println("Let's start!");
    initialize(3654898);
    now = mod(random(),10) + 1;
    outln(now);
    for (; i < now - 1; ++i)
    {
        a[i] = mod(random(),10) + 1;
        while (a[i] + temp > n)
            a[i] = mod(random(),10) + 1;
        temp = temp + a[i];
    }
    a[now - 1] = n - temp;
    show();
    merge();
    while (!win()) {
        print("step ");
        outl(++count);
        println(":");
        move();
        merge();
        show();
    }
    print("Total: ");
    outl(count);
    println(" step(s)");
    return 0;
}
