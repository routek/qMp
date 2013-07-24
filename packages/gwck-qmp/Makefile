# gwck-qmp openwrt package
#
# Copyright (C) 2011 Simó Albert i Beltran
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Version 0.1.20120427.2.0

include $(TOPDIR)/rules.mk

PKG_NAME:=gwck-qmp

PKG_SOURCE_PROTO:=git

PKG_SOURCE_URL:=git://qmp.cat/gwck.git
PKG_REV:=1dd66e60a351e7e6d59263216be8898d477a638f
PKG_VERSION:=r2013072401

PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_SOURCE_SUBDIR)

include $(INCLUDE_DIR)/package.mk

define Package/gwck-qmp
  SECTION:=net
  CATEGORY:=qMp
  SUBMENU:=Routing and Redirection
  TITLE:=Check gateway and control bmx6 tunnels.
  URL:=http://qmp.net/projects/gwck
  MAINTAINER:=Simó Albert i Beltran <sim6@graciasensefils.net>
  MENU:=1
  DEPENDS:=+fping +bmx6
endef

define Package/gwck-qmp/description
gwck is a tool to check gateway connectivity and perform actions in consequence.
This package runs gwck to control bmx6 tunnels.
endef

define Build/Compile
endef

define Package/gwck-qmp/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/gwck $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/gwck $(1)/etc/gwck/module
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/usr/bin/gwck $(1)/usr/bin/gwck
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/etc/gwck/gwck_conf $(1)/etc/gwck/gwck_conf
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/etc/gwck/gwck_conf_qmp $(1)/etc/gwck/gwck_conf_qmp
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/etc/gwck/gwck_conf_qmp_ipv4 $(1)/etc/gwck/gwck_conf_qmp_ipv4
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/etc/gwck/gwck_conf_qmp_ipv6 $(1)/etc/gwck/gwck_conf_qmp_ipv6
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/etc/gwck/module/wait_default $(1)/etc/gwck/module/wait_default
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/etc/gwck/module/specific_routes $(1)/etc/gwck/module/specific_routes
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/etc/gwck/module/qmp $(1)/etc/gwck/module/qmp
endef


define Package/gwck-qmp/conffiles
/etc/gwck/gwck_conf
/etc/gwck/gwck_conf_qmp
/etc/gwck/gwck_conf_qmp_ipv4
/etc/gwck/gwck_conf_qmp_ipv6
endef

$(eval $(call BuildPackage,gwck-qmp))
