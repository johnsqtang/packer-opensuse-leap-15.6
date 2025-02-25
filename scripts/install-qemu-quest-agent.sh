#!/bin/bash

# install-qemu-quest-agent.sh
echo "running install-qemu-guest-agent.sh"
if [[ "$PACKER_BUILDER_TYPE" == "proxmox-iso" ]]; then
   echo "installing qemu-guest-agent ..."
   zypper install -y qemu-guest-agent
fi
