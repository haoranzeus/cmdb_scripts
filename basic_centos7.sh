#!/bin/bash
if [ ! -d /var/www/html/ks/BASIC ]
then
    mkdir /var/www/html/ks/BASIC
fi
ks_path="/var/www/html/ks/BASIC/"

work_path=$1
c1=$2           # 物理机
c2=$3           # 物理机ip
c3=$4           # 虚拟机hostname
c4=$5           # cpu
c5=$6           # 内存(M)
c6=$7           # 系统磁盘空间(G)
c7=$8           # 系统版本
c8=$9           # ip地址
c9=${10}           # 掩码
c10=${11}       # 网关
c11=${12}       # 密码
c12=${13}       # 所属raid
c13=${14}       # 所属网段
c14=${15}       # 实例id

# TODO (delete)
echo $work_path
echo $c1 $c2 $c3 $c4 $c5 $c6 $c7 $c8 $c9 $c10 $c11 $c12 $c13 $c14

# TODO (delete end)

echo "install" > $work_path/$c3
echo "auth --enableshadow --enablemd5" >> $work_path/$c3
echo "url --url http://172.23.11.51/os/"$c7"/" >> $work_path/$c3
echo "firstboot --disable" >> $work_path/$c3
echo "firewall --disable" >> $work_path/$c3
echo "selinux --disable" >> $work_path/$c3
echo "ignoredisk --only-use=vda" >> $work_path/$c3

echo "keyboard --vckeymap=us --xlayouts='us'" >> $work_path/$c3
echo "lang en_US.UTF-8" >> $work_path/$c3

echo "network --bootproto=static --device=eth0 --gateway="$c10" --ip="$c8" --netmask="$c9"  --nameserver=172.23.11.231 --hostname="$c3" --activate " >> $work_path/$c3

echo "rootpw "$c11 >> $work_path/$c3
echo "timezone Asia/Shanghai --isUtc --nontp" >> $work_path/$c3

echo "bootloader --location=mbr --boot-drive=vda" >> $work_path/$c3
echo "clearpart --none --initlabel " >> $work_path/$c3
echo "zerombr" >>$work_path/$c3

echo "part /boot --fstype=xfs --size=500" >> $work_path/$c3
echo "part pv.vhost --grow --size=1" >> $work_path/$c3
echo "volgroup vg0 --pesize=4096 pv.vhost" >> $work_path/$c3
echo "logvol swap --name=lv_swap --vgname=vg0  --size=4096 --maxsize=4096" >> $work_path/$c3
echo "logvol / --fstype=xfs --name=lv_root --vgname=vg0 --grow --size=1" >> $work_path/$c3

echo "reboot" >> $work_path/$c3

echo "%packages --nobase" >> $work_path/$c3
echo "@core" >> $work_path/$c3
echo "%end" >> $work_path/$c3

echo "%post" >> $work_path/$c3
echo "cat > /etc/resolv.conf <<EOL" >> $work_path/$c3
echo "nameserver 172.23.11.231" >> $work_path/$c3
echo "EOL" >> $work_path/$c3

echo "cat >>  /etc/ssh/sshd_config <<EOC" >> $work_path/$c3
echo "UseDNS no" >> $work_path/$c3
echo "EOC" >> $work_path/$c3

echo "cd /etc/yum.repos.d/" >> $work_path/$c3
echo "cat > /etc/yum.repos.d/Centos-ISO.repo <<EOF" >> $work_path/$c3
echo "[ISO]" >> $work_path/$c3
echo "name=ISO" >> $work_path/$c3
echo "baseurl=http://mirrors.zju.edu.cn/centos/7/os/x86_64/" >> $work_path/$c3
echo "enable=1" >> $work_path/$c3
echo "gpgcheck=0" >> $work_path/$c3
echo "EOF" >> $work_path/$c3

echo "yum clean all && yum makecache && yum update -y" >> $work_path/$c3
echo "yum -y install nrpe wget python-psutil nfs-utils rpcbind ntpdate ntp openssh-clients net-tools.x86_64"  >> $work_path/$c3
echo "wget http://172.23.11.51/net_config/epel7.repo ">> $work_path/$c3
echo "cd /opt/" >> $work_path/$c3
echo "wget http://172.23.11.51/net_config/biaozhunhua-7.sh ">> $work_path/$c3
echo "chmod u+x biaozhunhua-7.sh">> $work_path/$c3
echo "./biaozhunhua-7.sh">> $work_path/$c3

echo "service rpcbind start">> $work_path/$c3
echo "service nfs start">> $work_path/$c3
echo "chkconfig nfs on ">> $work_path/$c3
echo "chkconfig rpcbind  on">> $work_path/$c3

echo "cat > /var/spool/cron/root <<EOC" >>$work_path/$c3
echo "*/5 * * * * /usr/sbin/ntpdate -u 172.23.242.21  && hwclock --systohc"  >>$work_path/$c3
echo "0 1 15 * * /usr/bin/yum update -y"  >>$work_path/$c3
echo "EOC" >>$work_path/$c3
echo "chmod 600 /var/spool/cron/root" >>$work_path/$c3
echo "service crond restart" >>$work_path/$c3
echo "/usr/sbin/ntpdate -u 172.23.242.21 && hwclock --systohc" >>$work_path/$c3

echo "%end" >> $work_path/$c3

# finished to create the ks file auto !
script_name=$work_path"/install.sh"

# 这个初始化判断有没有别的办法?
if [ ! -f $script_name ]; then  
echo "yum  install kvm python-virtinst libvirt tunctl bridge-utils virt-manager qemu-kvm-tools virt-viewer virt-v2v -y" > $script_name
echo "/etc/init.d/libvirtd restart" >> $script_name
echo "chkconfig libvirtd on" >> $script_name
echo "vgcreate vg0 /dev/sdb" >> $script_name
fi

echo "                             " >> $script_name
echo "set -e" >> $script_name
echo "virsh destroy "$c3 >>  $script_name
echo "virsh undefine "$c3 >>  $script_name
echo "lvremove -f /dev/vg0/"$c3 >>  $script_name
echo "lvcreate -L "$c6"G -n "$c3" "$c12 >>  $script_name
#echo "virt-install -n "$c3" -r "$c5" --vcpus="$c4" --arch=x86_64 --os-type=linux  -l http://112.13.168.3:10086/os/centos7/ --nographics --disk=/dev/"$c12"/"$c3",bus=virtio --bridge="$c13",model=virtio --accelerate --extra-args='console=tty0 console=ttyS0,115200n8 ks=http://172.23.11.51/ks/BASIC/"$c1"/"$c3" --connect qemu:///system'" >> $script_name
echo "virt-install -n "$c3" -r "$c5" --vcpus="$c4" --arch=x86_64 --os-type=linux  -l http://172.23.11.51/os/centos7.3/ --nographics --disk=/dev/"$c12"/"$c3",bus=virtio --bridge="$c13",model=virtio --accelerate --extra-args='console=tty0 console=ttyS0,115200n8 ks="$work_path"/"$c3" --connect qemu:///system'" >> $script_name
echo "                             " >> $script_name

# done
