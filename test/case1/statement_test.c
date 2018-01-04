//考察点：section 8 语句，包括if,while,for,break,continue,return等
//算法：线性筛法求欧拉函数
//样例输入：10
//样例输出：
//1
//2
//2
//4
//2
//6
//4
//6
//4
#include "io.h"
#include "lib.h"
int N;
int M = 0;
int check[20];

int main() {
    N = inl();
	int i = 0;
	while ( i <= N ) check[i++] = 1;
	int  phi[N+5];
	int  P[N+5];
	phi[1] = 1;
	for (i = 2; ; ++i ) {
		if ( i > N ) break;
		if ( check[i] ) {
			P[++M] = i;
			phi[i] = i - 1;
		}
		int k = i;
		int i;
		for (i = 1; i <= M && (mul(k, P[i]) <= N); i++) {
			int tmp = mul(k, P[i]);
			if ( tmp > N ) continue;
			check[tmp] = 0;
			if (mod(k, P[i]) == 0) {
				phi[tmp] = mul(phi[k], P[i]);
				break;
			}
			else {
				phi[mul(k, P[i])] = mul(phi[k], (P[i] - 1));
			}
		}
		outln(phi[k]);
	}
    return 0;
}
