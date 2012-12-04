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
#	Simó Albert i Beltran
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=qmp-small-node
PKG_RELEASE:=8
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)
QMP_CODENAME:=Ratafia
QMP_RELEASE:=1.0beta
QMP_BUILDDATE:=$(shell date +%Y%m%d_%H%M)

include $(INCLUDE_DIR)/package.mk

define Package/qmp-small-node
  SECTION:=net
  CATEGORY:=qMp
  TITLE:=Required addons for small qmp mesh nodes ( 4MByte )
  URL:=http://qmp.cat
  DEPENDS:= \
	+uhttpd +luci +luci-lib-nixio \
	+luci-ssl +iwinfo \
	+ahcpd \
	+radvd \
	+hostapd-mini +wpa-supplicant-mini \
	+wireless-tools +iw +netperf \
	+bmx6-qmp +bmx6-qmp-uci-config +bmx6-qmp-json +bmx6-qmp-sms +bmx6-luci \
	+olsrd +olsrd-mod-txtinfo +olsrd-mod-httpinfo +olsrd-mod-watchdog +olsrd-mod-arprefresh \
	+gwck-qmp +luci-theme-qmp \
	+firewall \
	+ip \
	+6in4 +6to4 \
	+ip6tables +ip6tables-utils \
	+kmod-ipip \
	+kmod-ip6-tunnel +kmod-iptunnel6 \
	+kmod-tun \
	+kmod-dummy \
	+gwck-qmp \
	+b6m-spread \

endef


define Package/qmp-small-node/description
 Addons for small qmp nodes (4MByte flash)
endef

define Package/qmp-small-node/conffiles
	/etc/config/qmp
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/qmp-small-node/install
	$(CP) ./files/* $(1)/
	$(CP) ./files/etc/config/qmp $(1)/etc/config/qmp.orig
	$(SED) 's,$$$$BRANCH,$(BRANCH_GIT),g' $(1)/etc/uci-defaults/qmp_banner
	$(SED) 's,$$$$REV,$(REV_GIT),g' $(1)/etc/uci-defaults/qmp_banner
	$(SED) 's,$$$$COD,$(QMP_CODENAME),g' $(1)/etc/uci-defaults/qmp_banner
	$(SED) 's,$$$$REL,$(QMP_RELEASE),g' $(1)/etc/uci-defaults/qmp_banner
	$(SED) 's,$$$$DATE,$(QMP_BUILDDATE),g' $(1)/etc/uci-defaults/qmp_banner
	chmod 755 $(1)/etc/init.d/qmp_autoconf
	date +%Y%m%d > $(1)/etc/qmp/qmp.version
	echo "QMP_ID=qMp" > $(1)/etc/qmp/qmp.release
	echo "QMP_CODENAME=$(QMP_CODENAME)" >> $(1)/etc/qmp/qmp.release
	echo "QMP_RELEASE=$(QMP_RELEASE)" >> $(1)/etc/qmp/qmp.release
	echo "QMP_BRANCH=$(BRANCH_GIT)" >> $(1)/etc/qmp/qmp.release
	echo "QMP_REVISION=$(REV_GIT)" >> $(1)/etc/qmp/qmp.release
	echo "QMP_BUILDDATE=$(QMP_BUILDDATE)" >> $(1)/etc/qmp/qmp.release
	echo "QMP_DESCRIPTION=\"qMp $(QMP_CODENAME) $(QMP_RELEASE), $(BRANCH_GIT) rev.$(REV_GIT)-$(QMP_BUILDDATE)\"" >> $(1)/etc/qmp/qmp.release
endef


$(eval $(call BuildPackage,qmp-small-node))

