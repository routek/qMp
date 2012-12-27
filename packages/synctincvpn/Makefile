#    Copyright (C) 2012 Routek http://routek.cat
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#    The full GNU General Public License is included in this distribution in
#    the file called "COPYING".

include $(TOPDIR)/rules.mk

PKG_NAME:=synctincvpn
PKG_RELEASE:=3

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/synctincvpn
  SECTION:=qmp
  CATEGORY:=qMp
  TITLE:=Configurate nodes with tincvpn
  DEPENDS:=+tinc +libopenssl +wget-nossl
  URL:=http://qmp.net/projects/synctincvpn
  MAINTAINER:=Agusti Moll i Garcia <agusti@biruji.org>
endef

define Package/synctincvpn/description
	Autoconfigurate tincvpn.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	cp src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define Build/Prepare
	$(INSTALL_DIR) $(PKG_BUILD_DIR)
	$(INSTALL_DATA) ./src/*.c $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(TARGET_CC) $(TARGET_CFLAGS) -Wall \
	        -o $(PKG_BUILD_DIR)/encrypt $(PKG_BUILD_DIR)/encrypt.c -lcrypto
	$(TARGET_CC) $(TARGET_CFLAGS) -Wall \
	        -o $(PKG_BUILD_DIR)/decrypt $(PKG_BUILD_DIR)/decrypt.c -lcrypto
endef

define Package/synctincvpn/install
	$(CP) ./files/* $(1)/
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/decrypt $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/encrypt $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,synctincvpn))
