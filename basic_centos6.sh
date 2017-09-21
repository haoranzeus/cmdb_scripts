#!/bin/bash
if [ ! -d /var/www/html/ks/BASIC ]
then
    mkdir /var/www/html/ks/BASIC
fi
# ks_path="/var/www/html/ks/BASIC/"

work_path=$1
c1=$2           # 物理机
c2=$3           # 物理机ip
c3=$4           # 虚拟机hostname
c4=$5           # cpu
c5=$6           # 内存(M)
c6=$7           # 系统磁盘空间(G)
c7=$8           # 系统版本
c8=$9           # ip地址
c9=${10}        # 掩码
c10=${11}       # 网关
c11=${12}       # 密码
c12=${13}       # 所属raid
c13=${14}       # 所属网段
c14=${15}       # 实例id

echo "install" > $work_path/$c3
echo "key --skip" >> $work_path/$c3
echo "url --url http://172.23.11.51/os/"$c7"/" >> $work_path/$c3

echo "lang en_US.UTF-8" >> $work_path/$c3
echo "keyboard us" >> $work_path/$c3

echo "network --bootproto=static --device=eth0 --gateway="$c10" --ip="$c8" --nameserver=172.23.11.231 --netmask="$c9" --hostname="$c3" --onboot=on" >> $work_path/$c3

echo "rootpw "$c11 >> $work_path/$c3
echo "authconfig --enableshadow --enablemd5" >> $work_path/$c3

echo "firewall --disable" >> $work_path/$c3
echo "selinux --disable" >> $work_path/$c3
echo "timezone --utc Asia/Shanghai" >> $work_path/$c3
echo "bootloader --location=mbr --driveorder=vda" >> $work_path/$c3

echo "clearpart --all --initlabel --drives=vda" >> $work_path/$c3
echo "zerombr" >> $work_path/$c3

echo "part /boot --fstype=ext4 --size=512" >> $work_path/$c3
echo "part pv.vhost --grow --size=1" >> $work_path/$c3
echo "volgroup vg0 --pesize=4096 pv.vhost" >> $work_path/$c3
echo "logvol swap --name=lv_swap --vgname=vg0  --size=4096 --maxsize=4096" >> $work_path/$c3
echo "logvol / --fstype=ext4 --name=lv_root --vgname=vg0 --grow --size=1" >> $work_path/$c3
#if [ $c6 -eq "50" ];then
#echo "logvol /data --fstype=ext4 --name=lv_data --vgname=vg0 --size=20480 --maxsize=20480" >> $work_path/$c3
#echo "logvol / --fstype=ext4 --name=lv_root --vgname=vg0 --grow --size=1" >> $work_path/$c3
#else
#echo "logvol / --fstype=ext4 --name=lv_root --vgname=vg0 --size=20480 --maxsize=20480" >> $work_path/$c3
#echo "logvol /data --fstype=ext4 --name=lv_data --vgname=vg0  --grow --size=1" >> $work_path/$c3
#fi

echo "reboot" >> $work_path/$c3

echo "%packages --nobase" >> $work_path/$c3
echo "@core" >> $work_path/$c3
echo "%post" >> $work_path/$c3
echo "mkdir /etc/yum.repos.d/bak" >> $work_path/$c3
echo "mv /etc/yum.repos.d/*repo /etc/yum.repos.d/bak/" >> $work_path/$c3
echo "cat > /etc/yum.repos.d/Centos-ISO.repo <<EOF" >> $work_path/$c3
echo "[ISO]" >> $work_path/$c3
echo "name=ISO" >> $work_path/$c3
echo "baseurl=http://mirrors.zju.edu.cn/centos/6/os/x86_64/" >> $work_path/$c3
echo "enable=1" >> $work_path/$c3
echo "gpgcheck=0" >> $work_path/$c3
echo "EOF" >> $work_path/$c3

echo "yum clean all" >> $work_path/$c3
echo "yum makecache" >> $work_path/$c3
echo "yum --exclude=kernel* update -y" >> $work_path/$c3
echo "yum -y install wget nrpe  python-psutil nfs-utils rpcbind ntpdate openssh-clients"  >> $work_path/$c3
echo "wget http://172.23.11.51/net_config/epel.repo">> $work_path/$c3
echo "mkdir -p /usr/local/admin" >> $work_path/$c3
echo "cd /opt/" >> $work_path/$c3
echo "wget http://172.23.11.51/net_config/biaozhunhua-6.sh ">> $work_path/$c3
echo "chmod u+x biaozhunhua-6.sh">> $work_path/$c3
echo "./biaozhunhua-6.sh">> $work_path/$c3
echo "service rpcbind start">> $work_path/$c3
echo "service nfs start">> $work_path/$c3
echo "chkconfig nfs on ">> $work_path/$c3
echo "chkconfig rpcbind  on">> $work_path/$c3

echo "cat >> /etc/ssh/sshd_config <<EOC" >> $work_path/$c3
echo "UseDNS no">>$work_path/$c3
echo "EOC" >>$work_path/$c3

echo "cat > /var/spool/cron/root <<EOC" >>$work_path/$c3
echo "*/5 * * * * /usr/sbin/ntpdate -u 172.23.242.21  && hwclock --systohc"  >>$work_path/$c3
echo "0 1 15 * * /usr/bin/yum --exclude=kernel* update -y"  >>$work_path/$c3
echo "EOC" >>$work_path/$c3
echo "chmod 600 /var/spool/cron/root" >>$work_path/$c3
echo "service crond restart" >>$work_path/$c3
echo "/usr/sbin/ntpdate -u 172.23.242.21 && hwclock --systohc" >>$work_path/$c3
echo "init 6" >>$work_path/$c3


# finished to create the ks file auto !
script_name=$work_path"/install.sh"
if [ ! -f $script_name ]; then  
echo "yum  install kvm python-virtinst libvirt tunctl bridge-utils virt-manager qemu-kvm-tools virt-viewer virt-v2v -y" > $script_name
echo "/etc/init.d/libvirtd restart" >> $script_name
echo "chkconfig libvirtd on" >> $script_name
echo "vgcreate vg0 /dev/sdb" >> $script_name
fi

echo "                             " >> $script_name
echo "set -e" >> $script_name
echo "lvcreate -L "$c6"G -n "$c3" "$c12  >>  $script_name
echo "virt-install -n "$c3" -r "$c5" --vcpus="$c4" --arch=x86_64 --os-type=linux  -l http://172.23.11.51/os/"$c7"/ --nographics --disk=/dev/"$c12"/"$c3",bus=virtio --bridge="$c13",model=virtio --accelerate --extra-args='console=tty0 console=ttyS0,115200n8 ks=http://172.23.11.51/ks/BASIC/"$c1"/"$c3" --connect qemu:///system'" >> $script_name
echo "                             " >> $script_name

# virshautostart
script_name=$work_path"/install.sh"
echo "virsh autostart "$c3 >> $script_name
