#ifndef RISCV32I_LIB_H_
#define RISCV32I_LIB_H_

#include "io.h"
static inline unsigned long mul(unsigned int a, unsigned int b)
{
    unsigned l1 = (a>b)?a:b;
    unsigned l2 = (a<b)?a:b;
    unsigned long ans=0;
    while (l2>0)
    {
        if (l2 & 1)
        {
            ans += l1;
            --l2;
        }
        if(!l2) break;
        l1 += l1;
        l2 >>= 1;
    }
    return ans;
}

static inline unsigned long div(unsigned int a, unsigned int b)
{
    unsigned long ans=0;
    unsigned int t = b, m = 1;
    while (a>=(t<<1)) t <<= 1, m <<= 1;
    while (a>=b)
    {
        a -= t;
        ans += m;
        while (a>=b && a<t)
        {
            t >>= 1;
            m >>= 1;
        }
    }
    return ans;
}

static inline unsigned long mod(unsigned int a, unsigned int b)
{
    unsigned int t = b;
    while (a>=(t<<1)) t <<= 1;
    while (a>=b)
    {
        a -= t;
        while (a>=b && a<t) t >>= 1;
    }
    return a;
}

static inline unsigned long sqrti(unsigned int a)
{
    long y = a,l = a << 1;
    while ((l-y)>1 || (l-y)<-1) l = y, y = (y + div(a,y)) >> 1;
    return y;
}

static inline unsigned long powi(unsigned int a, unsigned int b)
{
    unsigned long ans=1;
    while (b>0)
    {
        if (b&1)
        {
            ans = mul(ans,a);
            --b;
        }
        if (!b) break;
        a = mul(a,a);
        b >>= 1;
    }
    return ans;
}

static inline unsigned long logi(unsigned int a)
{
    unsigned long ans=(a>2)?1:0;
    while ((a>>1)>=2)
    {
        a >>= 1;
        ans += 1;
    }
    return ans;
}

#endif
