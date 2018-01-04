#include "io.h"
#include "lib.h"
int N = 15000;
int  b[15001];
int resultCount = 0;

int main()
{
  int i;

  for (i = 1; i <= N; i++) b[i] = 1;

  for (i = 2; i <= N; i++) if (b[i])
  {
    int count = 2;
    
    if (i>3 && b[i-2])
    {
      resultCount++;
      outl(i-2);
      print(" ");
      outln(i);
    }
    
    while (mul(i,count) <= N)
    {
      b[mul(i,count)] = 0;
      count++;
    }
  }

  print("Total: ");
  outln(resultCount);
  return 0;
}
