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
| Group: ldapg     | on Linux   | uid 555 |
| User: ldap01     | on Windows | uid 139 |
| User: ldap02     | on Windows | uid 140 |
| User: ldapg      | on Windows | uid 555 |


## 注意

* Linux users と Windows AD users 自動で sync しません。マニュアルで user と group を map させます
* Linux と Windows で認証方法は異なります。下記を参照ください。

        |     Protocol          |     Security style          |     Name-mapping direction          |     Permissions applied          |
        |-|-|-|-|
        |  SMB  |  `Unix`  |  Windows to UNIX  |  UNIX (mode bits or NFSv4.x ACLs)  |
        |  SMB  |  `Ntfs`  |  Windows to UNIX  |  NTFS ACLs (based on Windows SID accessing share)  |
        |  NFSv3  |  `Unix`  |  None  |  UNIX (mode bits or NFSv4.x ACLs) <br><br>  NFSv4.x ACLs can be applied using an NFSv4.x administrative client and honored by NFSv3 clients.  |
        |  NFS  |  `Ntfs`  |  UNIX to Windows  |  NTFS ACLs (based on mapped Windows user SID)  |

* [NFSv3 and SMB] と [NFSv4.1 and SMB] ともにサポートしていますが、ここでは [NFSv3 and SMB] を使用します

## 手順

