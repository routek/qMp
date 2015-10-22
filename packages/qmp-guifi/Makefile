#    Copyright (C) 2013 Quick Mesh Project
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
#	Jorge L. Florit
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=qmp-guifi
PKG_RELEASE:=1.0.4
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/qmp-guifi
  TITLE:=Guifi Oneclick for qMp.
  SECTION:=net
  CATEGORY:=qMp
  URL:=http://guifi.net
  DEPENDS:= \
  +qmp-system
endef


define Package/qmp-guifi/description
 Guifi Oneclick for qMp. Easy configuration for Guifi.net community network Mesh nodes.
endef

define Build/Prepare
 mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/qmp-guifi/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,qmp-guifi))
