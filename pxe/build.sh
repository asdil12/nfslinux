#!/bin/bash

mkdir -p /srv/tftpboot/
test -d ipxe || git clone https://github.com/ipxe/ipxe.git
pushd ipxe/src
make -j20 EMBED=../../boot.ipxe bin/ipxe.pxe bin/undionly.kpxe bin-x86_64-efi/ipxe.efi bin-x86_64-efi/snponly.efi
sudo cp -v bin/ipxe.pxe bin/undionly.kpxe bin-x86_64-efi/ipxe.efi bin-x86_64-efi/snponly.efi /srv/tftpboot/
popd
sudo cp -v menu.ipxe /srv/tftpboot/

# bin/ipxe.pxe uses iPXE network drivers on BIOS systems
# bin/undionly.kpxe uses generic PXE UNDI pxe firmware network driver on BIOS systems (this should always work)
# bin-x86_64-efi/ipxe.efi uses iPXE network drivers on UEFI systems
# bin-x86_64-efi/snponly.efi uses generic PXE SNP network driver un UEFI systems (this should always work)
# bin-x86_64-efi/snp.efi is similar to snponly.efi but would try all network cards - not only the one it was chainloaded via

# if you want to use PXELINUX for BIOS clients
#sudo ln -svf /usr/share/syslinux/{pxelinux.0,menu.c32} /srv/tftpboot/
#sudo ln -svf /srv/nfslinux /srv/tftpboot/
#sudo mkdir /srv/tftpboot/pxelinux.cfg
#sudo cp -v pxelinux.default /srv/tftpboot/pxelinux.cfg/default
