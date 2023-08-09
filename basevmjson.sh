#!/usr/bin/bash

export VMBUILD_WORKDIR=$(cd $(dirname $0) && pwd)
export VERSION=1.0.2

cli_help() {
    cli_name=${0##*/}
    echo "
$cli_name
Version: $VERSION
Usage: ./$cli_name [command]

Commands:
  -name         Give VM name                                            (default = BaseVM)
  -ostype       refer vbox ostypes                                      (default = SUSE_LE_64)
  -memory       memory size (integer)                                   (default = 2048)
  -cpus         number of cpus (integer)                                (default = 1)
  -nic1         type of networks - refer vbox - default hostonly
  -nic2         type of networks - refer vbox - default hostonly
  -nic3         type of networks - refer vbox - default hostonly
  -nic4         type of networks - refer vbox - default hostonly
  -hdsize       size of vhd (integer)                                   (default = 18000)
  -netname      net@nicno=networkname | ex: natnetwork@1=NatNetwork
  -iso          path to iso file
  -ip           Give IP address                                         (default is random)
  -hostname     Give Host name                                          (default = BaseVM)
  -help         Help

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

cli_help_iso() {
    echo "
! Specify path to iso please and do not start with -
Command: -iso
Usage: 
  -iso string"
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

cli_help_netnameN() {
    echo "
! Specify network type and Network name and please do not start with !
Command: -netnameN
Usage: 
  -netnameN netType=networkname | ex: nat-network1=NatNetwork | ex: bridge-adapter1=Intel(R) Wi-Fi 6 AX201 160MHz"
    exit 2
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
    -iso)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_iso
        [[ "${!j}" == -* ]] && cli_help_iso
        export VM_BUILD_iso=${!j}
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
    -ip)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_ip
        [[ "${!j}" == -* ]] && cli_help_ip
        export VM_BUILD_ip=${!j}
        ;;
    -hostname)
        j=$((i + 1))
        [ ! -n "${!j}" ] && cli_help_hostname
        [[ "${!j}" == -* ]] && cli_help_hostname
        export VM_BUILD_hostname=${!j}
        ;;
    -help)
        cli_help
        ;;
    esac
done

iso=$(jq '.init_params.iso' <config.json | tr -d '"')

if [ ! -n "$VM_BUILD_vm_name" ]; then
    export VM_BUILD_vm_name="BaseVM"
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

if [ ! -n "$VM_BUILD_ip" ]; then
    export VM_BUILD_ip="192.168.224.$(echo $((60 + RANDOM % 61)))"
fi

if [ ! -n "$VM_BUILD_hostname" ]; then
    export VM_BUILD_hostname="BaseVM"
fi

if [ ! -n "$VM_BUILD_iso" ]; then
    export VM_BUILD_iso=$iso
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

new_json=$(
    jq -n --arg vm_name "$VM_BUILD_vm_name" \
        --arg os_type "$VM_BUILD_ostype" \
        --arg memory "$VM_BUILD_memory" \
        --arg cpu "$VM_BUILD_cpus" \
        --arg hdsize "$VM_BUILD_hdsize" \
        --arg iso "$VM_BUILD_iso" \
        --argjson nic1 "$nic1_data" \
        --argjson nic2 "$nic2_data" \
        --argjson nic3 "$nic3_data" \
        --argjson nic4 "$nic4_data" \
        --argjson network "$network" \
        '$ARGS.named'
)

#creating the required folder
mkdir vms
mkdir vms/$VM_BUILD_vm_name

echo "$new_json" > vms/$VM_BUILD_vm_name/basevm_parameters.json


#coping the Https certificate to the base vm folder
cp openssl/ca.pem vms/$VM_BUILD_vm_name/ca.pem

#calling the required script 
source post-script-base.sh vms/$VM_BUILD_vm_name/basevm_parameters.json
python basevm.py $VM_BUILD_vm_name

