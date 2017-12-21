CC = /opt/riscv/bin/riscv32-unknown-elf-
%: ./test/%.s
	$(CC)as $< -o ./test/$@.o -march=rv32i
	$(CC)ld ./test/$@.o -o ./test/$@.om
	$(CC)objcopy -O verilog ./test/$@.om ./test/test.dat
	sed -i 1d ./test/test.dat
	cat ./test/test.dat
	iverilog testbench.v
	./a.out
	gtkwave test.vcd
.PHONY: clean
clean:
	rm -f ./test.vcd ./a.out ./test/*.o ./test/*.om ./test/*.dat
