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

QMP_RELEASE?=3.2.1
QMP_CODENAME?=Clearance

PKG_NAME:=qmp-small-node
PKG_VERSION:=$(QMP_RELEASE)
PKG_RELEASE:=$(QMP_CODENAME)
PGK_LICENSE:=GPL-2.0+

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/qmp-small-node
  SECTION:=net
  CATEGORY:=qMp
  TITLE:=Standard qMp node (8 MB flash devices)
  URL:=http://qmp.cat
  DEPENDS:= +qmp-tiny-node \
	+iputils-arping +iputils-clockdiff +tcpdump-mini +b6m +b6m-spread \
	+iputils-ping6 +mtr +netperf \
	+munin-mesh +mini-snmpd +cgi-bin-zero +kmod-ipip +kmod-gre \
	+libremap-agent +luci-lib-libremap-contact +luci-lib-libremap-wireless \
	+luci +luci-lib-libremap-system +luci-lib-libremap-location +bmx6-mdns
endef

define Package/qmp-small-node/description
 This metapackage installs the packages required for setting up a typical qMp node:
  - BMX6 routing protocol
  - Luci web interface
  - qMp system configuration files
  - IP/TCP utils
  - b6m and libremap
  - SNMP and Munin
  - IP over IP support

 It is intended to be used on devices with 8 MB of flash or more.
endef


define Build/Configure
endef

define Build/Compile
endef

define Build/Prepare
 mkdir -p $(PKG_BUILD_DIR)
endef

define Package/qmp-small-node/install
    $(INSTALL_DIR) $(1)/etc/qmp
endef

$(eval $(call BuildPackage,qmp-small-node))
