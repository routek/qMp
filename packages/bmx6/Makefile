#
# Copyright (C) 2010 bmx6.net
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# $Id$

include $(TOPDIR)/rules.mk

PKG_NAME:=bmx6


PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=git://git.bmx6.net/bmx6.git
PKG_REV:=c56e493c428dfa773cad83d1ce1dcbca53a23fdc

#PKG_SOURCE_PROTO:=git
#PKG_SOURCE_URL:=file:///usr/src/bmx6/bmx6-private.git
#PKG_REV:=0738371aa9985a3063d2ed099ac5a5c25df6c55b

#PKG_VERSION:=r$(PKG_REV)
#better using an increasing date (e.g.:20110101) + day-version (01), otherwise lower git hashes may prevent upgrading
PKG_VERSION:=r2011031502

#PKG_RELEASE:=1
#PKG_INSTALL:=1  # this tries to install straight to /usr/sbin/bmx6



PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_SOURCE_SUBDIR)

include $(INCLUDE_DIR)/package.mk

#define Package/bmx6/Default
#  URL:=https://www.bmx6.net/
#endef

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


define Package/bmx6/template
  SECTION:=net
  CATEGORY:=Network
  TITLE:=BMX6 layer 3 routing daemon  www.bmx6.net
  URL:=http://bmx6.net/
endef

define Package/bmx6/description
BMX6 layer 3 routing daemon
endef

define Package/bmx6
  $(call Package/bmx6/template)
  MENU:=1
#  DEPENDS:=+kmod-tun
endef

define Package/bmx6-uci-config
  $(call Package/bmx6/template)
  DEPENDS:=bmx6 +libuci
  TITLE:=configuration plugin based on uci
endef

#define Package/bmx6-http-info
#  $(call Package/bmx6/template)
#  DEPENDS:=bmx6
#  TITLE:=simple http info plugin
#endef

#define Package/bmx6-gsf-map
#  $(call Package/bmx6/template)
#  DEPENDS:=bmx6
#  TITLE:=GSF decentral map plugin
#endef

#define Package/bmx6-howto-plugin
#  $(call Package/bmx6/template)
#  DEPENDS:=bmx6
#  TITLE:=simple plugin example
#endef




define Build/Configure
	mkdir -p $(PKG_INSTALL_DIR)
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) $(MAKE_ARGS)
endef

define Package/bmx6/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/config $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bmx6 $(1)/usr/sbin/bmx6
	$(INSTALL_BIN) ./files/etc/init.d/bmx6 $(1)/etc/init.d
endef

define Package/bmx6-uci-config/install
	$(INSTALL_DIR) $(1)/usr/lib $(1)/etc/config $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/bmx6_uci_config/bmx6_config.so $(1)/usr/lib/bmx6_config.so
#	$(INSTALL_DATA) ./files/etc/config/bmx6 $(1)/etc/config
endef

#define Package/bmx6-http-info/install
#	$(INSTALL_DIR) $(1)/usr/lib 
#	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/bmx6_http_info/bmx6_http_info.so.1 $(1)/usr/lib/bmx6_http_info.so
#endef

#define Package/bmx6-gsf-map/install
#	$(INSTALL_DIR) $(1)/usr/lib 
#	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/bmx6_gsf_map/bmx6_gsf_map.so.1 $(1)/usr/lib/bmx6_gsf_map.so
#endef

#define Package/bmx6-howto-plugin/install
#	$(INSTALL_DIR) $(1)/usr/lib
#	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/bmx6_howto_plugin/bmx6_howto_plugin.so.1 $(1)/usr/lib/bmx6_howto_plugin.so
#endef

$(eval $(call BuildPackage,bmx6))
$(eval $(call BuildPackage,bmx6-uci-config))
#$(eval $(call BuildPackage,bmx6-http-info))
#$(eval $(call BuildPackage,bmx6-gsf-map))
#$(eval $(call BuildPackage,bmx6-howto-plugin))

