#!/bin/bash

check() {
    return 255
}

depends() {
    echo base
}

install() {
    inst_hook pre-pivot 11 "$moddir/keepwickeddhcp.sh"
}
