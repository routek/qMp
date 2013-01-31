# qmp-ssh-keys openwrt package
#
# Copyright (C) 2011 Simó Albert i Beltran
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=qmp-ssh-keys
PKG_VERSION:=1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/qmp-ssh-keys
  SECTION:=utils
  CATEGORY:=qMp
  TITLE:=qMp admins ssh keys
  MAINTAINER:=Simó Albert i Beltran <sim6@probeta.net>
endef

define Package/qmp-ssh-keys/description
 Developers/Administrators SSH keys
endef

define Build/Compile
endef

define Package/qmp-ssh-keys/install
	$(INSTALL_DIR) $(1)/etc/dropbear
	$(INSTALL_DATA) ./files/etc/dropbear/authorized_keys $(1)/etc/dropbear/authorized_keys
endef

$(eval $(call BuildPackage,qmp-ssh-keys))
