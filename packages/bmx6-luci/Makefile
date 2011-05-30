#
# Copyright (C) 2009 Jo-Philipp Wich <xm@subsignal.org>
#
# This is free software, licensed under the Apache 2.0 license.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=bmx6-luci
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/bmx6-luci
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=Applications
  TITLE:=bmx6 luci interface
  DEPENDS:=+bmx6 +bmx6-uci-config +luci-lib-json +luci-mod-admin-core +luci-lib-httpclient
endef

define Package/bmx6-luci/description
	bmx6 web interface for luci (json)
endef

define Package/bmx6-luci/conffiles
/etc/config/luci-bmx6
endef


define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/bmx6-luci/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,bmx6-luci))

