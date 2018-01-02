CCR = /opt/riscv/
CC = $(CCR)bin/riscv32-unknown-elf-
TESTCASE = case1/
TESTSRC = ./test/$(TESTCASE)
#CC = $(CCR)bin/riscv32-unknown-linux-gnu-
TSF = -march=rv32i -mabi=ilp32
LDF = -T memory.ld
rom.o:
	$(CC)as ./test/rom/rom.s -o ./test/rom/rom.o $(TSF)
%.s: ./test/%.cpp
	$(CC)g++ -S $< -o ./test/$@ $(TSF)
%.s: $(TESTSRC)%.c
	cp $< ./test/test.c
	$(CC)gcc -S ./test/test.c -o ./test/test.s $(TSF)
	#$(CC)gcc -S $< -o ./test/$@ $(TSF)
%: %.s rom.o 
	#$(CC)as ./test/$< -o ./test/$@.o $(TSF)
	#$(CC)ld ./test/$@.o ./test/rom/rom.o -o ./test/$@.om $(LDF)
	#$(CC)objdump -d ./test/$@.om > ./test/$@.dump
	#$(CC)objcopy -O verilog ./test/$@.om ./test/test.dat
	$(CC)as ./test/test.s -o ./test/test.o $(TSF)
	$(CC)ld ./test/test.o ./test/rom/rom.o -o ./test/test.om $(LDF)
	$(CC)objdump -D ./test/test.om > ./test/test.dump
	$(CC)objcopy -O verilog ./test/test.om ./test/test.dat
	#$(CC)ld ./test/$@.o -o ./test/$@.om
	#$(CC)as $< -o ./test/$@.o  
	#$(CCR)libexec/gcc/riscv32-unknown-elf/7.2.0/collect2 -plugin $(CCR)libexec/gcc/riscv32-unknown-elf/7.2.0/liblto_plugin.so -plugin-opt=$(CCR)libexec/gcc/riscv32-unknown-elf/7.2.0/lto-wrapper -plugin-opt=-fresolution=/tmp/ccAhfe4x.res -plugin-opt=-pass-through=-lgcc -plugin-opt=-pass-through=-lc -plugin-opt=-pass-through=-lgloss -plugin-opt=-pass-through=-lgcc --sysroot=$(CCR)riscv32-unknown-elf -melf32lriscv -o ./test/test6 $(CCR)lib/gcc/riscv32-unknown-elf/7.2.0/../../../../riscv32-unknown-elf/lib/crt0.o $(CCR)lib/gcc/riscv32-unknown-elf/7.2.0/crtbegin.o -L$(CCR)lib/gcc/riscv32-unknown-elf/7.2.0 -L$(CCR)lib/gcc/riscv32-unknown-elf/7.2.0/../../../../riscv32-unknown-elf/lib -L$(CCR)riscv32-unknown-elf/lib ./test/$@.o -o ./test/$@.om -lgcc --start-group -lc -lgloss --end-group -lgcc $(CCR)lib/gcc/riscv32-unknown-elf/7.2.0/crtend.o
	#sed -i 1d ./test/test.dat
	if [ -f $(TESTSRC)$@.in ]; then cp $(TESTSRC)$@.in ./test/test.in; fi
	iverilog testbench.v
	vvp -l ./vvp.log ./a.out
	sed -i '/^\(VCD\|WARNING\)/'d ./vvp.log
	#gtkwave test.vcd
	#vi ./vvp.log
	#cat ./vvp.log|grep "IO"
	#sed -i 's/[[:space:]]\{2,\}//g' ./test/test.out
	cat ./test/test.out 
	if [ -f $(TESTSRC)$@.ans ]; then cat $(TESTSRC)$@.ans;diff ./test/test.out $(TESTSRC)$@.ans; fi
.PHONY: clean
clean:
	rm -f ./*.log ./*.fst ./*.vcd ./a.out ./test/*.s ./test/*.o ./test/*.om ./test/test.* ./test/*.dump
