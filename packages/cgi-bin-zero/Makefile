# cgi-bin-zero openwrt package
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
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=cgi-bin-zero
PKG_VERSION:=1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/cgi-bin-zero
  SECTION:=utils
  CATEGORY:=qMp
  TITLE:=cgi-bin/zero
  MAINTAINER:=Simó Albert i Beltran <sim6@probeta.net>
endef

define Package/cgi-bin-zero/description
 cgi-bin/zero dummy script
endef

define Build/Compile
endef

define Package/cgi-bin-zero/install
	$(INSTALL_DIR) $(1)/www/cgi-bin
	$(INSTALL_BIN) ./files/www/cgi-bin/zero $(1)/www/cgi-bin/zero
endef

$(eval $(call BuildPackage,cgi-bin-zero))

