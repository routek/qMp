# 
# Copyright (C) 2011 qmp.cat
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=qmp-small-node
PKG_RELEASE:=1
PKG_SOURCE_URL:=@SF/qmp-small-node


PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz

include $(INCLUDE_DIR)/package.mk

define Package/qmp-small-node
  SECTION:=net
  CATEGORY:=Base system
  TITLE:=Required addons for small qmp mesh nodes ( 4MByte )
  URL:=http://qmp.cat
  DEPENDS:= \
	+luci-ssl \
	+horst \
	+iputils-arping +iputils-clockdiff +iputils-ping +iputils-tracepath \
	+ahcpd \
	+radvd \
	+wide-dhcpv6-client +wide-dhcpv6-control +wide-dhcpv6-server \
	+bmx6-qmp +bmx6-qmp-uci-config +bmx6-qmp-json \
	+olsrd +olsrd-mod-txtinfo +olsrd-mod-httpinfo +olsrd-mod-watchdog +olsrd-mod-arprefresh \
	+luci-i18n-catalan +luci-i18n-spanish +luci-i18n-french \
	+babeld \
	+ntpclient +ip \
	+ndisc6 +rdisc6 +rdnssd \
	+6in4 +6to4 \
	+ip6tables +ip6tables-utils \
	+kmod-niit \
	+kmod-ipip \
	+kmod-tun \
	+kmod-madwifi \

    
endef


define Package/qmp-small-node/description
 Addons for small qmp nodes (4MByte flash)
endef



$(eval $(call BuildPackage,qmp-small-node))
