#
# Copyright (C) 2008 Freifunk Leipzig
# Copyright (C) 2009 Agusti Moll, Simó Albert
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# $Id$

include $(TOPDIR)/rules.mk

PKG_NAME:=bmx
PKG_SOURCE_URL:=git://github.com/axn/bmxd.git

PKG_REV:=9c1d12b554dccd2efde249f5e44a7d4de59ce1a8
PKG_VERSION:=r20100415
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_SOURCE_SUBDIR)

include $(INCLUDE_DIR)/package.mk

define Package/bmx
$(call Package/bmx/Default)
  SECTION:=net
  CATEGORY:=qMp
  DEPENDS:=+kmod-tun +libuci +libpthread
  TITLE:=B.A.T.M.A.N. Experimental (BMX) layer 3 routing daemon
  URL:=http://www.open-mesh.net/
endef

define Package/bmx/description
B.A.T.M.A.N. Experimental (BMX) layer 3 routing daemon
endef

MAKE_ARGS += \
	EXTRA_CFLAGS="$(TARGET_CFLAGS)" \
	CCFLAGS="$(TARGET_CFLAGS)" \
	OFLAGS="$(TARGET_CFLAGS)" \
	REVISION="$(PKG_REV)" \
	CC="$(TARGET_CC)" \
	NODEBUG=1 \
	UNAME="Linux" \
	INSTALL_PREFIX="$(PKG_INSTALL_DIR)" \
	STRIP="/bin/true" \
	bmxd install_all

define Build/Configure
       $(call Build/Configure/Default, \
                CFLAGS=$(STAGING_DIR)/usr/include \
                LDFLAGS="-L$(STAGING_DIR)/usr/lib" \
        )
	mkdir -p $(PKG_INSTALL_DIR)/usr/sbin
	mkdir -p $(PKG_INSTALL_DIR)/usr/lib
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) $(MAKE_ARGS)
endef

define Package/bmx/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/usr/lib $(1)/etc/config $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/bmxd $(1)/usr/sbin/bmxd
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/lib/*.so $(1)/usr/lib/
	$(INSTALL_BIN) ./files/etc/init.d/bmxd $(1)/etc/init.d
	$(INSTALL_DATA) ./files/etc/config/bmx $(1)/etc/config/bmx
endef

$(eval $(call BuildPackage,bmx))
