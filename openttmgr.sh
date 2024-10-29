#!/usr/bin/env bash
set -eo pipefail

MOUNT_POINT=""

check_connectivity(){
    if [[ $(lsusb | grep "Mentor Graphics") ]]; then
        echo "TipToi is connected via USB"
    else
        echo "TipToi is not connected."
    fi
}

check_mount(){
    if [[ $(mount | grep tiptoi) ]]; then
        _mount_point=$(mount | grep tiptoi | cut -d " " -f3)
        echo "TipToi is mounted at $_mount_point"
        MOUNT_POINT=$_mount_point
    else
        read -r -p "TipToi is not mounted. Mount now? [y/N] " response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                mount_tiptoi
        fi
    fi
}

mount_tiptoi(){
    #TODO: mount via fuse
    echo "Not implemented"
}

list_tiptoi_files(){
    if [[ "$MOUNT_POINT" != "" ]]; then
        find "$MOUNT_POINT" -iname "*.gme"  -printf "%f\n" | sort
    else
        check_connectivity
        check_mount
    fi
}

main(){
    check_connectivity
    check_mount
    list_tiptoi_files
}

main