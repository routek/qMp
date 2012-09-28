# tinymce openwrt package
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
# Version 0.1.20111212.1.0

include $(TOPDIR)/rules.mk

PKG_NAME:=tinymce
PKG_VERSION:=3.4.9
PKG_RELEASE:=1

PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_SOURCE_SUBDIR)
PKG_SOURCE:=$(PKG_NAME)_$(PKG_VERSION).zip
PKG_SOURCE_URL:=http://github.com/downloads/tinymce/tinymce/
PKG_MD5SUM:=6d56cbeefc9371257d837104dbe928d5
PKG_UNPACK:=unzip -d $(PKG_BUILD_DIR)/ $(DL_DIR)/$(PKG_SOURCE)

include $(INCLUDE_DIR)/package.mk

define Package/tinymce
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=TinyMCE is a Javascript HTML WYSIWYG editor.
  URL:=http://www.tinymce.com
  MAINTAINER:=Simó Albert i Beltran <sim6@probeta.net>
endef

define Package/tinymce/description
TinyMCE is a platform independent web based Javascript HTML WYSIWYG editor control released as Open Source under LGPL by Moxiecode Systems AB.

TinyMCE has the ability to convert HTML TEXTAREA fields or other HTML elements to editor instances. TinyMCE is very easy to integrate into other Content Management Systems.
TinyMCE is a WYSIWIG web editor.
endef

define Build/Compile
endef

define Package/tinymce/install
	$(INSTALL_DIR) $(1)/www
	$(CP) $(PKG_BUILD_DIR)/tinymce/jscripts/tiny_mce $(1)/www/
endef

$(eval $(call BuildPackage,tinymce))
