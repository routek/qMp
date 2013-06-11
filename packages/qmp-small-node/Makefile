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

PKG_NAME:=qmp-small-node
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
QMP_CODENAME:=Ratafia
QMP_RELEASE:=2.0beta
QMP_BUILDDATE:=$(shell date +%Y%m%d_%H%M)

include $(INCLUDE_DIR)/package.mk

define Package/qmp-small-node
  SECTION:=net
  CATEGORY:=qMp
  TITLE:=Required addons for small qMp mesh node
  URL:=http://qmp.cat
  DEPENDS:= \
	+qmp-tiny-node \
	+olsrd +olsrd-mod-txtinfo +olsrd-mod-httpinfo +olsrd-mod-watchdog +olsrd-mod-arprefresh \
	+synctincvpn +altermap-agent \
	+iputils-arping +iputils-clockdiff +iputils-ping +iputils-tracepath +tcpdump-mini \
	+cgi-bin-zero \
	+kmod-tun +kmod-ipip \
	+b6m +b6m-spread
endef


define Package/qmp-small-node/description
 Addons for small qmp nodes (4MByte flash)
endef

define Package/qmp-small-node/conffiles
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/qmp-small-node/install
endef

$(eval $(call BuildPackage,qmp-small-node))
