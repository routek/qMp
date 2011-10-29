#
# Copyright (C) 2006-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=tinyproxy
PKG_VERSION:=1.8.3
PKG_RELEASE:=4

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
PKG_SOURCE_URL:=http://www.banu.com/pub/tinyproxy/1.8/
PKG_MD5SUM:=292ac51da8ad6ae883d4ebf56908400d

PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/qmp-tinyproxy
  SECTION:=net
  CATEGORY:=Base system
  TITLE:=Tinyproxy is a lightweight HTTP and HTTPS proxy with support splash
  URL:=http://tinyproxy.sourceforge.net/
endef

define Package/qmp-tinyproxy/conffiles
/etc/config/tinyproxy
endef

CONFIGURE_ARGS+= \
	--enable-filter \
	--enable-transparent \
	--disable-regexcheck \

define Package/qmp-tinyproxy/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) $(PKG_INSTALL_DIR)/usr/sbin/tinyproxy $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/usr/share/tinyproxy
	$(CP) $(PKG_INSTALL_DIR)/usr/share/tinyproxy/*.html $(1)/usr/share/tinyproxy/
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/tinyproxy.config $(1)/etc/config/tinyproxy
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/tinyproxy.init $(1)/etc/init.d/tinyproxy
	$(INSTALL_DIR) $(1)/usr/share/tinyproxy/splash/public
	$(INSTALL_BIN) ./files/gsf.png $(1)/usr/share/tinyproxy/splash/public/gsf.png
	$(INSTALL_BIN) ./files/guifinet.jpg $(1)/usr/share/tinyproxy/splash/public/guifinet.jpg
	$(INSTALL_BIN) ./files/index.html $(1)/usr/share/tinyproxy/splash/public/index.html
	$(INSTALL_BIN) ./files/puntcat.png $(1)/usr/share/tinyproxy/splash/public/puntcat.png
	$(INSTALL_BIN) ./files/qmp_big.png $(1)/usr/share/tinyproxy/splash/public/qmp_big.png
	$(INSTALL_BIN) ./files/qmp.png $(1)/usr/share/tinyproxy/splash/public/qmp.png
	$(INSTALL_DIR) $(1)/tmp/splash/whitelist	
endef

$(eval $(call BuildPackage,qmp-tinyproxy))
