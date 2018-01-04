#include "io.h"
#include "lib.h"

int make[25];
int  color[10];
int  count[1];
int i;
int j;

void origin(int N)
{
    for (i = 0; i < N; i ++ ) {
        for (j = 0; j < N; j ++ )
        make[3*(i)+j] = 0;
    }	
}

int search(int x, int y, int z)
{
	int s;
	int i;
	int j;
    if ((y > 0 || y < 0) || x == 0 || make[3*(x-1)+0] + make[3*(x-1)+1] + make[3*(x-1)+2] == 15)
    {
        if (x == 2 && y == 2) {
            make[3*(2)+2] = 45 - z;
            s = make[3*(0)+0] + make[3*(0)+1] + make[3*(0)+2];
            if  (make[3*(1)+0] + make[3*(1)+1] + make[3*(1)+2] == s &&
                    make[3*(2)+0] + make[3*(2)+1] + make[3*(2)+2] == s &&
                    make[3*(0)+0] + make[3*(1)+0] + make[3*(2)+0] == s &&
                    make[3*(0)+1] + make[3*(1)+1] + make[3*(2)+1] == s &&
                    make[3*(0)+2] + make[3*(1)+2] + make[3*(2)+2] == s &&
                    make[3*(0)+0] + make[3*(1)+1] + make[3*(2)+2] == s &&
                    make[3*(2)+0] + make[3*(1)+1] + make[3*(0)+2] == s)
            {
                count[0] = count[0] + 1;
                for (i = 0;i <= 2;i ++)
                {
                	for (j = 0;j <= 2;j ++)
                    {
                        outl(make[3*(i)+j]);
                        print(" ");
                    }
                    print("\n");
                }
               print("\n");
            }
       }
       else {
            if (y == 2) {
                make[3*(x)+y] = 15 - make[3*(x)+0] - make[3*(x)+1];
                if (make[3*(x)+y] > 0 && make[3*(x)+y] < 10 && color[make[3*(x)+y]] == 0) {
                    color[make[3*(x)+y]] = 1;
                    if (y == 2)
                        search(x + 1, 0, z+make[3*(x)+y]);
                    else
                        search(x, y+1, z+make[3*(x)+y]);
                    color[make[3*(x)+y]] = 0;
            	}
            }
            else {
                for (i = 1;i <= 9;i ++) {
                    if (color[i] == 0) {
                        color[i] = 1;
                        make[3*(x)+y] = i;
                        if (y == 2)
                            search(x + 1, 0, z+i);
                        else
                            search(x, y+1, z+i);
                        make[3*(x)+y] = 0;
                        color[i] = 0;
                    }
                }
            }
    	}
    }
}
int main()
{
	origin(3);
    search(0, 0, 0);
    outln(count[0]);
    return 0;
}
