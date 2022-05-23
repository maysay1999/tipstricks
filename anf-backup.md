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
* その他は、[こちら](https://github.com/maysay1999/anfdemo02/blob/main/anf-hands-on_prep.md)をご参照下さい

## ダイアグラム

![diagram](https://github.com/maysay1999/tipstricks/blob/main/images/anf_backup_diagram.png)  
  ダイアグラムのダウンロードは[ここから](https://github.com/maysay1999/tipstricks/blob/main/pdfs/220314_hands-on_diagram_anf_backup.pdf)

## 留意点

* バックアップは3つのタイプ  
  * 手動 スナップショットなしでバックアップ  
  * 手動 スナップショットを作成した後、バックアップ  
  * 自動 スナップショットポリシーを作成した後、バックアップポリシーを作成し自動バックアップ  

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
* 同じANFアカウント同じVNetに復元できる
* 同じANFアカウント違うVNetに復元できる
* 別のANFアカウントのVNetに復元できる
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
   code ~/AnfBackup/anf-backup.sh
   ```

2. 27行目にpasswordを投入し(12文字以上)、上書き設定した後、shellを実行する。

   ![anf-backup password](https://github.com/maysay1999/tipstricks/blob/main/images/anf-backup-password.png)

   ```bash
   ~/AnfBackup/anf-backup.sh
   ```

3. NetApp account1 --> pool1 の配下に、Volume1 を作成

   * ANFアカウント名: account1
   * ボリューム名: **volume1**
   * Protocol: NFSv3
   * Size: 100GiB

   ![anf backup volume1](https://github.com/maysay1999/tipstricks/blob/main/images/anf_backup_vol1.png)

4. NetApp account1 --> pool1 の配下に、Volume2 を作成

   * ANFアカウント名: account1
   * ボリューム名: **volume2**
   * Protocol: NFSv3
   * Size: 100GiB

   ![anf backup volume2](https://github.com/maysay1999/tipstricks/blob/main/images/anf_backup_vol2.png)  

5. VM ubuntu-anf-demo01に bastion でログインし、volume1 をマウント。そして、10MiB のファイルを作成

   VM ubuntu-anf-demo01に bastion でログイン

   ![anf backup ubuntu](https://github.com/maysay1999/tipstricks/blob/main/images/anf_backup_ubuntu.png)

   volume1 をマウントした後、10Mのファイルを作成

   ```bash
   sudo -i
   apt install -y nfs-common
   cd /mnt
   mkdir volume1
   mount -t nfs -o rw,hard,rsize=65536,wsize=65536,vers=3,tcp 172.29.64.4:/volume1 volume1
   ```

   ```bash
   cd /mnt/volume1
   dd if=/dev/zero of=10m.img bs=1024 count=10240
   ```

   ```bash
   ls -lh
   ```

6. volume2 をマウントした後、 20MiB のファイルを作成

   ```bash
   cd /mnt
   mkdir volume2
   mount -t nfs -o rw,hard,rsize=65536,wsize=65536,vers=3,tcp 172.29.64.4:/volume2 volume2
   ```

   ```bash
   cd /mnt/volume2
   dd if=/dev/zero of=20m.img bs=1024 count=20480
   ```

   ```bash
   ls -lh
   ```

7. volume1 の バックアップを有効化

   account1 --> volume1 --> Backups --> Configure --> Enabled --> OK  

   ![anf backup enabled](https://github.com/maysay1999/tipstricks/blob/main/images/anf_backup_enabled.png)

8. 手動 スナップショットなしでバックアップを作成

   Add Backup --> New Backup  

   * バックアップ名: account1-pool1-volume1  

9. スナップショットを作成した後、バックアップを作成

   * スナップショット名: account1-pool1-volume1-snapshot

10. volume2 に スナップショットポリシーを作成した後、バックアップポリシーを作成

* スナップショットポリシー名: account1-pool1-volume2-snapshot01
* バックアップポリシー名: account1-pool1-volume2-backup01

11. 同じアカウント同じVNetに復元

12. 同じアカウント違うVNetに復元

13. 別のアカウント同じVNetに復元

    * account2 からリストアする  
