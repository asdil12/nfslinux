#!/bin/bash

mkdir -p /srv/tftpboot/
test -d ipxe || git clone https://github.com/ipxe/ipxe.git
pushd ipxe/src
make -j20 EMBED=../../boot.ipxe bin/ipxe.pxe bin/undionly.kpxe bin-x86_64-efi/ipxe.efi
sudo cp -v bin/ipxe.pxe bin/undionly.kpxe bin-x86_64-efi/ipxe.efi /srv/tftpboot/
popd
sudo cp -v menu.ipxe /srv/tftpboot/

# if you want to use PXELINUX for BIOS clients
#sudo ln -svf /usr/share/syslinux/{pxelinux.0,menu.c32} /srv/tftpboot/
#sudo ln -svf /srv/nfslinux /srv/tftpboot/
#sudo mkdir /srv/tftpboot/pxelinux.cfg
#sudo cp -v pxelinux.default /srv/tftpboot/pxelinux.cfg/default
