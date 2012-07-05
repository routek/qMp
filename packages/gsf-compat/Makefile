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

PKG_NAME:=gsf-compat
PKG_RELEASE:=1
#PKG_SOURCE_URL:=@SF/qmp-small-node
#PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/gsf-compat
  SECTION:=net
  CATEGORY:=qMp
  TITLE:= Compatiblity with GSF firmware for qMp
  URL:=http://graciasensefils.net
  DEPENDS:= \
	+bmx
endef


define Package/gsf-compat/description
 Addons for small qmp nodes (4MByte flash)
endef

define Package/gsf-compat/conffiles
	/etc/config/gsf-compat
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/gsf-compat/install
	$(CP) ./files/* $(1)/
	chmod 755 $(1)/etc/init.d/gsf-compat
endef


$(eval $(call BuildPackage,gsf-compat))

