#!/bin/bash

# make template work path
if [ ! -d /tmp/vm_maker_path ]
then
    mkdir /tmp/vm_maker_path
fi
work_path=/tmp/vm_maker_path
vm_creater=$work_path"/install.sh"          # 用于生成虚拟机的脚本
cmdb_insert=cmdb_insert.sh                  # 用于归档cmdb的脚本
cmdb_url_path=http://192.168.5.249:10001    # 根据实际情况修改
cmdb_sync_str="curl -X POST -H \"Content-Type: application/json\" -d '{\"auth\": { },\"action\": { }}' "$cmdb_url_path"/custom/sync/"

line_numb=0   # 记录行号

cat kscfg | while read c_server c_sip c_vname c_cpu c_memory c_disk c_version c_ip c_mask c_gateway c_psword c_raid c_netsegment c_machine_area c_caseid c_done
do
    rm -f $work_path/c_vname                # 删除旧的生成虚拟机的中间配置文件
    rm -f $vm_creater                       # 删除旧的生成虚拟机的脚本

    # 如果第一个就是todo，说明是一次新的任务，可以将cmdb数据归档文件删除，从新生成
    if [ $line_numb -eq 0 -a $c_done = todo ]
    then
        rm -r $cmdb_insert
        echo $cmdb_sync_str >> $cmdb_insert
    fi

    line_numb=`expr $line_numb + 1`         # 跟踪配置文件的行号

    # 跳过c_done为"done"的行
    if [ $c_done -a $c_done = done ]
    then
        continue
    fi

    # centos6.x和centos7.x分别调用basic_centos6.sh和basic_centos7.sh
    if [ ${c_version:0:7} = centos6 ]
    then
        ./basic_centos6.sh $work_path $c_server $c_sip $c_vname $c_cpu $c_memory $c_disk $c_version $c_ip $c_mask $c_gateway $c_psword $c_raid $c_netsegment $c_caseid
    elif [ ${c_version:0:7} = centos7 ]
    then
        ./basic_centos7.sh $work_path $c_server $c_sip $c_vname $c_cpu $c_memory $c_disk $c_version $c_ip $c_mask $c_gateway $c_psword $c_raid $c_netsegment $c_caseid
    else
        echo ERROR! $c_version is not a valiable os version!
        return 2
    fi
    # 开始执行创建
    ssh root@$c_sip < $vm_creater
    # ssh zhr@192.168.5.213 < /tmp/test.sh
    if [ $? -ne 0 ]
    then
        echo Some error occurred when creating vm "$c_vname"
        return 1
    fi

    # 将最后一个单词从todo变为done
    sed -i "${line_numb}s/todo$/done/" kscfg

    # 生成归档cmdb的curl语句
    # 去掉同步中间结果集的语句
    sed -i "/\/custom\/sync\//d" $cmdb_insert

    # 添加资源
    echo curl -X POST -H \"Content-Type: application/json\" -d \'{\"auth\": { },\"action\": {\"ci_item\": {\"unique_keys\": {\"name\": \"$c_vname\"}, \
        \"properties\": {\"status\": 1, \"inner_ip\": \"$c_ip\", \"pwd\": \"c_psword\", \"cores\": $c_cpu, \"hdd\": $c_disk, \"ram\": $c_memory, \
        \"os\": \"$c_version\"}}, \"ci_relations\": [{\"tag_ci\": \"server\", \"tag_keys\": {\"name\": \"BASIC-SERVER-043\", \"machine_area\": \"红山-开发测试\"}}], \
        \"sync\": false}}\' $cmdb_url_path/api/cmdb/v0_1_0/vm/itemandrelation/add/ >> $cmdb_insert
    # 将资源与实例关联
    echo curl -X POST -H \"Content-Type: application/json\" -d \'{\"auth\": { },\"action\": {\"case_id\": $c_caseid, \"ci_items\": [\"ci_key\": \"vm\", \
        \"relation_type\": \"vm\", \"relation_name\": \"虚拟机\", \"auto_del\": 0, \"unique_keys\": {\"name\": \"$c_vname\"}]}}\' >> $cmdb_insert

    # 添加同步中间结果集的语句
    echo -e "\n" >> $cmdb_insert
    echo $cmdb_sync_str >> $cmdb_insert
done
