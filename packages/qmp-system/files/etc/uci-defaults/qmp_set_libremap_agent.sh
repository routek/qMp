#!/bin/sh
[ "$(uci -q get libremap.@libremap[0].community)" == "FIXME" ] && {
	uci set libremap.@libremap[0].community=qMp.cat
	uci commit
}
