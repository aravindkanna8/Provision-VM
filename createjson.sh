#!/usr/bin/bash

export VMBUILD_WORKDIR=$(cd $(dirname $0) && pwd)
export VERSION=1.0.2

cli_help() {
    cli_name=${0##*/}
    echo "
$cli_name
Version: $VERSION
Usage: ./$cli_name [command]

Note: 'Please provide the base_tree and replicaIP if you want existing mode and dont give treename'

Commands:
  -name             Give VM name                                                (default is random generation)
  -ostype           refer vbox ostypes                                          (default = SUSE_LE_64)
  -memory           memory size (integer)                                       (default = 2048)
  -cpus             number of cpus (integer)                                    (default = 1)
  -nic1             type of networks - refer vbox - default hostonly
  -nic2             type of networks - refer vbox - default hostonly
  -nic3             type of networks - refer vbox - default hostonly
  -nic4             type of networks - refer vbox - default hostonly
  -hdsize           size of vhd (integer)                                       (default = 18000)
  -netname          net@nicno=networkname | ex: natnetwork@1=NatNetwork
  -ip               Give IP address                                             (default is random generation)
  -hostname         Give Host name                                              (default = vm name)
  -mode             mode of edirectory configuration ["new","existing"]             (default = new)
  -treename         name of new edirectory tree (for mode=new)                  (default = vm name)
  -server_context   Give e-directory server context                             (default ou=blr,ou=in,o=mf)
  -base_tree        Give the Base tree name (for mode=existing) 
  -replicaIP        Provide the e-directory Base tree Ip (for mode=existing)
  -cluster          configure the setup as a cluster [True,false]               (default = false)
  -cluster_mode     mode of cluster (new or existing)                           (default new)
  -cluster_name     Name for the cluster, used to set cn and shared volume names(default = blr-cluster[random number])
  -cluster_ip       Ip address of the cluster                                   (default is random generation)
  -help             Help

exit error codes:
    exit 0 - no error
    exit 1 - infrastructure error
    exit 2 - netwrok setup error
"
    exit 0
}

function exit_process() {
    echo ${LINENO}
    exit $1
}

cli_help_name() {
    echo "
! Specify name please and do not start with -
Command: -name
Usage: 
  -name vm_name"
    exit_process 1
}

cli_help_ostype() {
    echo "
! Specify ostype please and do not start with -
Command: -ostype
Usage: 
  -ostype osname/type name"
    exit 1
}

cli_help_memory() {
    echo "
! Specify memory size please and do not start with -
Command: -memory
Usage: 
  -memory <integer>"
    exit 1
}

cli_help_cpus() {
    echo "
! Specify number of cpus please and do not start with -
Command: -cpus
Usage: 
  -cpus <integer>"
    exit 1
}

cli_help_nicn() {
    echo "
! Specify network card with number please and do not start with -
Command: -nicn
Usage: 
  -nicn typeOfNetwork"
    exit 2
}

cli_help_hdsize() {
    echo "
! Specify hardisk size please and do not start with -
Command: -hdsize
Usage: 
  -hdsize <integer>"
    exit 1
}

cli_help_mode() {
    echo "
! Specify mode of edirectory configuration ["new","existing"] and don not start with  -
Command: -mode
Usage: 
  -mode string"
    exit 1
}

cli_help_treename() {
    echo "
! Specify name of edirectory tree and do not start with  -
Command: -treename
Usage: 
  -treename string"
    exit 1
}

cli_help_ip() {
    echo "
! Specify IP address and do not start with  -
Command: -ip
Usage: 
  -ip string"
    exit 1
}

cli_help_hostname() {
    echo "
! Specify hostname and do not start with  -
Command: -hostname
Usage: 
  -hostname string"
    exit 1
}

cli_help_base_tree() {
    echo "
! Specify base tree name and do not start with  -
Command: -base_tree
Usage: 
  -base_tree string"
    exit 1
}

cli_help_replicaIP() {
    echo "
! Specify Tree Header replicaIP address and do not start with  -
Command: -replicaIP
Usage: 
  -replicaIP string"
    exit 1
}

cli_help_netnameN() {
    echo "
! Specify network type and Network name and please do not start with !
Command: -netnameN
Usage: 
  -netnameN netType=networkname | ex: nat-network1=NatNetwork | ex: bridge-adapter1=Intel(R) Wi-Fi 6 AX201 160MHz"
    exit 2
}

cli_help_server_context() {
    echo "
! Specify server edirectory context  -
Command: -server_context
Usage:
  -server_context ou=blr,ou=in,o=mf"
    exit 1
}

cli_help_cluster() {
    echo "
! Specify if cluster setup is required and do not start with  -
Command: -cluster
Usage:
  -cluster true"
    exit 1
}

cli_help_cluster_mode() {
    echo "
! Specify the cluster's mode [new or existing], only works if cluster is set true
Command: -cluster_mode
Usage:
  -cluster_ip new | existing"
    exit 1
}

cli_help_cluster_name() {
    echo "
! Specify the cluster name for shared volume, only works if cluster is set true
Command: -cluster_name
Usage:
  -cluster_name name"
    exit 1
}

cli_help_cluster_ip() {
    echo "
! Specify the cluster's ip, only works if cluster is set true
Command: -cluster_ip
Usage:
  -cluster_ip <ip address>"
    exit 1
}


for ((i = 1; i <= $#; i += 2)); do
    case "${!i}" in
    -name)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_name
        [[ "${!j}" == -* ]] && cli_help_name
        export VM_BUILD_vm_name=${!j}
        ;;
    -ostype)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_ostype
        [[ "${!j}" =~ ^-* ]] && cli_help_ostype
        export VM_BUILD_ostype=${!j}
        ;;
    -memory)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_memory
        [[ "${!j}" == -* ]] && cli_help_memory
        export VM_BUILD_memory=${!j}
        ;;
    -cpus)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_cpus
        [[ "${!j}" == -* ]] && cli_help_cpus
        export VM_BUILD_cpus=${!j}
        ;;
    -nic1)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_nicn
        [[ "${!j}" == -* ]] && cli_help_nicn
        export VM_BUILD_nic1=${!j}
        ;;
    -nic2)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_nicn
        [[ "${!j}" == -* ]] && cli_help_nicn
        export VM_BUILD_nic2=${!j}
        ;;
    -nic3)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_nicn
        [[ "${!j}" == -* ]] && cli_help_nicn
        export VM_BUILD_nic3=${!j}
        ;;
    -nic4)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_nicn
        [[ "${!j}" == -* ]] && cli_help_nicn
        export VM_BUILD_nic4=${!j}
        ;;
    -hdsize)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_hdsize
        [[ "${!j}" == -* ]] && cli_help_hdsize
        export VM_BUILD_hdsize=${!j}
        ;;
    -netname1)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_netnameN
        [[ "${!j}" == -* ]] && cli_help_netnameN
        IFS="="
        read -ra ADDR1 <<<"${!j}"
        echo ${ADDR1[!0]}
        export typeNet1=${ADDR1[!1]}
        export netName1=${ADDR1[!0]}
        echo ${ADDR1[!1]}
        ;;
    -netname2)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_netnameN
        [[ "${!j}" == -* ]] && cli_help_netnameN
        IFS="="
        read -ra ADDR1 <<<"${!j}"
        echo ${ADDR1[!0]}
        export typeNet2=${ADDR1[!1]}
        export netName2=${ADDR1[!0]}
        echo ${ADDR1[!1]}
        ;;
    -netname3)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_netnameN
        [[ "${!j}" == -* ]] && cli_help_netnameN
        IFS="="
        read -ra ADDR1 <<<"${!j}"
        echo ${ADDR1[!0]}
        export typeNet3=${ADDR1[!1]}
        export netName3=${ADDR1[!0]}
        echo ${ADDR1[!1]}
        ;;
    -netname4)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_netnameN
        [[ "${!j}" == -* ]] && cli_help_netnameN
        IFS="="
        read -ra ADDR1 <<<"${!j}"
        echo ${ADDR1[!0]}
        export typeNet4=${ADDR1[!1]}
        export netName4=${ADDR1[!0]}
        echo ${ADDR1[!1]}
        ;;
    -mode)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_mode
        [[ "${!j}" == -* ]] && cli_help_mode
        export VM_BUILD_mode=${!j}
        ;;
    -treename)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_treename
        [[ "${!j}" == -* ]] && cli_help_treename
        export VM_BUILD_treename=${!j}
        ;;
    -ip)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_ip
        [[ "${!j}" == -* ]] && cli_help_ip
        export VM_BUILD_ip=${!j}
        ;;
    -replicaIP)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_treeIP
        [[ "${!j}" == -* ]] && cli_help_treeIP
        export VM_BUILD_replicaIP=${!j}
        ;;
    -hostname)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_hostname
        [[ "${!j}" == -* ]] && cli_help_hostname
        export VM_BUILD_hostname=${!j}
        ;;
    -base_tree)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_base_tree
        [[ "${!j}" == -* ]] && cli_help_base_tree
        export VM_BUILD_base_tree=${!j}
        ;;
    -server_context)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_server_context
        [[ "${!j}" == -* ]] && cli_help_server_context
        export VM_BUILD_server_context=${!j}
        ;;
    -cluster)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_cluster
        [[ "${!j}" == -* ]] && cli_help_cluster
        export VM_BUILD_cluster=${!j}
        ;;
    -cluster_name)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_cluster_name
        [[ "${!j}" == -* ]] && cli_help_cluster_name
        export VM_BUILD_cluster_name=${!j}
        ;;
    -cluster_mode)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_cluster_mode
        [[ "${!j}" == -* ]] && cli_help_cluster_mode
        export VM_BUILD_cluster_mode=${!j}
        ;;
    -cluster_ip)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_cluster_ip
        [[ "${!j}" == -* ]] && cli_help_cluster_ip
        export VM_BUILD_cluster_ip=${!j}
        ;;
    -help)
        cli_help
        ;;
    esac
done

if [ ! -n "$VM_BUILD_vm_name" ]; then
    name="testVM$(echo $RANDOM | tr '[0-9]' '[a-z]')"
    export VM_BUILD_vm_name=$name
fi
if [ ! -n "$VM_BUILD_ostype" ]; then
    export VM_BUILD_ostype=SUSE_LE_64
fi
if [ ! -n "$VM_BUILD_memory" ]; then
    export VM_BUILD_memory=2048
fi
if [ ! -n "$VM_BUILD_cpus" ]; then
    export VM_BUILD_cpus=1
fi
if [ ! -n "$VM_BUILD_nic1" ] && [ ! -n "$VM_BUILD_nic2" ] && [ ! -n "$VM_BUILD_nic3" ] && [ ! -n "$VM_BUILD_nic4" ]; then
    export VM_BUILD_nic1=hostonly
    export typeNet1=host-only-adapter1
    export netName1="VirtualBox Host-Only Ethernet Adapter"
fi
if [ "$VM_BUILD_nic1" == "bridged" ] && [ ! -n "$typeNet1" ] && [ ! -n "$netName1" ]; then
    export typeNet1=bridge-adapter1
    export netName1="Intel(R) Wi-Fi 6 AX201 160MHz"
fi
if [ "$VM_BUILD_nic2" == "bridged" ] && [ ! -n "$typeNet2" ] && [ ! -n "$netName2" ]; then
    export typeNet2=bridge-adapter2
    export netName2="Intel(R) Wi-Fi 6 AX201 160MHz"
fi
if [ "$VM_BUILD_nic3" == "bridged" ] && [ ! -n "$typeNet3" ] && [ ! -n "$netName3" ]; then
    export typeNet3=bridge-adapter3
    export netName3="Intel(R) Wi-Fi 6 AX201 160MHz"
fi
if [ "$VM_BUILD_nic4" == "bridged" ] && [ ! -n "$typeNet4" ] && [ ! -n "$netName4" ]; then
    export typeNet4=bridge-adapter4
    export netName4="Intel(R) Wi-Fi 6 AX201 160MHz"
fi

if [ "$VM_BUILD_nic1" == "hostonly" ] && [ ! -n "$typeNet1" ] && [ ! -n "$netName1" ]; then
    export typeNet1=host-only-adapter1
    export netName1="VirtualBox Host-Only Ethernet Adapter"
fi
if [ "$VM_BUILD_nic2" == "hostonly" ] && [ ! -n "$typeNet2" ] && [ ! -n "$netName2" ]; then
    export typeNet2=host-only-adapter2
    export netName2="VirtualBox Host-Only Ethernet Adapter"
fi
if [ "$VM_BUILD_nic3" == "hostonly" ] && [ ! -n "$typeNet3" ] && [ ! -n "$netName3" ]; then
    export typeNet3=host-only-adapter3
    export netName3="VirtualBox Host-Only Ethernet Adapter"
fi
if [ "$VM_BUILD_nic4" == "hostonly" ] && [ ! -n "$typeNet4" ] && [ ! -n "$netName4" ]; then
    export typeNet4=host-only-adapter4
    export netName4="VirtualBox Host-Only Ethernet Adapter"
fi

if [ ! -n "$VM_BUILD_hdsize" ]; then
    export VM_BUILD_hdsize=18000
fi
if [ ! -n "$VM_BUILD_mode" ]; then
    export VM_BUILD_mode="new"
fi


if [ ! -n "$VM_BUILD_ip" ]; then
    export VM_BUILD_ip="192.168.224.$(echo $((60 + RANDOM % 61)))"
fi

if [ ! -n "$VM_BUILD_hostname" ]; then
    export VM_BUILD_hostname="${VM_BUILD_vm_name}"
fi

if [ ! -n "$VM_BUILD_cluster_mode" ]; then
    export VM_BUILD_cluster_mode="new"
fi

if [ ! -n "$VM_BUILD_treename" ]; then
    export VM_BUILD_treename=$VM_BUILD_vm_name
fi
if [[ $VM_BUILD_mode == "existing" ]]; then
    if [ ! -n "$VM_BUILD_base_tree" ]; then
        echo "error : needs to provide the base tree name"
        exit 2 
    fi
    if [ ! -n "$VM_BUILD_replicaIP" ]; then
        echo "error : needs to provide the base tree ip within replicaIP"
        exit 2
    fi
fi

if [ ! -n "$VM_BUILD_server_context" ]; then
    export VM_BUILD_server_context="ou=blr,ou=in,o=mf"
fi

if [[ $VM_BUILD_cluster_mode == "existing" ]]; then
    if [ ! -n "$VM_BUILD_cluster_name" ]; then
        echo "error : needs to provide the cluster name"
        exit 2
    fi
    if [ ! -n "$VM_BUILD_cluster_ip" ]; then
        echo "error : needs to provide the cluster_ip"
        exit 2
    fi
fi

if [ ! -n "$VM_BUILD_cluster_name" ]; then
    export VM_BUILD_cluster_name="blr-cluster$(echo "$((RANDOM % 100))")"
fi

if [ ! -n "$VM_BUILD_cluster" ]; then
    export VM_BUILD_cluster=False
fi

if [ ! -n "$VM_BUILD_cluster_ip" ]; then
    export VM_BUILD_cluster_ip="192.168.56.$(echo $((60 + RANDOM % 61)))"
fi



nic1_data=$(
    jq -n --arg nic "$VM_BUILD_nic1" \
        --arg typenet1 "$typeNet1" \
        --arg netName1 "$netName1" \
        '$ARGS.named'
)
nic2_data=$(
    jq -n --arg nic "$VM_BUILD_nic2" \
        --arg typenet2 "$typeNet2" \
        --arg netName2 "$netName2" \
        '$ARGS.named'
)
nic3_data=$(
    jq -n --arg nic "$VM_BUILD_nic3" \
        --arg typenet3 "$typeNet3" \
        --arg netName3 "$netName3" \
        '$ARGS.named'
)
nic4_data=$(
    jq -n --arg nic "$VM_BUILD_nic4" \
        --arg typenet4 "$typeNet4" \
        --arg netName4 "$netName4" \
        '$ARGS.named'
)

network=$(
    jq -n --arg ip "$VM_BUILD_ip" \
        --arg hostname "$VM_BUILD_hostname" \
        '$ARGS.named'
)

edirectory=$(
    jq -n --arg mode "$VM_BUILD_mode" \
        --arg treename "$VM_BUILD_treename" \
        --arg server_context "$VM_BUILD_server_context" \
        --arg replicaIP "$VM_BUILD_replicaIP" \
        --arg base_tree "$VM_BUILD_base_tree" \
        '$ARGS.named'
)

cluster=$(
    jq -n --arg cluster "$VM_BUILD_cluster" \
        --arg cluster_name "$VM_BUILD_cluster_name" \
        --arg cluster_ip "$VM_BUILD_cluster_ip" \
        --arg cluster_mode "$VM_BUILD_cluster_mode" \
        --arg cluster_context "cn=${VM_BUILD_cluster_name},${VM_BUILD_server_context}" \
        '$ARGS.named'
)

new_json=$(
    jq -n --arg vm_name "$VM_BUILD_vm_name" \
        --arg os_type "$VM_BUILD_ostype" \
        --arg memory "$VM_BUILD_memory" \
        --arg cpu "$VM_BUILD_cpus" \
        --arg hdsize "$VM_BUILD_hdsize" \
        --argjson nic1 "$nic1_data" \
        --argjson nic2 "$nic2_data" \
        --argjson nic3 "$nic3_data" \
        --argjson nic4 "$nic4_data" \
        --argjson edirectory "$edirectory" \
        --argjson network "$network" \
        --argjson cluster "$cluster" \
        '$ARGS.named'
)

# echo "$new_json" > parameters.json
new_macro=$(jq '.cluster.ncs_macro_new' <config.json | tr -d '"')
existing_macro=$(jq '.cluster.ncs_macro_existing' <config.json | tr -d '"')

mkdir vms/$VM_BUILD_vm_name
echo "$new_json" > vms/$VM_BUILD_vm_name/$VM_BUILD_vm_name.json
echo "IP Associated to this vm is $VM_BUILD_ip"

#calling the required files
source user.sh $VM_BUILD_vm_name
source host-ssh.sh vms/$VM_BUILD_vm_name/$VM_BUILD_vm_name.json
source post_script.sh vms/$VM_BUILD_vm_name/$VM_BUILD_vm_name.json



if [[ $VM_BUILD_mode == "new" ]]; then
        python new_tree.py $VM_BUILD_vm_name
    else
        python existing_tree.py $VM_BUILD_vm_name
fi

if [[ $VM_BUILD_cluster == "True" ]]; then
    if [[ $VM_BUILD_cluster_mode == "new" ]]; then
        cp $new_macro vms/$VM_BUILD_vm_name/
        sed -i "s/<password>/Replace this text with the real password/g" vms/$VM_BUILD_vm_name/newclustermacro.ycp
        sed -i "s/<machineip>/${VM_BUILD_ip}/g" vms/$VM_BUILD_vm_name/newclustermacro.ycp
        sed -i "s/<clustermasterip>/${VM_BUILD_cluster_ip}/g" vms/$VM_BUILD_vm_name/newclustermacro.ycp
        sed -i "s/<clusterdn>/cn=${VM_BUILD_cluster_name},${VM_BUILD_server_context}/g" vms/$VM_BUILD_vm_name/newclustermacro.ycp
        sed -i "s/<clustershareddisk>/sdb/g" vms/$VM_BUILD_vm_name/newclustermacro.ycp
        sed -i "s/<clustershareddisk2>/sdc/g" vms/$VM_BUILD_vm_name/newclustermacro.ycp
    else
        cp $existing_macro vms/$VM_BUILD_vm_name/
        sed -i "s/<password>/Replace this text with the real password/g" vms/$VM_BUILD_vm_name/existingclustermacro.ycp
        sed -i "s/<machineip>/${VM_BUILD_ip}/g" vms/$VM_BUILD_vm_name/existingclustermacro.ycp
        sed -i "s/<clusterdn>/cn=${VM_BUILD_cluster_name},${VM_BUILD_server_context}/g" vms/$VM_BUILD_vm_name/existingclustermacro.ycp
    fi
fi

source ssh.sh vms/$VM_BUILD_vm_name/$VM_BUILD_vm_name.json

