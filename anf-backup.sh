#!/bin/bash

# 1st vnet
az network vnet create -g anfbackup-rg -n anfbackup-vnet \
    --address-prefix 172.29.64.0/22 \
    --subnet-name default-sub \
    -l japaneast \
    --subnet-prefix 172.29.65.0/24

az network vnet subnet create \
    --resource-group anfbackup-rg \
    --vnet-name anfbackup-vnet \
    --name anf-sub \
    --delegations "Microsoft.NetApp/volumes" \
    --address-prefixes 172.29.64.0/26

# 2nd vnet
az network vnet create -g anfbackup-rg -n anfbackup2-vnet \
    --address-prefix 192.168.64.0/22 \
    --subnet-name default2-sub \
    -l japaneast \
    --subnet-prefix 192.168.65.0/24

az network vnet subnet create \
    --resource-group anfbackup-rg \
    --vnet-name anfbackup2-vnet \
    --name anf2-sub \
    --delegations "Microsoft.NetApp/volumes" \
    --address-prefixes 192.168.64.0/26

# 1st account
az netappfiles account create \
    -g anfbackup-rg \
    --name account1 -l japaneast

az netappfiles pool create \
    --resource-group anfbackup-rg \
    --location japaneast \
    --account-name account1 \
    --pool-name pool1 \
    --size 4 \
    --service-level Standard

# az netappfiles volume create \
#     --resource-group anfbackup-rg \
#     --location japaneast \
#     --account-name account1 \
#     --pool-name pool1 \
#     --name volume1 \
#     --service-level Standard \
#     --vnet anfbackup-vnet \
#     --subnet anf-sub \
#     --allowed-clients 0.0.0.0/0 \
#     --rule-index 1 \
#     --usage-threshold 100 \
#     --file-path nfsvolume1 \
#     --protocol-types NFSv3

# 2nd account, pool only
az netappfiles account create \
    -g anfbackup-rg \
    --name account2 -l japaneast

az netappfiles pool create \
    --resource-group anfbackup-rg \
    --location japaneast \
    --account-name account1 \
    --pool-name pool2 \
    --size 4 \
    --service-level Standard
