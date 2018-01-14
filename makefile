CCR = /opt/riscv/
CC = $(CCR)bin/riscv32-unknown-elf-
TESTCASE = case0/
TESTSRC = ./test/$(TESTCASE)
#CC = $(CCR)bin/riscv32-unknown-linux-gnu-
TSF = -march=rv32i -mabi=ilp32
LDF =  -L $(CCR)/riscv32-unknown-elf/lib/ -L $(CCR)/lib/gcc/riscv32-unknown-elf/7.2.0/ -lc -lgcc -lm -lnosys -o ./test/test.om
system.o:
	$(CC)gcc -c ./test/rom/system.c -o ./test/rom/system.o $(TSF)
rom.o:
	$(CC)as ./test/rom/rom.s -o ./test/rom/rom.o $(TSF)
%.s: ./test/%.cpp
	cp $< ./test/test.cpp
	$(CC)g++ -S ./test/test.cpp -o ./test/test.s $(TSF)
%.s: $(TESTSRC)%.c
	cp $< ./test/test.c
	$(CC)gcc -S ./test/test.c -o ./test/test.s $(TSF) -Wall
%: %.s rom.o system.o 
	$(CC)as ./test/test.s -o ./test/test.o $(TSF)
	#$(CC)ld ./test/test.o ./test/rom/rom.o -o ./test/test.om $(LDF)
	$(CC)ld -T memory.ld ./test/rom/rom.o ./test/test.o ./test/rom/system.o $(LDF) 
	$(CC)objdump -D ./test/test.om > ./test/test.dump
	$(CC)objcopy -O binary ./test/test.om ./test/test.bin
	python ./bin2ascii.py ./test/test.bin ./test/test.ascii
	$(CC)objcopy -O verilog ./test/test.om ./test/test.dat
	if [ -f $(TESTSRC)$@.in ]; then cp $(TESTSRC)$@.in ./test/test.in; fi
	#iverilog testbench.v
	iverilog testuart.v
	vvp -l ./vvp.log ./a.out
	sed -i '/^\(VCD\|WARNING\)/'d ./vvp.log
	./simple.sh
	#gtkwave test.vcd
	cat ./test/test.out 
	if [ -f $(TESTSRC)$@.ans ]; then cat $(TESTSRC)$@.ans;diff ./test/test.out $(TESTSRC)$@.ans; fi
.PHONY: clean
clean:
	rm -f ./*.log ./*.fst ./*.vcd ./a.out ./test/*.s ./test/*.o ./test/*.om ./test/test.* ./test/*.dump
