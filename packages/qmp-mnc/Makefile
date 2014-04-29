#    Copyright (C) 2014 Routek S.L.
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
#    Contributor:
#     Roger Pueyo Centelles <rogerpueyo@routek.net>
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=qmp-mnc
PKG_RELEASE:=0.0.1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/qmp-mnc
  TITLE:=Mesh Network Characterisation for qMp
  SECTION:=net
  CATEGORY:=qMp
  URL:=http://qmp.cat
  DEPENDS:=+luci-lib-core +luci-lib-nixio +luci-lib-sys +luci-lib-web +libiwinfo-lua
endef

define Package/qmp-mnc/description
 Mesh Network Characterisation (MNC) for qMp. The MNC package allows end users to monitor the status of a qMp mesh network in real time (active nodes, link characteristics, routes etc.) and perform management actions (select gateways, trust or ban nodes, etc.). It consists of the Network Characterisation Daemon (NCD) and the web interface. The NCD exchanges information with other MNC-enabled nodes in the mesh to gather information about the topology, quality of the links, etc. The web interface, integrated in LuCI, provides a topological and geographycal representation of the mesh along with all the details and available actions.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/qmp-system/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,qmp-mnc))
