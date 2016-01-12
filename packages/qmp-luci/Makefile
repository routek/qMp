#    Copyright © 2011-2016
#    Fundació Privada per a la Xarxa Oberta, Lliure i Neutral Guifi.net
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    The full GNU General Public License is included in this distribution in
#    the file named "COPYING"
#
#    Contributors:
#
#        Roger Pueyo Centelles <qmp@rogerpueyo.com>

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

QMP_RELEASE?=3.9
QMP_CODENAME?=Kalimotxo
QMP_BUILDDATE:=$(shell date +%Y%m%d_%H%M)

PKG_NAME:=qmp-luci
PKG_VERSION:=$(QMP_RELEASE)
PKG_RELEASE:=$(QMP_CODENAME)
PKG_LICENSE:=GPL-3.0+

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/qmp-luci
  TITLE:=Quick Mesh Project LuCI-based web interface
  SECTION:=net
  CATEGORY:=qMp
  URL:=http://www.qmp.cat
  DEPENDS:=+qmp-system
endef

define Package/qmp-luci/description
 This package contains the LuCI-based web interface for managing a qMp device
 from the browser
 device from the command line.
endef

define Build/Prepare
  mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/qmp-luci/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,qmp-luci))

