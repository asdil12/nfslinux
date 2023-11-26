#!/bin/sh

# copy the duid.xml, iaid.xml and lease-eth0-dhcp-ipv4.xml
# so that the system can keep its dhcp lease

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

if getargbool 0 rd.keepwickeddhcp ; then
	cp -v /var/lib/wicked/* "$NEWROOT/var/lib/wicked/"  
fi
