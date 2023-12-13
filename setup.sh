#!/bin/bash -ex

nfsroot=/srv/nfslinux
NSPAWN_CALL="systemd-nspawn --resolv-conf=bind-host -D $nfsroot"
distro="openSUSE_Tumbleweed"
#distro="15.5"
[ "$distro" != "openSUSE_Tumbleweed" ] && leap=1
dvd_iso=openSUSE-Tumbleweed-DVD-x86_64-Current.iso
#dvd_iso=no

if [ -e "$dvd_iso" ] ; then
	zypper -n --root "$nfsroot" ar -c -p 80 "iso:/?iso=$dvd_iso" dvd
fi
if [ -n "$leap" ] ; then
	zypper -n -R "$nfsroot" ar http://download.opensuse.org/update/leap/$distro/backports/ repo-backports-update
	zypper -n -R "$nfsroot" ar http://download.opensuse.org/distribution/leap/$distro/repo/non-oss/ repo-non-oss
	zypper -n -R "$nfsroot" ar http://codecs.opensuse.org/openh264/openSUSE_Leap/ repo-openh264
	zypper -n -R "$nfsroot" ar http://download.opensuse.org/distribution/leap/$distro/repo/oss/ repo-oss
	zypper -n -R "$nfsroot" ar http://download.opensuse.org/update/leap/$distro/sle/ repo-sle-update
	zypper -n -R "$nfsroot" ar http://download.opensuse.org/update/leap/$distro/oss/ repo-update
	zypper -n -R "$nfsroot" ar http://download.opensuse.org/update/leap/$distro/non-oss/ repo-update-non-oss
else
	zypper -n --root "$nfsroot" ar http://www.ftp.fau.de/opensuse/tumbleweed/repo/oss/ oss
fi
zypper -n --root "$nfsroot" ar -p 150 http://download.opensuse.org/repositories/games/${distro}/ games

zypper -n --root "$nfsroot" --gpg-auto-import-keys ref
zypper -n --root "$nfsroot" in --no-recommends \
    systemd shadow zypper openSUSE-release vim glibc-locale ca-certificates kernel-default grub2 \
    nfs-client wicked iproute2 iputils timezone less vim-data sudo psmisc curl wget openssh \
    aaa_base-extras python3 kernel-firmware-all sof-firmware ucode-intel ucode-amd usbutils biosdevname alsa-utils
if [ -e "$dvd_iso" ] ; then
	zypper -n --root "$nfsroot" mr -d dvd
fi
zypper -n --root "$nfsroot" in \
    sway dmenu alacritty bat pipewire pipewire-alsa pipewire-pulseaudio gstreamer-plugin-pipewire pavucontrol brightnessctl
zypper -n --root "$nfsroot" install --no-recommends --force-resolution emptyepsilon
if [ -n "$leap" ] ; then
	$NSPAWN_CALL rpmdb --rebuilddb
else
	zypper -n --root "$nfsroot" install --no-recommends openssh-server-config-rootlogin
fi

echo -e "linux\nlinux" | $NSPAWN_CALL -P passwd root

# add user tux with audio support
$NSPAWN_CALL useradd -m -N tux
echo -e "linux\nlinux" | $NSPAWN_CALL -P passwd tux
$NSPAWN_CALL -u tux systemctl --user enable pipewire{,-pulse}.socket

# allow login without password
rm -f "$nfsroot/etc/pam.d/common-auth"
echo "auth    sufficient      pam_localuser.so" | tee "$nfsroot/etc/pam.d/common-auth"
grep -v "^#" /etc/pam.d/common-auth-pc | tee -a "$nfsroot/etc/pam.d/common-auth"

# autologin tux on tty1
mkdir -p "$nfsroot/etc/systemd/system/getty@tty1.service.d"
port="-"
[ -n "$leap" ] && port="%I"
tee "$nfsroot/etc/systemd/system/getty@tty1.service.d/autologin.conf" <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -- \\\\u' --noclear --autologin tux --skip-login $port \$TERM
EOF

# autostart sway for tux
$NSPAWN_CALL -P -u tux tee -a "/home/tux/.bash_profile" <<EOF
if [ "\$(tty)" = "/dev/tty1" ] ; then
	exec sway
	#sway || WLR_RENDERER_ALLOW_SOFTWARE=1 sway
	exit
fi
EOF

source "$nfsroot/etc/os-release"
tee "$nfsroot/etc/issue" <<EOF

███╗   ██╗███████╗███████╗██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗
████╗  ██║██╔════╝██╔════╝██║     ██║████╗  ██║██║   ██║╚██╗██╔╝
██╔██╗ ██║█████╗  ███████╗██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝
██║╚██╗██║██╔══╝  ╚════██║██║     ██║██║╚██╗██║██║   ██║ ██╔██╗
██║ ╚████║██║     ███████║███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗
╚═╝  ╚═══╝╚═╝     ╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝

$PRETTY_NAME - \\l

Login with root/linux or tux/linux

EOF

tee "$nfsroot/etc/sysconfig/network/ifcfg-eth0" <<EOF
BOOTPROTO='dhcp'
STARTMODE='nfsroot'
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
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOF

# when making changes on nfs root while VM is running
# use dropcaches to drop inode cache
tee "$nfsroot/usr/bin/dropcaches" <<EOF
#!/bin/sh
echo 3 > /proc/sys/vm/drop_caches
EOF
chmod +x "$nfsroot/usr/bin/dropcaches"

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
input type:touchpad {
	tap enabled
}
bindsym XF86AudioRaiseVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bindsym XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindsym XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-
bindsym XF86MonBrightnessUp exec brightnessctl set 5%+
exec autostart
#exec [ -n "\$WLR_RENDERER_ALLOW_SOFTWARE=1" ] && swaynag -m "Starting sway failed! - Fallback starting it with WLR_RENDERER_ALLOW_SOFTWARE=1"
EOF
ln -sf /usr/bin/alacritty "$nfsroot/usr/local/bin/foot"

tee "$nfsroot/usr/local/bin/autostart" <<EOF
#!/usr/bin/python3

import os
for p in open('/proc/cmdline').read().strip().split(' '):
	if p.startswith('autostart='):
		e = p.split('=')[1]
		os.execvp(e, [e])
EOF
chmod +x "$nfsroot/usr/local/bin/autostart"

# disable hostonly mode so that the initrd will work everywhere
# add modules
tee "$nfsroot/etc/dracut.conf.d/99-nfslinux.conf" <<EOF
hostonly=no
hostonly_cmdline=no
add_dracutmodules+=" overlayfsify nfs keepwickeddhcp hostappendmac "
EOF

# inject custom dracut modules & generate initrd
cp -rv dracut_modules/* "$nfsroot/usr/lib/dracut/modules.d/"
$NSPAWN_CALL dracut -f --regenerate-all
$NSPAWN_CALL sh -c 'chmod a+r /boot/initrd-*'


# export fs from host
#cat /etc/exports
#/srv/nfslinux	*(ro,no_root_squash,sync,no_subtree_check)

# cmdline: ip=dhcp net.ifnames=0 root=192.168.122.1:/srv/nfslinux rd.debug rd.shell rd.overlayfsify=1 rd.keepwickeddhcp=1 rd.hostappendmac=1
