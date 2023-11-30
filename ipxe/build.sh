#!/bin/bash

mkdir -p /srv/tftpboot/
test -d ipxe || git clone https://github.com/ipxe/ipxe.git
pushd ipxe/src
make -j20 EMBED=../../boot.ipxe bin/ipxe.pxe bin-x86_64-efi/ipxe.efi
sudo cp -v bin/ipxe.pxe bin-x86_64-efi/ipxe.efi /srv/tftpboot/
popd
sudo cp -v menu.ipxe /srv/tftpboot/
