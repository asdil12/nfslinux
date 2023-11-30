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
		# For whatever reason I can't specify the x-initrd.mount option for the actual nfs mount.
		# But I can trick systemd into keeping /run/rootfsbase mounted longer on shutdown
		# by doing this (for some reason "mounts" lists a 2nd LiveOS_rootfs type mount at /run/rootfsbase
		# where actually the nfs is mounted).
		mount -o remount,x-initrd.mount LiveOS_rootfs
	fi
fi
