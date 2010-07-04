obj-m := capable_probe.o
KDIR := /lib/modules/$(shell uname -r)/build
PWD := $(shell pwd)
default:
	$(MAKE) -C $(KDIR) SUBDIRS=$(PWD) modules
install: default
	install -d /lib/modules/$(shell uname -r)/kernel/misc/
	install capable_probe.ko /lib/modules/$(shell uname -r)/kernel/misc/
	depmod -a
clean:
	rm -f *.mod.c *.ko *.o modules.order Module.symvers
