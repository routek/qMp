#   Copyright (C) 2013 Pau Escrich <p4u@dabax.net>
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

PKG_NAME:=munin-mesh
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/munin-mesh
  TITLE:=Munin mesh agent for qMp
  SECTION:=qMp
  CATEGORY:=qMp
  URL:=http://qmp.cat
  DEPENDS:=+netcat
endef

define Package/munin-mesh/description
	Munin mesh agent for qMp
endef

define Build/Configure
endef

define Build/Compile
	@rm -rf ./build || true
	@cp -r ./src ./build
endef

define Package/munin-mesh/install
	$(INSTALL_DIR) $(1)/etc/munin-plugins
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/rc.d/

	$(CP) ./build/plugins/* $(1)/etc/munin-plugins/
	chmod 755 $(1)/etc/munin-plugins/*
	$(CP) ./build/munin-node $(1)/usr/sbin/
	chmod 755 $(1)/usr/sbin/munin-node
	$(CP) ./build/munin $(1)/etc/init.d/
	chmod 755 $(1)/etc/init.d/munin

	ln -s ../init.d/munin $(1)/etc/rc.d/S99munin
endef

$(eval $(call BuildPackage,munin-mesh))
