#include "io.h"
#include "lib.h"

int gcd(int x, int y) {
  if (mod(x,y) == 0) return y;
  else return gcd(y, mod(x,y));
}

int main() {
    outln(gcd(10,1));
    outln(gcd(34986,3087));
    outln(gcd(2907,1539));

    return 0;
}
