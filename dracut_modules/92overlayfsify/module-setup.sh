#!/bin/bash

check() {
    return 255
}

depends() {
    echo base
}

installkernel() {
    instmods overlay
}

install() {
    inst_hook pre-pivot 10 "$moddir/overlayfsify.sh"
}
