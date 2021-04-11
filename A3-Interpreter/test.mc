a = 3;
print a;
b = 0.14 + a;
print b;
c = 5.1/2;
print c;
d = a*c;
print d;

count = 5;
tval = 0;

while(count > 0){
	if(count > 3) print count;
	else if(count == 2) {
		if(tval == 0) {
			tval = tval + 1;
			print tval;
		}
		else ;
	} else print 1.23456 + 1;
	count = count - 1;
}

min = 0;
atmp = 1;
btmp = 2;
ctmp = 3;

if(atmp <= btmp) {
	if(atmp >= ctmp) min = ctmp;
	else min = atmp;
} else {
	if(btmp >= ctmp) min = ctmp;
	else min = btmp;
}

print min;
