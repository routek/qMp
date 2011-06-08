#!/bin/sh

qmp_uci_get() {
	echo "$(uci get qmp.$1)" 2>/dev/null
}



