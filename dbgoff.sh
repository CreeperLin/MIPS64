sed -i 's/$display/\/\/$display/g' *.v
sed -i 's/default: \/\/$display/default: $display/g' *.v
sed -i 's/\/\/$display("IO:R/$display("IO:R/g' *.v
sed -i 's/\/\/$write/$write/g' *.v
sed -i 's/$dump/\/\/$dump/g' *.v
