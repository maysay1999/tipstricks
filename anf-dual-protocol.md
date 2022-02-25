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

* ADDS または AADDS (Windows 2019 など) Windows client (Windows 10 など) Linux (Ubuntu など) を準備します。
* ANFのサブネットを作成し、Microsoft.NetApp/volumes に委任します
* ANF のaccount と pool を作成しておきます。

## ダイアグラム

