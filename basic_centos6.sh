#!/bin/bash
mkdir /var/www/html/ks/BASIC
ks_path="/var/www/html/ks/BASIC/"

cat kscfg | while read c1 c2 c3 c4 c5 c6 c7 c8 c9 c10 c11 c12 c13 c14 c15
do
if [ -d $ks_path$c1 ];then
echo "the directory exists already"
else
mkdir $ks_path$c1
fi

echo "install" > $ks_path$c1/$c3
echo "key --skip" >> $ks_path$c1/$c3
echo "url --url http://172.23.11.51/os/"$c7"/" >> $ks_path$c1/$c3

echo "lang en_US.UTF-8" >> $ks_path$c1/$c3
echo "keyboard us" >> $ks_path$c1/$c3

echo "network --bootproto=static --device=eth0 --gateway="$c10" --ip="$c8" --nameserver=172.23.11.231 --netmask="$c9" --hostname="$c3" --onboot=on" >> $ks_path$c1/$c3

echo "rootpw "$c11 >> $ks_path$c1/$c3
echo "authconfig --enableshadow --enablemd5" >> $ks_path$c1/$c3

echo "firewall --disable" >> $ks_path$c1/$c3
echo "selinux --disable" >> $ks_path$c1/$c3
echo "timezone --utc Asia/Shanghai" >> $ks_path$c1/$c3
echo "bootloader --location=mbr --driveorder=vda" >> $ks_path$c1/$c3

echo "clearpart --all --initlabel --drives=vda" >> $ks_path$c1/$c3
echo "zerombr" >> $ks_path$c1/$c3

echo "part /boot --fstype=ext4 --size=512" >> $ks_path$c1/$c3
echo "part pv.vhost --grow --size=1" >> $ks_path$c1/$c3
echo "volgroup vg0 --pesize=4096 pv.vhost" >> $ks_path$c1/$c3
echo "logvol swap --name=lv_swap --vgname=vg0  --size=4096 --maxsize=4096" >> $ks_path$c1/$c3
echo "logvol / --fstype=ext4 --name=lv_root --vgname=vg0 --grow --size=1" >> $ks_path$c1/$c3
#if [ $c6 -eq "50" ];then
#echo "logvol /data --fstype=ext4 --name=lv_data --vgname=vg0 --size=20480 --maxsize=20480" >> $ks_path$c1/$c3
#echo "logvol / --fstype=ext4 --name=lv_root --vgname=vg0 --grow --size=1" >> $ks_path$c1/$c3
#else
#echo "logvol / --fstype=ext4 --name=lv_root --vgname=vg0 --size=20480 --maxsize=20480" >> $ks_path$c1/$c3
#echo "logvol /data --fstype=ext4 --name=lv_data --vgname=vg0  --grow --size=1" >> $ks_path$c1/$c3
#fi

echo "reboot" >> $ks_path$c1/$c3

echo "%packages --nobase" >> $ks_path$c1/$c3
echo "@core" >> $ks_path$c1/$c3
echo "%post" >> $ks_path$c1/$c3
echo "mkdir /etc/yum.repos.d/bak" >> $ks_path$c1/$c3
echo "mv /etc/yum.repos.d/*repo /etc/yum.repos.d/bak/" >> $ks_path$c1/$c3
echo "cat > /etc/yum.repos.d/Centos-ISO.repo <<EOF" >> $ks_path$c1/$c3
echo "[ISO]" >> $ks_path$c1/$c3
echo "name=ISO" >> $ks_path$c1/$c3
echo "baseurl=http://mirrors.zju.edu.cn/centos/6/os/x86_64/" >> $ks_path$c1/$c3
echo "enable=1" >> $ks_path$c1/$c3
echo "gpgcheck=0" >> $ks_path$c1/$c3
echo "EOF" >> $ks_path$c1/$c3

echo "yum clean all" >> $ks_path$c1/$c3
echo "yum makecache" >> $ks_path$c1/$c3
echo "yum --exclude=kernel* update -y" >> $ks_path$c1/$c3
echo "yum -y install wget nrpe  python-psutil nfs-utils rpcbind ntpdate openssh-clients"  >> $ks_path$c1/$c3
echo "wget http://172.23.11.51/net_config/epel.repo">> $ks_path$c1/$c3
echo "mkdir -p /usr/local/admin" >> $ks_path$c1/$c3
echo "cd /opt/" >> $ks_path$c1/$c3
echo "wget http://172.23.11.51/net_config/biaozhunhua-6.sh ">> $ks_path$c1/$c3
echo "chmod u+x biaozhunhua-6.sh">> $ks_path$c1/$c3
echo "./biaozhunhua-6.sh">> $ks_path$c1/$c3
echo "service rpcbind start">> $ks_path$c1/$c3
echo "service nfs start">> $ks_path$c1/$c3
echo "chkconfig nfs on ">> $ks_path$c1/$c3
echo "chkconfig rpcbind  on">> $ks_path$c1/$c3

echo "cat >> /etc/ssh/sshd_config <<EOC" >> $ks_path$c1/$c3
echo "UseDNS no">>$ks_path$c1/$c3
echo "EOC" >>$ks_path$c1/$c3

echo "cat > /var/spool/cron/root <<EOC" >>$ks_path$c1/$c3
echo "*/5 * * * * /usr/sbin/ntpdate -u 172.23.242.21  && hwclock --systohc"  >>$ks_path$c1/$c3
echo "0 1 15 * * /usr/bin/yum --exclude=kernel* update -y"  >>$ks_path$c1/$c3
echo "EOC" >>$ks_path$c1/$c3
echo "chmod 600 /var/spool/cron/root" >>$ks_path$c1/$c3
echo "service crond restart" >>$ks_path$c1/$c3
echo "/usr/sbin/ntpdate -u 172.23.242.21 && hwclock --systohc" >>$ks_path$c1/$c3
echo "init 6" >>$ks_path$c1/$c3


# finished to create the ks file auto !
script_name=$ks_path$c1"/"$c1"_install.sh"
if [ ! -f $script_name ]; then  
echo "yum  install kvm python-virtinst libvirt tunctl bridge-utils virt-manager qemu-kvm-tools virt-viewer virt-v2v -y" > $script_name
echo "/etc/init.d/libvirtd restart" >> $script_name
echo "chkconfig libvirtd on" >> $script_name
echo "vgcreate vg0 /dev/sdb" >> $script_name
fi

echo "                             " >> $script_name
echo "lvcreate -L "$c6"G -n "$c3" "$c12  >>  $script_name
echo "virt-install -n "$c3" -r "$c5" --vcpus="$c4" --arch=x86_64 --os-type=linux  -l http://172.23.11.51/os/"$c7"/ --nographics --disk=/dev/"$c12"/"$c3",bus=virtio --bridge="$c13",model=virtio --accelerate --extra-args='console=tty0 console=ttyS0,115200n8 ks=http://172.23.11.51/ks/BASIC/"$c1"/"$c3" --connect qemu:///system'" >> $script_name
echo "                             " >> $script_name

done

cat kscfg | while read c1 c2 c3 c4 c5 c6 c7 c8 c9 c10 c11 c12 c13 c14 c15
do
# virshautostart
script_name=$ks_path$c1"/"$c1"_install.sh"
echo "virsh autostart "$c3 >> $script_name
done

