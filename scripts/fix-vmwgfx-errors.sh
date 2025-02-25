#!/bin/bash

# fix-vmwgfx-errors.sh
#
# This script fixes the error message - "vmwgfx 0000:00:02.0: [drm] *ERROR* vmwgfx seems to be running on an unsupported hypervisor" that
# appears at the console login screen.
# 
# The fix comes from https://unix.stackexchange.com/questions/502540/why-does-drmvmw-host-log-vmwgfx-error-failed-to-send-host-log-message-sh
#
echo "running install-cloud-init.sh"
if [[ "$PACKER_BUILDER_TYPE" == "virtualbox-iso" ]]; then
   echo "fix vmwgfx 0000:00:02.0: [drm] *ERROR* ..."
   sed -i -e 's/ mitigations/ nomodeset mitigations/g' /etc/default/grub
   grub2-mkconfig -o /boot/grub2/grub.cfg
fi
