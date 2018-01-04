sed -i 's/\/\/$display/$display/g' *.v
sed -i 's/$write/\/\/$write/g' ram.v
sed -i 's/\/\/$dump/$dump/g' *.v
