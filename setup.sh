#!/bin/bash -ex

nfsroot=/srv/nfslinux
NSPAWN_CALL="systemd-nspawn --resolv-conf=bind-host -D $nfsroot"
dvd_iso=openSUSE-Tumbleweed-DVD-x86_64-Current.iso

if [ -e "$dvd_iso" ] ; then
	zypper -n --root "$nfsroot" ar -c "iso:/?iso=$dvd_iso" dvd
	zypper -n --root "$nfsroot" --gpg-auto-import-keys ref
else
	zypper -n --root "$nfsroot" ar -c http://www.ftp.fau.de/opensuse/tumbleweed/repo/oss/ oss
fi
zypper -n --root "$nfsroot" in --no-recommends systemd shadow zypper openSUSE-release vim glibc-locale ca-certificates kernel-default grub2 nfs-client wicked iproute2 timezone less
if [ -e "$dvd_iso" ] ; then
	zypper -n --root "$nfsroot" mr -d dvd
	zypper -n --root "$nfsroot" ar -c http://www.ftp.fau.de/opensuse/tumbleweed/repo/oss/ oss
	zypper -n --root "$nfsroot" --gpg-auto-import-keys ref
fi
zypper -n --root "$nfsroot" in sway dmenu alacritty bat pipewire

zypper -n --root "$nfsroot" ar obs://games games
zypper -n --root "$nfsroot" --gpg-auto-import-keys ref
zypper -n --root "$nfsroot" install --no-recommends emptyepsilon

echo -e "linux\nlinux" | $NSPAWN_CALL -P passwd root

tee "$nfsroot/etc/sysconfig/network/ifcfg-eth0" <<EOF
BOOTPROTO='dhcp'
STARTMODE='hotplug'
EOF

echo "nfslinux" | tee "$nfsroot/etc/hostname"

tee "$nfsroot/etc/systemd/journald.conf" <<EOF
[Journal]
Storage=volatile
SystemMaxUse=10MB
EOF

# force shutdown as network would come down before NFS is unmounted resulting in freeze
# ignore power buttons
tee "$nfsroot/etc/systemd/logind.conf" <<EOF
[Login]
HandlePowerKey=ignore
HandlePowerKeyLongPress=ignore
HandleRebootKey=ignore
HandleRebootKeyLongPress=ignore
HandleSuspendKey=ignore
HandleSuspendKeyLongPress=ignore
HandleHibernateKey=ignore
HandleHibernateKeyLongPress=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOF

tee "$nfsroot/etc/profile.d/nfslinux.sh" <<EOF
alias reboot="reboot -f"
alias poweroff="poweroff -f"
alias dropcaches="echo 3 > /proc/sys/vm/drop_caches"
EOF

# set timezone and enable NTP client
ln -sf /usr/share/zoneinfo/Europe/Berlin "$nfsroot/etc/localtime"
$NSPAWN_CALL systemctl enable systemd-timesyncd

tee "$nfsroot/etc/vconsole.conf" <<EOF
KEYMAP=de-nodeadkeys
XKBLAYOUT=de
XKBMODEL=microsoftpro
XKBVARIANT=nodeadkeys
XKBOPTIONS=terminate:ctrl_alt_bksp
EOF

mkdir -p  "$nfsroot/etc/sway/config.d/"
tee "$nfsroot/etc/sway/config.d/nfslinux" <<EOF
input * {
	xkb_layout "de"
	xkb_variant "nodeadkeys"
}
EOF
ln -sf /usr/bin/alacritty "$nfsroot/usr/local/bin/foot"

# disable hostonly mode so that the initrd will work everywhere
echo "hostonly=no" | tee "$nfsroot/etc/dracut.conf.d/99-nfsoverlay.conf"
echo "hostonly_cmdline=no" | tee -a "$nfsroot/etc/dracut.conf.d/99-nfsoverlay.conf"

# inject custom dracut modules & generate initrd
cp -rv dracut_modules/* "$nfsroot/usr/lib/dracut/modules.d/"
$NSPAWN_CALL dracut -f --regenerate-all --add "overlayfsify nfs keepwickeddhcp hostappendmac"


# export fs from host
#cat /etc/exports
#/srv/nfslinux	*(ro,no_root_squash,sync,no_subtree_check)

# cmdline: ip=dhcp net.ifnames=0 root=192.168.122.1:/srv/nfslinux rd.debug rd.shell rd.overlayfsify=1 rd.keepwickeddhcp=1 rd.hostappendmac=1
