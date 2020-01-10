#!/bin/bash

# ARGBASH_SET_INDENT([  ])
# DEFINE_SCRIPT_DIR()
# ARG_POSITIONAL_SINGLE([id], [Integer 0 - 255])
# ARG_DEFAULTS_POS
# ARG_HELP()
# ARG_TYPE_GROUP([int], [int], [id])
# ARGBASH_GO

# [ <-- needed because of Argbash
set -e

VM_BASE_PATH=/var/lib/libvirt/instances
VM_BACK_STORE=/var/lib/libvirt/boot/ubuntu-1804.img
VM_STORE_SIZE=8
VM_ID=$(uuidgen)
VM_NAME=vm$(printf %02d $_arg_id)
VM_MAC=$(echo '00 60 2f'$(od -An -N3 -t xC /dev/urandom) | sed -e 's/ /:/g')
VM_NET=host-bridge
VM_IP=192.168.0.${_arg_id}/24
VM_GATEWAY=192.168.0.1
VM_DNS=192.168.0.1
VM_DNS_SEARCH=jinchen.me
VM_PATH=${VM_BASE_PATH}/${VM_NAME}
SECTION_BREAK='################'
VIRSH=virsh

run() {
  echo "$*"
  eval "$*"
}

echo "Clean & Prepare ${SECTION_BREAK}"
run "$VIRSH destroy ${VM_NAME} &> /dev/null || true"
run "$VIRSH undefine ${VM_NAME} &> /dev/null || true"
run "rm -rf ${VM_PATH}"
run "mkdir -p ${VM_PATH}"
run "cd ${VM_PATH}"

echo -e "\nBuild meta-data ${SECTION_BREAK}"
tee meta-data <<EOT 
instance-id: ${VM_ID}
hostname: ${VM_NAME}
EOT

echo -e "\nBuild user-data ${SECTION_BREAK}"
tee user-data <<EOT
#cloud-config
hostname: ${VM_NAME}
users:
  - name: root
    lock_passwd: false
    ssh_pwauth: true
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDF3xPhlSB7zRnymi1WfdkMrSnpky8Xx0NcULlruNhD2V/OkACwi6ZIjUMbX0sqDteBsshzVv7yCHzlU9rQKrjxGUIBovjz6REcWfN5ZT4mhUyvSpR9QtRzBPqNTE64zTrwr/57SCBJfly7Ew24y0kPhjHTLcDejzRoeGAuOpmRUS3LS1IUvsndkHRdeytcZxe9e1KEMn+YTuea+WylBU0KRstFwlvrsfCgXhdG4ei3lCguO5Xfe6daP1hiPtc8ozia63avHIHCvF7NNAoThRoE2ftESNNZkd1AUpSKln87tK4iJCstpeWnLbORhgWnC/vMcXc2OS3TPdFW/N6yWosDcMESXvNmTSj4rIZKICwoG52qYudrO2Wrg/2TH/0cP/xpXQsVPSyUQnt9x86IR51dB4FmSvMn5jv+FvXTe10CAbaWOAf4ABhq3gtp75jUFKDvT7l0cJtwP5teJp74SqYm7/xaudkHe84/bUJbJbTzQktHFXM09N2ex74g/vVb60owAiLKK5yc+upLqnlySz+5DtIYvuio3QQRzL+loHFN2tLmHJumORJZmjfKqAx1lhiN7qmUt7/lk2jFi/2SGcGXX6TqnxtPKZNF6DwfKx5kMjuCAcUYyHV0xkfTrP3jucfnnjkAP9RUqBRziB3rW4iB7mbEcufglcLfG//uZI84MQ== id_rsa_starlight
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDBZQjPKoyVGC4Sj5r5Cpzclr2q/EYpL3fK6j1Qt0eVv0+qSE8tbnD8TnW/xtjl2N/z59kq9C9ys76YUAKma/MSp26Kwk1zA0Hki1bPVKeH69zrMra49LIyf25Kbaiou+ofBYEebyPob7c/RsPpVhI/nLtO3t3GUKUdNEKOH2eCKICIPtj3MOv1YnMTzW1ICgrU2EDlf6PYZ5caEGiTRV5xmPN3LKGDM6MnzZ7ZPiukkQrm46HJU38rQvSGAgXYYXybYtD9CcZgFzUpmdDQ42uQ8CsoX0Jw7nifCI05r/rOY1zgbmHC3rEYyG0Izw/2Z6ba2KqUXECmM3sgBjEgR3L9r1kdXlDwKDpiNAy8pMH6wowmrqpRRF+gSSlmPlP5+RfHl7Yuv0OB5bUh02xqDNL9AiCVc5jNX7BN3dIwL5gSKf9H7BV71L+2U0kqsRcInw+v950HigoJ9GRgJiQOAERd0RyDu4mrQsRGP2ALZcUE8QnbUMbNFsxeLjVotJq2mME8GXmKLQ3zAo3VCnfUXcl0MnD3wk1V7RR9JrRhvbwIZejFSKVuDCy5voKLuXriPcUcBFktZFLrRcHhqpnfoHWkkI/OLAle1MjBxUNUnKoPYjAtiQLWuRSGMRjfeUEbg3ONWS5Bb4Pu1lsyqzd7bVIpXOdanh2IJ1fdWEZf3umg4Q== id_rsa_jinchen_me
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0Y5qFSkDD2g7svOeSXxzggB95IwN7zpMTy9iiE6QAME2TxRV/mor65V/OY2+5CcrZmgqY6db3XFYDH9CRc1DCkZcLC6Il/g5xyqtK3pFs3hdcUSJ3wPoa5IgKUNRoWWLmKxzcP48pMKGVwddV48xReV2HWowQbBuIG9sMv/I2OdZiAVuoBO3pQqKTyZOnDQVpuZbRa1z0j8vtoWWSfzjjJmBpQeNB5DWfOGAQ7eSCoxZVEXdsKFwuZ/b8cFsvbW4BET9L0SM2CkZIkG/DjNGYVWdGcd3KfFWuGdrEEE9WRieRQQqakiXerTPssJ+lQ40LymPgs/J3fXiZXGIZ7fYJ root@mole-server
chpasswd:
  list: |
    root:mole
  expire: false
EOT

echo -e "\nBuild network-config-v2.yaml ${SECTION_BREAK}"
tee network-config-v2.yaml <<EOT
version: 2
ethernets:
  eth0:
    dhcp4: false
    match:
      macaddress: ${VM_MAC}
    set-name: eth0
    addresses: [${VM_IP}]
    gateway4: ${VM_GATEWAY}
    nameservers:
      search: [${VM_DNS_SEARCH}]
      addresses: [${VM_DNS}]
EOT

echo -e "\nBuild seed.iso ${SECTION_BREAK}"
run "cloud-localds -v --network-config network-config-v2.yaml seed.iso user-data meta-data"
echo $CMD

echo -e "\nRun command ${SECTION_BREAK}"
run virt-install \
    --name ${VM_NAME} \
    --memory 1024 \
    --vcpus 2 \
    --hvm \
    --os-type=linux \
    --os-variant=ubuntu18.04 \
    --disk ${VM_PATH}/${VM_NAME}.qcow2,device=disk,bus=virtio,size=${VM_STORE_SIZE},backing_store=${VM_BACK_STORE} \
    --disk ${VM_PATH}/seed.iso,device=cdrom \
    --network network=${VM_NET},mac=${VM_MAC} \
    --graphics none \
    --import \
    --noautoconsole
run "$VIRSH autostart ${VM_NAME}"
# ] <-- needed because of Argbash
