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
# Contributors:
#	Pau Escrich <p4u@dabax.net>
#	Simó Albert i Beltran
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=qmp-tiny-node
PKG_RELEASE:=2
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/qmp-tiny-node
  SECTION:=net
  CATEGORY:=qMp
  TITLE:=Basic addons for default qMp node
  URL:=http://qmp.cat
  DEPENDS:= \
  +qmp-system \
  +uhttpd +iwinfo \
  +luci-app-bmx6 +luci-mod-admin-full +luci-i18n-english \
  +radvd  +wpad-mini +iw +netperf \
  +bmx6 +bmx6-uci-config +bmx6-json +bmx6-sms +bmx6-mdns \
  +gwck-qmp +luci-theme-qmp \
  +libremap-agent +luci-lib-libremap-contact +luci-lib-libremap-wireless +luci-lib-libremap-system \
  +ip +iputils-ping6
endef


define Package/qmp-tiny-node/description
 Required addons for qMp node (only needed and basic stuff)
endef

define Build/Prepare
 mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/qmp-tiny-node/install
	$(INSTALL_DIR) $(1)/etc/qmp
endef

$(eval $(call BuildPackage,qmp-tiny-node))

