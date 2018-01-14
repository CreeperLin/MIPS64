#ifndef CPU_JUDGE_TEST_IO_H
#define CPU_JUDGE_TEST_IO_H

#define INT_PORT_E 1

static inline unsigned char inb()
{
	return *((volatile unsigned char *)0x100);
}

static inline void outb(const unsigned char data)
{
	*((volatile unsigned char *)0x104) = data;
}

#define NL outb('\n');

#if INT_PORT_E
static inline unsigned long inl()
{
    unsigned char data[4];
	*((volatile unsigned char *)0x200) = 1;
    data[0] = *((volatile unsigned char *)0x201); 
    data[1] = *((volatile unsigned char *)0x202); 
    data[2] = *((volatile unsigned char *)0x203); 
    data[3] = *((volatile unsigned char *)0x204);
    //unsigned long tmp;
    //tmp = *((volatile unsigned long *)0x201);
	//*((volatile unsigned char *)0x200) = 0;
	return data[0] | (data[1] << 8) | (data[2] << 16) | (data[3] << 24);
    //return tmp;
}

static inline void outl(const unsigned int data)
{
    
	*((volatile unsigned char *)0x205) = data & 0xff;
	*((volatile unsigned char *)0x206) = (data>>8) & 0xff;
	*((volatile unsigned char *)0x207) = (data>>16) & 0xff;
	*((volatile unsigned char *)0x208) = (data>>24) & 0xff;
    //*((volatile unsigned int *)0x205) = data;
	*((volatile unsigned char *)0x209) = 1;
}

#elif
static inline unsigned long inl()
{
    unsigned char data[4];
    data[0] = inb();
    data[1] = inb();
    data[2] = inb();
    data[3] = inb();
    return data[0] | (data[1] << 8) | (data[2] << 16) | (data[3] << 24);
}

static inline void outl(const unsigned int data)
{
    outb(data & 0xff);
    outb((data >> 8) & 0xff);
    outb((data >> 16) & 0xff);
    outb((data >> 24) & 0xff);
}
#endif

static inline void print(const char *str)
{
	for (; *str; str++)
		outb(*str);
}

static inline void println(const char *str)
{
	print(str);
	outb('\n');
}

static inline void outln(const unsigned int data)
{
    outl(data);
    NL
}
#endif
