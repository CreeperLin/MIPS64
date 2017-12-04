main.vcd:main.vcd
	rm -f ./a.out
	rm -f test.vcd
	iverilog testbench.v
	./a.out
	gtkwave test.vcd
