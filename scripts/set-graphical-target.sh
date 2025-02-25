#!/bin/bash -eux

# set-graphical-target.sh

if [[ $PACKER_BASE_ENVIRONMENT = @(|gnome|kde|xfce) ]]; then
   echo "Set to graphical target - $PACKER_DISTRO"
   systemctl set-default graphical.target
fi
