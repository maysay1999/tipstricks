---
title: Create ANF demo laboratory with Terraform
titleSuffix: ANF lab
description: It's a tool to create ANF demo lab quickly
author: Meisei Takemoto
ms.author: b-mtakemoto
ms.date: 06/06/2022
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

## 1. [Cloud Shell](https://docs.microsoft.com/ja-jp/azure/cloud-shell/overview) を開き、providerを登録し、必要なfeatureを追加する *CLIで実行*

   ```Bash
   az provider register --namespace Microsoft.NetApp
   az feature register --namespace Microsoft.NetApp --name ANFSharedAD
   az feature register --namespace Microsoft.NetApp --name ANFTierChange
   az feature register --namespace Microsoft.NetApp --name ANFUnixPermissions
   ```

## 2. anfdemolab-rg という名でresouce group を東日本に作成 *CLIで実行*

   ```Bash
   az group create -n anfdemolab-rg -l japaneast
   ```

## 3. git clone で自動作成で使用するファイルをダウンロード *CLIで実行*

   ```git
   git clone https://github.com/maysay1999/tipstricks AnfLaboCreate
   ```

## 4. Directoryを変える *CLIで実行*

   ```Bash
   cd AnfLaboCreate/dcforest
   ```

## 5. main.tf を開く *CLIで実行*

   ```Bash
   code main.tf
   ```

## 6. 23行目の`admin_password`にあなたのパスワード(数字アルファベット混合 12文字以上)をいれ、上書きし保存 **ctl + s**, **ctl + q** (右上の **...** をクリックしても可)

   ![password](https://github.com/maysay1999/tipstricks/blob/main/images/anf-lab_pass.png)

## 7. `terraform init` と入力 *CLIで実行*

   ```hcl
   terraform init
   ```

## 8. `terraform apply` と入力 *CLIで実行*

   ```hcl
   terraform apply
   ```

## 9. "Do you want to perform these action? ..." Enter a value: と出てきたら `yes` と入力。  

   ```hcl
   yes
   ```

> **ノート**:  作成途中でエラーが発生した際は、再度 `terraform apply` を実行してください

## 10. 15分程度待てば完成

* 3つの VM (ubuntu, win10-client, windc01) が作成されているか確認  
    ![list of resources](https://github.com/maysay1999/tipstricks/blob/main/images/anf-lab_terraform_list.png)  

## 11. Windows 10 client を AD Domain `azureisfun.local` に参加させる

* 手順  
  1. win10-client の "概要" --> "接続" --> "Bastion" でログイン。ユーザー名: anfadmin、パスワード: 手順 6 で指定したもの  
  2. 右側にネットワーク検出許可がポップアップされれば、「はい」をクリック  
      ![Windows popup](https://github.com/maysay1999/anfdemo02/raw/main/images/anf-smb-network.png)  
  3. command prompt から`control sysdm.cpl`と入力し、System Properties を表示  
     ![sysdm.cpl](https://github.com/maysay1999/tipstricks/blob/main/images/anf-lab_sysdm.png)  
  4. "Change"をクリック  
     ![System properties](https://github.com/maysay1999/tipstricks/blob/main/images/anf-lab_join_domain-pre.png)  
  5. `azureisfun.local` ドメインに参加させ、reboot
     ![join domain](https://github.com/maysay1999/tipstricks/blob/main/images/anf-lab_join_domain.png)

## 次のステップ

* [Azure NetApp Files ハンズオン NFS 編 スタンダード](https://github.com/maysay1999/anfdemo02/blob/main/anf-hands-on_ubuntu.md)

* [Azure NetApp Files ハンズオン SMB 編](https://github.com/maysay1999/anfdemo02/blob/main/anf-hands-on_windows.md)

## 推奨コンテンツ

* [Azure NetApp Files のコスト モデル](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-cost-model)  
  サービスから経費を管理するための Azure NetApp Files のコスト モデルについて説明します  
* [Azure NetApp Files のストレージ階層](https://docs.microsoft.com/ja-jp/azure/azure-netapp-files/azure-netapp-files-understand-storage-hierarchy)  
  Azure NetApp Files のアカウント、容量プール、ボリュームを含むストレージ階層について説明します  
