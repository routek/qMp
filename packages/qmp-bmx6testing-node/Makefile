#    Copyright (C) 2011 Fundacio Privada per a la Xarxa Oberta, Lliure i Neutral guifi.net
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
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=qmp-bmx6testing-node
PKG_RELEASE:=2
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/qmp-bmx6testing-node
  SECTION:=net
  CATEGORY:=qMp
  TITLE:=Basic addons for bmx6 testing and developing
  URL:=http://qmp.cat
  DEPENDS:= \
  +qmp-system \
  +iwinfo \
  +wpad-mini \
  +iw +mtr \
  +firewall \
  +tcpdump-mini \
  +ip +iputils-ping6 
endef

define Package/qmp-bmx6testing-node/description
 Basic addons for bmx6 testing and developing
endef

define Build/Prepare
 mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/qmp-bmx6testing-node/install
    $(INSTALL_DIR) $(1)/etc/qmp
endef

$(eval $(call BuildPackage,qmp-bmx6testing-node))
