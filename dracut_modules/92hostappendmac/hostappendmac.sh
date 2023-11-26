#!/bin/sh

# append mac to hostname (or set hostname to mac if hostname is empty)

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

if getargbool 0 rd.hostappendmac ; then
	touch "$NEWROOT/etc/hostname"
	hostname=$(cat "$NEWROOT/etc/hostname")
	mac=$(cat /sys/class/net/eth0/address | tr -d :)
	[ -n "$hostname" ] && hostname="${hostname}-"
	hostname="${hostname}${mac}"
	echo "$hostname" > "$NEWROOT/etc/hostname"
fi
