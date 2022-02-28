---
title: Instruction of a dual-protocol volume for Azure NetApp Files
titleSuffix: ANF Dual Protocol
description: In this article, you will learn how to create dual-protocol volumes of ANF
author: Meisei Takemoto
ms.author: b-mtakemoto
ms.date: 02/25/2022
ms.topic: instruction
ms.service: azure-netapp-files
services: storage
---
# Azure NetApp Files を使って dual-protocol volume をつくってみる

Azure NetApp Files では NFS (NFSv3 or NFSv4.1) または SMB3 または dual protocol (NFSv3 and SMB, or NFSv4.1 and SMB) がサポートされています。このサイトでは LDAP user mapping を使っての dual protocol 設定方法を順を追って説明します

## 事前準備

* ADDS または AADDS (Windows 2019 など) Windows client (Windows 10 など) Linux (Ubuntu など) を準備します
* ANFのサブネットを作成し、Microsoft.NetApp/volumes に委任します

## ダイアグラム

![diagram](https://github.com/maysay1999/tipstricks/blob/main/images/anf-dual_protocol_diagram.png)

| New user / group | Where      | ID      |
|------------------|------------|---------|
| User: ldap01     | on Linux   | uid 139 |
| User: ldap02     | on Linux   | uid 140 |
| Group: ldapg     | on Linux   | gid 555 |
| User: ldap01     | on Windows | uid 139 |
| User: ldap02     | on Windows | uid 140 |
| User: ldapg      | on Windows | gid 555 |

| Parameter            | Value          |
|----------------------|----------------|
| LOCATION             | japaneast   |
| RESOURCEGROUP        | anflab-rg   |
| ANF SUBNET           | testsubnet   |
| NETAPP ACCOUNT       | netapptestaccount  |
| NNETAPP POOL         | netapptestpool |
| NETAPP VOLUME        | netapptestvolume  |
| DOMAIN JOIN USERNAME | azureadmin |
| DOMAIN JOIN PASSWORD | null |
| SMB SERVER NAME      | pmcsmb |
| DNS LIST             | 10.0.0.4 |
| AD FQDN              | testdomain.local |

## 注意

* Linux users と Windows AD users 自動で sync しません。マニュアルで user と group を map させます
* Linux と Windows で認証方法は異なります。下記を参照ください。

|     Protocol          |     Security style          |     Name-mapping direction          |     Permissions applied          |
|-----------------------|-----------------------------|-------------------------------------|----------------------------------|
|  SMB  |  `Unix`  |  Windows to UNIX  |  UNIX (mode bits or NFSv4.x ACLs)  |
|  SMB  |  `Ntfs`  |  Windows to UNIX  |  NTFS ACLs (based on Windows SID accessing share)  |
|  NFSv3  |  `Unix`  |  None  |  UNIX (mode bits or NFSv4.x ACLs)  |
|  NFS  |  `Ntfs`  |  UNIX to Windows  |  NTFS ACLs (based on mapped Windows user SID)  |

* [NFSv3 and SMB] と [NFSv4.1 and SMB] ともにサポートしていますが、ここでは [NFSv3 and SMB] を使用します
* 同じ user を Windows (Active Directory) と Linux 両方に作る必要があります

## 手順

1. ANF アカウントを作成する

   ```Bash
   az netappfiles account create \
     -g anflab-rg \
     --name netapptestaccount -l japaneast
   ```

2. ANF pool を作成する

   ```Bash
   az netappfiles pool create \
    --resource-group anflab-rg \
    --location japaneast \
    --account-name netapptestaccount \
    --pool-name netapptestpool \
    --size 4 \
    --service-level Standard
   ```

3. DNS の設定を変更

   ```Bash
   az network vnet update -g MyResourceGroup \
     -n {vnet_name} --dns-servers 10.0.0.4
   ```

   > **Note**:  {vnet_name} は実際の環境の VNet名 に置き換え。10.0.0.4 は Primary Domain Controller

4. Reverse DNS を設定

   * ここでは Domain Controller を DNS として使用しているので、Windows にて設定

   ![reverser dns](https://github.com/maysay1999/tipstricks/blob/main/images/anf-dual-protocol_dns.png)

5. Active Directory User と Group を作成

   * Active Directory User `pcuser` と `ldap01` と `ldap02` を作成
   * Group `ldapg` を作成し、`ldap01` と `ldap02` を `ldapg` のメンバーとする

   ![add users](https://github.com/maysay1999/tipstricks/blob/main/images/anf-dual-protocol_ad_users.png)

6. LDAP POSIX Attribute の設定

   * グループ ldapg の attributes の設定:
    `objectClass: group, posixGroup`,  
    `gidNumber: 555`

    ![ldapg](https://github.com/maysay1999/tipstricks/blob/main/images/anf-dual-protocol_group.png)

   * ユーザー ldap01 の attributes の設定:
    `uid: idap01`,  
    `uidNumber: 139`,  
    `gidNumber: 555`,  
    `objectClass: user, posixAccount`

    ![ldap01](https://github.com/maysay1999/tipstricks/blob/main/images/anf-dual-protocol_ldap01.png)

   * ユーザー ldap02 の attributes の設定:
    `uid: idap02`,  
    `uidNumber: 140`,  
    `gidNumber: 555`,  
    `objectClass: user, posixAccount`

    ![ldap02](https://github.com/maysay1999/tipstricks/blob/main/images/anf-dual-protocol_ldap02.png)

   > **Note**:  uid gid は重複しないように `cat /etc/passwd` `cat /etc/group` で空きを確認します

7. Linux で group と users を作成 (6で作成したものと同じ gid, uid を 使う)

   * 新しいグループ `ldapg` を gid 555 で作成

   ```Bash
   group add -g 555 ldapg
    ```

   * 新しいユーザー `ldap01` を uid 139, group `ldapg` で作成し、パスワードを設定

   ```Bash
   useradd -u 139 ldap01 -g ldapg
   passwd ldap01
    ```

   * 新しいユーザー `ldap02` を uid 140, group `ldapg` で作成し、パスワードを設定

   ```Bash
   useradd -u 140 ldap02 -g ldapg
   passwd ldap02
    ```

8. Azure Portal にて Active Direcotry Connections の設定

   ![active directory](https://github.com/maysay1999/tipstricks/blob/main/images/anf-dual-protocol_ad_settings.png)

   * AZ CLI ならこちら

   ```Bash
   RESOURCEGROUP_NAME="ANFLabo-RG"
   NETAPP_ACCOUNT_NAME="netapptestaccount"
   DOMAIN_JOIN_USERNAME=azureadmin
   DOMAIN_JOIN_PASSWORD=null
   SMB_SERVER_NAME="pmcsmb"
   DNS_LIST="10.0.0.4"
   AD_FQDN="testdomain.local"

   az netappfiles account ad add --resource-group $RESOURCEGROUP_NAME \
     --name $NETAPP_ACCOUNT_NAME \
     --username $DOMAIN_JOIN_USERNAME \
     --password $DOMAIN_JOIN_PASSWORD \
     --smb-server-name $SMB_SERVER_NAME \
     --dns $DNS_LIST \
     --domain $AD_FQDN
   ```

9. ANF volume を作成 (**必ずGUIで** CLIだと上手くできないので、無難に)

* Dual Protocol を選ぶ。その他はdefault

   ![anf volume1](https://github.com/maysay1999/tipstricks/blob/main/images/anf-dual-protocol_volume1.png)

   ![anf volume2](https://github.com/maysay1999/tipstricks/blob/main/images/anf-dual-protocol_volume2.png)

10. Volume のdデプロイが完成したら、Mount instructions に従い mount

   ![mount](https://github.com/maysay1999/tipstricks/blob/main/images/anf-dual-protocol_mount.png)

11. 