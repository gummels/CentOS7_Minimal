#version=RHEL7

# System authorization information
auth --enableshadow --passalgo=sha512

# Use CDROM installation media
cdrom

# Run in text mode
cmdline

# Poweroff the system after install
poweroff

# Just use first disk
ignoredisk --only-use=sda

# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'

# System language
lang en_US.UTF-8

# Network information
network  --bootproto=dhcp --device=enp0s3 --onboot=on --ipv6=auto
network  --hostname=localhost.localdomain

# Root password
rootpw --iscrypted $6$WpONJqh5BSmlLXkq$1a3DNr2.qAFBAuyR/Yo00tHNJNAMHlXxYo1ysKxjjjQanMBO9qHSzMAUhQsmbWVSC1JTVgE9FmxM4fpdTbe97/

# System timezone
timezone America/New_York --isUtc
user --groups=wheel --name=vagrant --password=$6$Ljw4oYGVP5wzSm0i$O693rOrv5s0/G7WiuDNsv8o/URDf5cByIBMuN1vHf0pgbv03OoG5/i6OU1in416LNvQt2VdjNyeefMVP5CZRC/ --iscrypted --gecos="vagrant"

# System bootloader configuration
bootloader --location=mbr --boot-drive=sda

# Partition clearing information
clearpart --all --initlabel --drives=sda

# Disk partitioning information
part /boot --fstype="xfs" --ondisk=sda --size=500 --label=C7M_BOOT
part / --fstype="xfs" --ondisk=sda --size=8715 --label=C7M_ROOT
part swap --fstype="swap" --ondisk=sda --size=1024 --label=C7M_SWAP

# Packages
%packages
@core
-aic94xx-firmware
-alsa-firmware
-alsa-tools-firmware
-ivtv-firmware
-iwl1000-firmware
-iwl100-firmware
-iwl105-firmware
-iwl135-firmware
-iwl2000-firmware
-iwl2030-firmware
-iwl3160-firmware
-iwl3945-firmware
-iwl4965-firmware
-iwl5000-firmware
-iwl5150-firmware
-iwl6000-firmware
-iwl6000g2a-firmware
-iwl6000g2b-firmware
-iwl6050-firmware
-iwl7260-firmware
-libertas-sd8686-firmware
-libertas-sd8787-firmware
-libertas-usb8388-firmware
%end

# Post Installation Scripts
%post --log=/root/anaconda-post.log
exec < /dev/tty6 > /dev/tty6 2> /dev/tty6
/usr/bin/chvt 6

# Put vagrant user in sudoers.d file
/bin/echo "##Setting up vagrant sudoers.d file##"
/bin/echo -e 'Defaults:vagrant !requiretty' > /etc/sudoers.d/001_vagrant
/bin/echo -e 'vagrant\tALL=(ALL)\tNOPASSWD: ALL' >> /etc/sudoers.d/001_vagrant
/bin/chmod 440 /etc/sudoers/001_vagrant

# Set up vagrant user ssh
/bin/echo "##Setting up vagrant user ssh"
/bin/mkdir /home/vagrant/.ssh
/bin/chmod 700 /home/vagrant/.ssh
/bin/curl -o /home/vagrant/.ssh/authorized_keys "https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub"
/bin/chmod 600 /home/vagrant/.ssh/authorized_keys
/bin/curl -o /home/vagrant/.ssh/id_rsa "https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant"
/bin/chmod 600 /home/vagrant/.ssh/id_rsa
/bin/chown -R vagrant:vagrant /home/vagrant/.ssh
/bin/ls -R /home/vagrant/.ssh

# Install EPEL Repo
/bin/echo "##Install EPEL Repo##"
/bin/yum -y install http://download.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-2.noarch.rpm

# Install Puppet Repo
/bin/echo "##Install Puppet Repo##"
/bin/yum -y install https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm

# Update
/bin/echo "##Updating Installed Base##"
/bin/yum -y update

# Set vagrant-release
/bin/echo "##Setting vagrant-release##"
LATESTKERNEL=`/bin/rpm -q kernel | tail -n1`
KERNELVERSION=`/bin/echo ${LATESTKERNEL} | /bin/awk -F. '{printf("%d%03d",$4,$5)}'`
/bin/echo -e "CentOS7_Minimal 7.0.${KERNELVERSION}" > /etc/vagrant-release
/bin/cat /etc/vagrant-release

# Install the development tools required for Virtual Box Guest Additions
/bin/echo "##Installing tools required for VirtualBox Guest Additions installer##"
/bin/yum -y install bzip2 gcc make `/bin/echo ${LATESTKERNEL}| sed -e 's/kernel/kernel-devel/'`

# Install puppet agent
/bin/echo "##Installing puppet##"
/bin/yum -y install puppet

# Install firstboot oneshot service and scripts

/bin/echo "##Setting up firstboot service##"

/bin/curl -o /usr/lib/systemd/system/firstboot.service  http://10.0.2.2:7777/firstboot.service
/bin/systemctl enable firstboot.service

# The way the script works is that the service is looking for /root/firstboot.script which will be a link
# to the bootstageN.script that needs to be executed.  Once the bootstageN.script executes it will 
# re-link to the next bootstageN.script that needs to execute.

/bin/echo "##Setting up bootstage1.script##"

/bin/curl -o /root/bootstage1.script http://10.0.2.2:7777/bootstage1.script
/bin/ln -sf /root/bootstage1.script /root/firstboot.script
/bin/chmod +x /root/bootstage1.script

#/bin/echo "##Setting up bootstage2.script##"

#/bin/curl -o /root/bootstage2.script http://10.0.2.2:7777/bootstage2.script
#/bin/chmod +x /root/bootstage2.script


#/bin/cp /etc/fstab /root/bootstage.fstab

#for LABEL in `/bin/lsblk -nplo label,name |/bin/awk '/C7M_/{printf("%s=%s\n",$1,$2)}'`
#do
#  declare ${LABEL}
#done

#/bin/cat <<- EOF > /etc/fstab
#${C7M_ROOT}	/	xfs	defaults	1 1
#${C7M_BOOT}	/boot	xfs	defaults	1 2
#${C7M_SWAP}	swap	swap	defaults	0 0
#EOF

/usr/bin/chvt 1
%end
