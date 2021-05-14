#!/bin/bash

# test for root privilege
if [ "$(id -u)" -ne 0 ]; then
    echo 'The installation process requires root privileges' >&2
    exit 1
fi

# add group i2c and user piwatcher
echo 'Create group: i2c'
groupadd -f i2c
echo 'Create user: piwatcher'
id -u piwatcher &>/dev/null || adduser --system --no-create-home --disabled-login --ingroup i2c --shell /sbin/nologin piwatcher

# configure i2c devices
echo 'Setup i2c interface'
echo 'dtparam=i2c_arm=on,i2c_arm_baudrate=50000' >> /boot/config.txt
echo 'i2c-dev' >> /etc/modules
echo 'KERNEL=="i2c-[0-9]*", GROUP="i2c"' > /etc/udev/rules.d/10-local_i2c_group.rules

# link i2c-0 to i2c-1 on models 0002 and 0003 
cpuinfo=$(cat /proc/cpuinfo | grep 'Revision' | awk '{print $3}')
if [ "$cpuinfo" = '0002' ] || [ "$cpuinfo" = '0003' ]; then
    echo 'Applying patch for model B v1'
    echo 'KERNEL=="i2c-0", SYMLINK+="i2c-1"' > /etc/udev/rules.d/11-i2c-0_to_i2c-1_symlink.rules
fi

# get piwatcher
if [ ! -f /usr/local/bin/piwatcher ]; then
    echo 'Download: piwatcher'
    curl -fsSL http://omzlo.com/downloads/piwatcher -o /usr/local/bin/piwatcher
    chown piwatcher /usr/local/bin/piwatcher
    chgrp i2c /usr/local/bin/piwatcher
    chmod 110 /usr/local/bin/piwatcher
fi
# get piwatchdog.sh
if [ ! -f /usr/local/bin/piwatchdog.sh ]; then
    echo 'Download: piwatchdog.sh'
    curl -fsSL https://raw.githubusercontent.com/kwitsch/piwatchdog/main/piwatchdog.sh -o /usr/local/bin/piwatchdog.sh
    chown piwatcher /usr/local/bin/piwatchdog.sh
    chmod 500 /usr/local/bin/piwatchdog.sh
fi
# get piwatchdog.service
if [ ! -f /etc/systemd/system/piwatchdog.service ]; then
    echo 'Download: piwatchdog.service'
    curl -fsSL https://raw.githubusercontent.com/kwitsch/piwatchdog/main/piwatchdog.service -o /etc/systemd/system/piwatchdog.service
    chmod 444 /etc/systemd/system/piwatchdog.service
fi

# enable piwatchdog service
echo 'Enabling service: piwatchdog'
systemctl enable piwatchdog

echo '----------------------------------------------'
echo '| Reboot system to complete the installation |'
echo '----------------------------------------------'
