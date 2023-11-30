# NFSLinux

Create an linux system root based on openSUSE that machines can boot from using NFS and TFTP/HTTP boot.
This is designed to be used for LAN parties when playing games like SpaceNerdsInSpace or EmptyEpsilon
space bridge simulators.

The machine can boot from network directly into the game.
The NFS root is mounted readonly and there is an overlay added above so that changes can be done
locally but will only be kept in RAM.
All local changes can be seen in `/run/overlayfs`.

## A word of warning
This setup is built without any security in mind.
The PAM system is tweaked to allow login of any user (including root) without a password.
This is considered acceptable as the NFS root is readonly
and the setup is designed for LAN parties.

## NFS Server
To export the NFS root, add something like this to your `/etc/exports`:
```
/srv/nfslinux	*(ro,no_root_squash,sync,no_subtree_check)
```
Then start your NFS server (e.g. via `nfs-server.service`).

## Setup NFS root
Run `./setup.sh` as root to create your NFS root in `/srv/nfslinux`.

To make local changes, use this command:
```
systemd-nspawn --resolv-conf=bind-host -D /srv/nfslinux/
```

The kernel and initrd can be found in `/srv/nfslinux/boot/vmlinuz` and `/srv/nfslinux/boot/initrd`.
The commandline for booting should look like this:
```
ip=dhcp net.ifnames=0 root=192.168.122.1:/srv/nfslinux rd.shell rd.overlayfsify=1 rd.keepwickeddhcp=1 rd.hostappendmac=1 autostart=EmptyEpsilon
```

