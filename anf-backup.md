---
title: Instruction of Azure NetApp Files Backup
titleSuffix: ANF Backup
description: In this article, you will learn how to use ANF Backup
author: Meisei Takemoto
ms.author: b-mtakemoto
ms.date: 03/14/2022
ms.topic: instruction
ms.service: azure-netapp-files
services: storage
---

# Azure NetApp Files Backup を使いこなす

Azure NetApp Files Backup の使い方を解説します

## 事前準備

* anf-backup.sh を実行します

## ダイアグラム

![diagram](https://github.com/maysay1999/tipstricks/blob/main/images/anf_backup_diagram.png)

## 留意点

* バックアップは3つのタイプ  
  * 手動 スナップショットなしでバックアップ (お薦めしない)  
  * スナップショットを作成した後、バックアップ (推奨)  
  * スナップショットポリシーを作成した後、バックアップポリシーを作成し自動バックアップ (推奨)  

* バックアップがポータルで表示されるまで約5分かかる
* バックアップは同じリージョンに ZRS で保存される
* バックアップスケジュール を設定したい場合、スナップショットポリシーは必須
* 常にスナップショットからバックアップを作成することを推奨
* Baseline snapshot (一番最初に作成されるバックアップ。snapmirror....という名前が付けられる）を消してはいけない。自動で消される
* 毎時間にバックアップを作成することは不可能。毎日、毎週、毎月のみ
* CRRの場合、sourceのみでANF Backup は使用可能
* 不要なバックアップを削除する場合、古い順に削除する
* バックアップを作成できるのは最大5 ボリューム
* ボリュームを削除してもバックアップは残る
* 課金はバックアップの総容量できまる
* 手動で実行する場合、名前の付け方に注意。何をソースとして作成したのか認識する手段がない為  
  **{アカウント名}-{プール名}-{ボリューム名}-{snapshot / backup}** の名前を推奨  
  例1) account3-pool1-volume2-snapshot1  
  例2) account3-pool1-volume2-backup1  

  ![diagram](https://github.com/maysay1999/tipstricks/blob/main/images/anf_backup_sample.png)

## 手順

1. Resource Group を作成し、anf-backup.sh を実行

   ```bash
   az group create -n anfbackup-rg -l japaneast
   ```

   ```bash
   git clone https://github.com/maysay1999/tipstricks AnfBackup
   ```

   ```bash
   ~/AnfBackup/anf-backup.sh
   ```

2. account1のしたに、Volume1 と Volume２ を作成

   * ANFアカウント名: account1
   * ボリューム名: **volume1**
   * Protocol: NFSv3
   * Size: 100MiB

   * ANFアカウント名: account1
   * ボリューム名: **volume2**
   * Protocol: NFSv3
   * Size: 100MiB

3. VMを作成し、volume1 の中に 10MiB のファイルを作成

   * VM名: ubuntu01
   * リソースグループ: anfbackup-rg
   * Image: Ubuntu Server 21.10 - Gen2
   * Size: Standard_D2s_v4
   * VNet: anfbackup-vnet
   * Subnet: default-sub

   ボリュームをマウントした後、10Mのファイルを作成

   ```bash
   dd if=/dev/zero of=10m.img bs=1024 count=10240
   ```

4. VMを作成し、volume2 の中に 20MiB のファイルを作成

   ```bash
   dd if=/dev/zero of=20m.img bs=1024 count=20480
   ```

5. volume1 の バックアップを有効化

   account1 --> volume1 --> Backups --> Configure --> Enabled  

6. 手動 スナップショットなしでバックアップを作成

   Add Backup --> New Backup  

   バックアップ名: account1-pool1-volume1  

7. スナップショットを作成した後、バックアップを作成

   スナップショット名: account1-pool1-volume1-snapshot

8. volume2 に スナップショットポリシーを作成した後、バックアップポリシーを作成

   スナップショットポリシー名: account1-pool1-volume2-snapshot01
   バックアップポリシー名: account1-pool1-volume2-backup01

9. 同じアカウント同じVNetに復元

10. 同じアカウント違うVNetに復元

11. 別のアカウント同じVNetに復元
