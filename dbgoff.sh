sed -i 's/$display/\/\/$display/g' *.v
sed -i 's/default: \/\/$display/default: $display/g' *.v
sed -i 's/\/\/$display("IO/$display("IO/g' *.v
sed -i 's/$dump/\/\/$dump/g' *.v
