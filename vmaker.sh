#!/bin/bash

# make template work path
if [ ! -d /tmp/vm_maker_path ]
then
    mkdir /tmp/vm_maker_path
fi
work_path=/tmp/vm_maker_path
vm_creater=$work_path"/install.sh"
cmdb_insert=$work_path"cmdb_insert.sh"
rm -r $cmdb_insert

line_numb = 0   # 记录行号

cat kscfg | while read c_server c_sip c_vname c_cpu c_memory c_disk c_version c_ip c_mask c_gateway c_psword c_raid c_netsegment c_caseid c_done
do
    rm -f $work_path/c_vname
    rm -f $vm_creater
    line_numb=`expr $line_numb + 1`
    echo $line_numb
    if [ $c_done -a $c_done = done ]
    then
        continue
    fi
    if [ ${c_version:0:7} = centos5 ]
    then
        ./basic_centos6.sh $work_path $c_server $c_sip $c_vname $c_cpu $c_memory $c_disk $c_version $c_ip $c_mask $c_gateway $c_psword $c_raid $c_netsegment $c_caseid
    fi
    if [ ${c_version:0:7} = centos7 ]
    then
        ./basic_centos7.sh $work_path $c_server $c_sip $c_vname $c_cpu $c_memory $c_disk $c_version $c_ip $c_mask $c_gateway $c_psword $c_raid $c_netsegment $c_caseid
    fi
    # 开始执行创建
    # ssh root@$c_sip << $vm_creater
    ssh zhr@192.168.5.213 < /tmp/test.sh
    if [ $? -ne 0 ]
    then
        echo Some error occurred when creating vm "$c_vname"
        return 1
    fi
    # 将最后一个单词从todo变为done
    sed -i "${line_numb}s/todo$/done/" kscfg
    # 生成归档cmdb的curl语句
done
