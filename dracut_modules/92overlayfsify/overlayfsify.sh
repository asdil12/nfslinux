#!/bin/sh

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh
if getargbool 0 rd.overlayfsify ; then
	if ! [ -e /run/rootfsbase ]; then
		mkdir -m 0755 -p /run/rootfsbase
		mount --bind "$NEWROOT" /run/rootfsbase
	fi

	mkdir -m 0755 -p /run/overlayfs
	mkdir -m 0755 -p /run/ovlwork

	if ! strstr "$(cat /proc/mounts)" LiveOS_rootfs; then
		mount -t overlay LiveOS_rootfs -o "lowerdir=/run/rootfsbase,upperdir=/run/overlayfs,workdir=/run/ovlwork" "$NEWROOT"
	fi
fi
