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

PKG_NAME:=qmp-big-node
PKG_RELEASE:=2
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz

include $(INCLUDE_DIR)/package.mk

define Package/qmp-big-node
  SECTION:=net
  CATEGORY:=qMp
  TITLE:=Addons for big qMp mesh node (8MByte flash or more)
  URL:=http://qmp.cat
  DEPENDS:= \
	+qmp-small-node \
	+qmp-tinyproxy +tinymce \
	+openssl-util +luci-ssl \
	+lsof \
	+olsrd +olsrd-mod-txtinfo +olsrd-mod-httpinfo +olsrd-mod-watchdog +olsrd-mod-arprefresh \
	+wget +bmon +bwm +ebtables +pv \
	+ndisc6 +rdisc6 \
	+ipv6calc
endef

define Package/qmp-big-node/description
 Addons for big qmp nodes (8MByte flash or more)
endef

$(eval $(call BuildPackage,qmp-big-node))
