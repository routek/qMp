#
# Makefile for niit.
#

ifeq ($(OPENWRT_BUILD),1)

obj-m   := niit.o
ifeq ($(MAKING_MODULES),1)
-include $(TOPDIR)/Rules.make
endif

else



CONFIG_NIIT=m


obj-$(CONFIG_NIIT) += niit.o

all:
	$(MAKE) -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules 

clean:
	$(MAKE) -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

endif
