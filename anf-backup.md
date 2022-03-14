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
  1. `git clone https://github.com/maysay1999/tipstricks AnfBackup`
  2. ./anf-backup.sh

## ダイアグラム

![diagram](https://github.com/maysay1999/tipstricks/blob/main/images/anf_backup_diagram.png)

## 留意点

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
  {アカウント名}-{プール名}-{ボリューム名}-{snapshot / backup} の名前を推奨  
  例1) account3-pool1-volume2-snapshot1  
  account3-pool1-volume2-backup1  

  ![diagram](https://github.com/maysay1999/tipstricks/blob/main/images/anf_backup_sample.png)

