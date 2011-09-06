#
# Copyright (C) 2011 OpenWrt.org, bmx6.net
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# $Id$

include $(TOPDIR)/rules.mk

PKG_NAME:=bmx6-qmp

PKG_SOURCE_PROTO:=git

#Public Sources:
PKG_SOURCE_URL:=git://git.bmx6.net/bmx6.git
PKG_REV:=2623264c17fc463d34f681c2cea32dddde7d30fb

#Private Sources:
#PKG_SOURCE_URL:=file:///usr/src/bmx6/bmx6-private.git
#PKG_REV:=ba3ef22f1d0521d593098fd8ae97e5ab2844e152

PKG_VERSION:=r2011090502

#PKG_RELEASE:=1
#PKG_INSTALL:=1  # this tries to install straight to /usr/sbin/bmx6

PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_SOURCE_SUBDIR)

include $(INCLUDE_DIR)/package.mk


TARGET_CFLAGS += $(FPIC)

#-DNO_TRAFFIC_DUMP -DNO_DYN_PLUGIN -DNO_DEBUG_DUMP -DNO_DEBUG_ALL -DNO_DEBUG_TRACK -DNO_DEBUG_SYS

MAKE_ARGS += \
	EXTRA_CFLAGS="$(TARGET_CFLAGS) -I. -I$(STAGING_DIR)/usr/include -DNO_DEBUG_ALL -DNO_DEBUG_DUMP" \
	EXTRA_LDFLAGS="-L$(STAGING_DIR)/usr/lib " \
	REVISION_VERSION="$(PKG_REV)" \
	CC="$(TARGET_CC)" \
	INSTALL_DIR="$(PKG_INSTALL_DIR)" \
	STRIP="/bin/true" \
	build_all


define Package/bmx6-qmp/Default
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Routing and Redirection
  TITLE:=BMX6 layer 3 routing daemon (QMP version)
  URL:=http://bmx6.net/
  MAINTAINER:=Axel Neumann <neumann@cgws.de>
endef

define Package/bmx6-qmp/description
BMX6 layer 3 routing daemon (QMP version) supporting IPv4, IPv6, and IPv4 over IPv6 -  http://www.bmx6.net
endef

define Package/bmx6-qmp
  $(call Package/bmx6-qmp/Default)
  MENU:=1
endef

define Package/bmx6-qmp-uci-config
  $(call Package/bmx6-qmp/Default)
  DEPENDS:=bmx6-qmp +libuci
  TITLE:=configuration plugin based on uci (recommended!)
endef


define Package/bmx6-qmp-json
  $(call Package/bmx6-qmp/Default)
  DEPENDS:=bmx6-qmp +libjson
  TITLE:=josn plugin based on jsonc 
endef

define Package/bmx6-qmp-sms
  $(call Package/bmx6-qmp/Default)
  DEPENDS:=bmx6-qmp
  TITLE:=sms plugin 
endef


define Build/Configure
	mkdir -p $(PKG_INSTALL_DIR)
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) $(MAKE_ARGS)
endef


define Package/bmx6-qmp/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/config $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bmx6 $(1)/usr/sbin/bmx6
endef


define Package/bmx6-qmp-uci-config/conffiles
/etc/config/bmx6
endef


define Package/bmx6-qmp-uci-config/install
	$(INSTALL_DIR) $(1)/usr/lib $(1)/etc/config $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/bmx6_uci_config/bmx6_config.so $(1)/usr/lib/bmx6_config.so
	$(INSTALL_BIN) ./files/etc/init.d/bmx6 $(1)/etc/init.d/bmx6
	$(INSTALL_DATA) ./files/etc/config/bmx6 $(1)/etc/config/bmx6
endef

define Package/bmx6-qmp-json/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/bmx6_json/bmx6_json.so $(1)/usr/lib/bmx6_json.so
endef

define Package/bmx6-qmp-sms/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/bmx6_sms/bmx6_sms.so $(1)/usr/lib/bmx6_sms.so
endef

$(eval $(call BuildPackage,bmx6-qmp))
$(eval $(call BuildPackage,bmx6-qmp-uci-config))
$(eval $(call BuildPackage,bmx6-qmp-json))
$(eval $(call BuildPackage,bmx6-qmp-sms))

