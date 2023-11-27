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
zypper -n --root "$nfsroot" in --no-recommends systemd shadow zypper openSUSE-release vim glibc-locale ca-certificates kernel-default grub2 nfs-client wicked iproute2 timezone less vim-data sudo psmisc
if [ -e "$dvd_iso" ] ; then
	zypper -n --root "$nfsroot" mr -d dvd
	zypper -n --root "$nfsroot" ar -c http://www.ftp.fau.de/opensuse/tumbleweed/repo/oss/ oss
	zypper -n --root "$nfsroot" --gpg-auto-import-keys ref
fi
zypper -n --root "$nfsroot" in sway dmenu alacritty bat pipewire pipewire-alsa pipewire-pulseaudio gstreamer-plugin-pipewire pavucontrol brightnessctl
#zypper -n --root "$nfsroot" in --no-recommends pulseaudio-utils pavucontrol brightnessctl

zypper -n --root "$nfsroot" ar obs://games games
zypper -n --root "$nfsroot" --gpg-auto-import-keys ref
zypper -n --root "$nfsroot" install --no-recommends emptyepsilon

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
tee "$nfsroot/etc/systemd/system/getty@tty1.service.d/autologin.conf" <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -- \\\\u' --noclear --autologin tux --skip-login - \$TERM
EOF

# autostart sway for tux
echo '[ "$(tty)" = "/dev/tty1" ] && exec sway' | $NSPAWN_CALL -P -u tux tee -a "/home/tux/.bash_profile"

tee "$nfsroot/etc/issue" <<EOF

███╗   ██╗███████╗███████╗██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗
████╗  ██║██╔════╝██╔════╝██║     ██║████╗  ██║██║   ██║╚██╗██╔╝
██╔██╗ ██║█████╗  ███████╗██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝
██║╚██╗██║██╔══╝  ╚════██║██║     ██║██║╚██╗██║██║   ██║ ██╔██╗
██║ ╚████║██║     ███████║███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗
╚═╝  ╚═══╝╚═╝     ╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝

Login with root/linux or tux/linux

EOF

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
bindsym XF86AudioRaiseVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bindsym XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindsym XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-
bindsym XF86MonBrightnessUp exec brightnessctl set 5%+
exec autostart
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
echo "hostonly=no" | tee "$nfsroot/etc/dracut.conf.d/99-nfsoverlay.conf"
echo "hostonly_cmdline=no" | tee -a "$nfsroot/etc/dracut.conf.d/99-nfsoverlay.conf"

# inject custom dracut modules & generate initrd
cp -rv dracut_modules/* "$nfsroot/usr/lib/dracut/modules.d/"
$NSPAWN_CALL dracut -f --regenerate-all --add "overlayfsify nfs keepwickeddhcp hostappendmac"


# export fs from host
#cat /etc/exports
#/srv/nfslinux	*(ro,no_root_squash,sync,no_subtree_check)

# cmdline: ip=dhcp net.ifnames=0 root=192.168.122.1:/srv/nfslinux rd.debug rd.shell rd.overlayfsify=1 rd.keepwickeddhcp=1 rd.hostappendmac=1
