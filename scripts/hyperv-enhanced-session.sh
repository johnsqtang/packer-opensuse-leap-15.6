#!/bin/bash

# hyperv-enhanced-session.sh
if [[ ! "$PACKER_BUILDER_TYPE" == "hyperv-iso" ]]; then
   exit 0
fi

if [[ ! $PACKER_BASE_ENVIRONMENT = @(|gnome|kde|xfce) ]]; then
   exit 0
fi

# ref: https://github.com/microsoft/linux-vm-tools/blob/master/arch/install-config.sh
# but does NOT recreate /etc/pam.d/xrdp-sesman like in the post!
#
zypper install -y xrdp
systemctl enable xrdp
systemctl enable xrdp-sesman
sed -i_orig -e 's/port=3389/port=vsock:\/\/-1:3389/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' /etc/xrdp/sesman.ini
echo "allowed_users=anybody" > /etc/X11/Xwrapper.config
echo "hv_sock" > /etc/modules-load.d/hv_sock.conf
cat > /etc/polkit-1/rules.d/02-allow-colord.rules <<EOF
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.color-manager.create-device"  ||
         action.id == "org.freedesktop.color-manager.modify-profile" ||
         action.id == "org.freedesktop.color-manager.delete-device"  ||
         action.id == "org.freedesktop.color-manager.create-profile" ||
         action.id == "org.freedesktop.color-manager.modify-profile" ||
         action.id == "org.freedesktop.color-manager.delete-profile") &&
        subject.isInGroup("users"))
    {
        return polkit.Result.YES;
    }
});
EOF

# Open port 3389
firewall-cmd --add-port=3389/tcp --permanent
firewall-cmd --reload

echo "Enhanced Session Mode Installation on VM has been complete."
echo "Please turn off your VM Machine and execute 'Set-VM \"your_opensuse_vm\" -EnhancedSessionTransportType HvSocket' in PowerShell Admin and turn on again your VM Machine"
echo
