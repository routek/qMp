# 
# Copyright (C) 2011 qmp.cat
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=qmp-big-node
PKG_RELEASE:=1
PKG_SOURCE_URL:=@SF/qmp-big-node


PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz

include $(INCLUDE_DIR)/package.mk

define Package/qmp-big-node
  SECTION:=net
  CATEGORY:=Base system
  TITLE:=Required addons for big qmp mesh nodes (8MByte flash or more)
  URL:=http://qmp.cat
  DEPENDS:= \
	+qmp-small-node \
	+openvpn \
	+openssl-util \
        +tcptraceroute6 \
	+iperf +mtr +netcat +netperf +tcpdump \
	+nmap +lsof \
	+wget \
	+ipv6calc \
	+bmon +bwm +ebtables \

    
endef

# for qmp-big-node-testing:

define CommentsAndOptions
  DEPENDS_COMMENT:= \
	+luci-mod-freifunk-community \
	+olsrd +olsrd-mod-txtinfo +olsrd-mod-httpinfo +olsrd-mod-watchdog +olsrd-mod-arprefresh \
        +olsrd-eigennet +olsrd-eigennet-mod-dyn-gw +olsrd-eigennet-mod-httpinfo +olsrd-eigennet-mdns +olsrd-eigennet-mod-arprefresh +olsrd-eigennet-mod-txtinfo  +bmxe +bmx-uci-config +bmx-gsf-map \
	+eigennet-autoconf \
	+gsf-map-minimal \
	+gsf-map-full \
	+wpa-supplicant-mini \
	+hostapd-mini \
 


endef
#       +niit \
#	+tcpdump \
#	+bwm +wprobe-export \

#	+small-mesh-node +gsf-map-full \
#	+wget \
#	+bwm +wprobe-export \
#	+kmod-usb-core +kmod-usb-net +kmod-usb-ohci +kmod-usb2 +kmod-rt73-usb \
#	+kmod-p54-usb +kmod-rt2500-usb +kmod-rt2800-usb \
#	+kmod-zd1211rw \
#	+kmod-rtl8187 \
#	+kmod-ath +kmod-ath9k \
#	+iw \
#	+libopenssl \
#	+openvpn \
#
#	+luci-app-openvpn \
#	+openssl-util \
#	+libnl-tiny \
#	+luci-app-openvpn \
#	+wprobe-export \  # I guess this one causes the crc-ccitt compile ERROR
#	+usbutils \
#	+hostapd +hostapd-utils \ # causing recursive dependency

#  KCONFIG:=CONFIG_KERNEL_KALLSYMS CONFIG_GDB


define Package/qmp-big-node/description
 Addons for big qmp nodes (8MByte flash or more)
endef



$(eval $(call BuildPackage,qmp-big-node))
