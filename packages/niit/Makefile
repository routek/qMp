# 
# Copyright (C) 2006 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

#ifdef OPENWRTVERSION

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=niit
PKG_VERSION:=0.2

include $(INCLUDE_DIR)/package.mk

define KernelPackage/niit
  SUBMENU:=Network Support
  TITLE:=Stateless IP ICMP Translation Algorithm
  DEPENDS:=+kmod-ipv6
  FILES:=$(PKG_BUILD_DIR)/niit.$(LINUX_KMOD_SUFFIX)
  AUTOLOAD:=$(call AutoLoad,50,niit)
endef

define KernelPackage/niit/description
 Stateless IP ICMP Translation Algorithm
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	cp src/Makefile src/niit.h src/niit.c $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(MAKE) -C $(LINUX_DIR) \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		ARCH="$(LINUX_KARCH)" \
		SUBDIRS="$(PKG_BUILD_DIR)" \
		KERNELDIR=$(LINUX_DIR) \
		CC="$(TARGET_CC)" \
		modules
endef

$(eval $(call KernelPackage,niit))

#else

#CONFIG_NIIT=m

#obj-$(CONFIG_NIIT) += niit.o

#all:
#	$(MAKE) -C /lib/modules/$(shell uname -r)/build M=$(PWD)/src modules

#clean:
#	$(MAKE) -C /lib/modules/$(shell uname -r)/build M=$(PWD)/src clean


#endif
