#!/bin/bash -ex

##########################################################################################
# Disable SELINUX
sed -e 's/^SELINUX=enforcing/SELINUX=disabled/' -i /etc/selinux/config
sed -e 's/^SELINUX=permissive/SELINUX=disabled/' -i /etc/selinux/config

##########################################################################################
# Set swappiness to minimum
echo 0 | tee /proc/sys/vm/swappiness

# Set the value in /etc/sysctl.conf so it stays after reboot.
echo '' >> /etc/sysctl.conf
echo '#Set swappiness to 0 to avoid swapping' >> /etc/sysctl.conf
echo 'vm.swappiness = 0' >> /etc/sysctl.conf

##########################################################################################
# Disable some not-required services.
chkconfig cups off
chkconfig postfix off
chkconfig iptables off
chkconfig ip6tables off

service iptables stop
service ip6tables stop

##########################################################################################
# Ensure NTPD is turned on and run update
chkconfig ntpd on
ntpd -q
service ntpd start

##########################################################################################
#Disable transparent huge pages
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo no > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag 

echo '' >> /etc/rc.local
echo '#Disable THP' >> /etc/rc.local
echo 'if test -f /sys/kernel/mm/transparent_hugepage/enabled; then' >> /etc/rc.local
echo '  echo never > /sys/kernel/mm/transparent_hugepage/enabled' >> /etc/rc.local
echo 'fi' >> /etc/rc.local
echo '' >> /etc/rc.local
echo 'if test -f /sys/kernel/mm/transparent_hugepage/defrag; then' >> /etc/rc.local
echo '   echo never > /sys/kernel/mm/transparent_hugepage/defrag' >> /etc/rc.local
echo 'fi' >> /etc/rc.local
echo '' >> /etc/rc.local
echo 'if test -f /sys/kernel/mm/transparent_hugepage/khugepaged/defrag; then' >> /etc/rc.local
echo '   echo no > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag' >> /etc/rc.local
echo 'fi' >> /etc/rc.local

##########################################################################################
#Remove existing mount points
sed '/^\/dev\/xvd[b-z]/d' -i /etc/fstab

#Fromat emphemeral drives and create mounts
for drv in `ls /dev/xv* | grep -v xvda`
do
  umount $drv || :
  mkdir -p ${drv//dev/data}
  echo "$drv ${drv//dev/data} ext4 defaults,noatime,nodiratime 0 0" >> /etc/fstab
  nohup mkfs.ext4 -m 0 -T largefile4 $drv &
done
wait

##########################################################################################
# Re-size root partition
(echo u;echo d; echo n; echo p; echo 1; cat /sys/block/xvda/xvda1/start; echo; echo w) | fdisk /dev/xvda || :