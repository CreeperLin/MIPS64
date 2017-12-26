CC = /opt/riscv/bin/riscv32-unknown-elf-
TSF = -march=rv32i -mabi=ilp32
%.s: ./test/%.cpp
	$(CC)g++ -S $< -o ./test/$@ $(TSF)
%.s: ./test/%.c
	$(CC)gcc -S $< -o ./test/$@ $(TSF)
%: ./test/%.s 
	$(CC)as $< -o ./test/$@.o $(TSF)
	$(CC)ld ./test/$@.o -o ./test/$@.om
	$(CC)objcopy -O verilog ./test/$@.om ./test/test.dat
	#sed -i 1d ./test/test.dat
	iverilog testbench.v
	vvp -l ./vvp.log ./a.out
	sed -i '/^\(VCD\|WARNING\)/'d ./vvp.log
	cat ./test/test.dat ./vvp.log > ./test.log
	#gtkwave test.vcd
	vi ./test.log
.PHONY: clean
clean:
	rm -f ./*.vcd ./a.out ./test/*.o ./test/*.om ./test/*.dat
