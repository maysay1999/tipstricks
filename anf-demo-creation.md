---
title: Create ANF demo laboratory with Terraform
titleSuffix: ANF lab
description: It's a tool to create ANF demo lab quickly
author: Meisei Takemoto
ms.author: b-mtakemoto
ms.date: 02/28/2022
ms.topic: instruction
ms.service: azure-netapp-files
services: storage
---
# Azure NetApp Files 用の自分だけの laboratory を自動でつくる

Azure NetApp Files 用の自分だけの laboratory を自動でつくる

## 必要知識

* [Azure Cloud Shell](https://docs.microsoft.com/ja-jp/azure/cloud-shell/overview)の基本知識

## 事前準備

* [Azure subscription](https://portal.azure.com/)を事前に登録 USD200のフリーアカウントを新規登録したい場合は[こちら](https://azure.microsoft.com/en-us/free/)

## ダイアグラム

  ![diagram](https://github.com/maysay1999/tipstricks/blob/main/images/anf-lab_diagram.png)

## 注意

* *Creation of 'netAppAccounts' has been restricted in this region.* のエラーが起きた際は、[こちらのサイト](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/request-region-access)から登録が必要

## 手順

1. [Cloud Shell](https://docs.microsoft.com/ja-jp/azure/cloud-shell/overview) を開き、providerを登録し、必要なfeatureを追加する *CLIで実行*

   ```Bash
   az provider register --namespace Microsoft.NetApp
   az feature register --namespace Microsoft.NetApp --name ANFSharedAD
   az feature register --namespace Microsoft.NetApp --name ANFTierChange
   az feature register --namespace Microsoft.NetApp --name ANFUnixPermissions
   ```

2. anfdemolab-rg という名でresouce group を東日本に作成 *CLIで実行*

   ```Bash
   az group create -n anfdemolab-rg -l japaneast
   ```

3. git clone で自動作成で使用するファイルをダウンロード *CLIで実行*

   ```git
   git clone https://github.com/maysay1999/tipstricks AnfLaboCreate
   ```

4. Direcotryを変える *CLIで実行*

   ```Bash
   cd AnfLaboCreate/dcforest
   ```

5. main.tf を開く *CLIで実行*

   ```Bash
   code main.tf
   ```

6. 23行目の`admin_password`にあなたのパスワードをいれ、上書きし保存 (右上の ... )

   ![password](https://github.com/maysay1999/tipstricks/blob/main/images/anf-lab_pass.png)

7. `terraform init` と入力 *CLIで実行*

   ```hcl
   terraform init
   ```

8. `terraform apply` と入力 *CLIで実行*

   ```hcl
   terraform apply
   ```

9. "Do you want to perform these action? ..." Enter a value: と出てきたら `yes` と入力

   ```hcl
   yes
   ```

10. 20分ほど待てば完成
