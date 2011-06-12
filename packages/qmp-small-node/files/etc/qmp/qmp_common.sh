#!/bin/sh

qmp_uci_get() {
	echo "$(uci get qmp.$1)" 2>/dev/null
}

qmp_error() {
	echo "Error: $1"
	exit 1
}

