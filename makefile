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
	cp $< ./test/test.cpp
	$(CC)g++ -S ./test/test.cpp -o ./test/test.s $(TSF)
%.s: $(TESTSRC)%.c
	cp $< ./test/test.c
	$(CC)gcc -S ./test/test.c -o ./test/test.s $(TSF)
%: %.s rom.o 
	$(CC)as ./test/test.s -o ./test/test.o $(TSF)
	$(CC)ld ./test/test.o ./test/rom/rom.o -o ./test/test.om $(LDF)
	$(CC)objdump -D ./test/test.om > ./test/test.dump
	$(CC)objcopy -O verilog ./test/test.om ./test/test.dat
	if [ -f $(TESTSRC)$@.in ]; then cp $(TESTSRC)$@.in ./test/test.in; fi
	iverilog testbench.v
	vvp -l ./vvp.log ./a.out
	sed -i '/^\(VCD\|WARNING\)/'d ./vvp.log
	#gtkwave test.vcd
	cat ./test/test.out 
	if [ -f $(TESTSRC)$@.ans ]; then cat $(TESTSRC)$@.ans;diff ./test/test.out $(TESTSRC)$@.ans; fi
.PHONY: clean
clean:
	rm -f ./*.log ./*.fst ./*.vcd ./a.out ./test/*.s ./test/*.o ./test/*.om ./test/test.* ./test/*.dump
