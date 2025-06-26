- [はじめに](#はじめに)
- [](#)

## VMテンプレートのインポート
1. [02_200_skelton_suse_15_06](../../ovf/02_200_skelton_suse_15_06)をインポート
2. インストールISOファイルをマウント
3. UEFI Firmware Settingsから、SATA CD/DVDで起動してインストール

## 言語設定
既定値
- デフォルト: 英語
- キーボード: US

## リポジトリ
既定値
- Update SLES15
- Update openSUSE Backports
- Update Non-Oss
- Non-OSS
- Main Update
- Main

## System Role
最小ロールとして、`Server`

## ディスク構成
SWAPディスクは二つ目をつかって、全領域を使う。
mdxはディスクの拡大縮小をオンラインでできないから、スワップ領域が不足した場合に備えて、別ディスクにしておく。
`/etc/fstab`はLABELを使う。
snapshotを使うかどうかは、使用後に決める。

- /dev/sda
  - sda1: EFI 33 MiB, LABEL=EFI
  - sda2: ROOT 7.97 GiB, LABEL=ROOT, btrfs, compress=zstd
- /dev/sdb: SWAP, LABEL=SWAP

## 時刻設定
あとで、オフにするから設定しなくても良いけど、NTPの既定値をmdx用にしておく

- Time Zone: Asia/Japan
- [x] Hardware Clock Set to UTC
- [x] Synchronize with NTP Server
- [x] Run NTP as daemon
- [x] Save NTP Configuration
- [x] Server: 172.16.2.26
- [x] Server: 172.16.2.27

## Local Users
mdx用既定ユーザーの作成, ユーザーの既定値を作ったら無効化。

- User's Full Name: なし
- Username: mdxuser
- Password: パスワードマネージャー参照
- [x] Use this password for system administrator

## Summary
ここまで既定だと以下のようになっている

- Boot Loader: GRUB2 EFI
- Secure Boot: enabled
- Update NVRAM: enabled
- Default systemd Target: Text mode
- Security:
  - CPU Mitigations: Auto
  - Firewall: enabled
  - SSH service: enabled
  - SSH port: open
  - Security Module: AppArmor
  - PolicyKit: Default

以下は既定から変更して、インストール開始

### Software
以下は、インストールしないのでチェックを外す
- Help and Support Document
- YaST Base Utilities

yast2は廃止予定なので、基本的なモノ以外いれない。必要なら後でインストールする。
細かく見ると、CUPSなどVMでは必要ないパッケージもあるが、手間に対して削減される容量が少ないので、やらない。

### Network Configuration
`wicked`から`NetworkManager`に変更する。
nmtuiでターミナルから変更可能であるのと、TWやデスクトップ環境の既定がNetworkManagerであるため

- DHCPにする
- すでに、VM環境内にDNSがある場合のみ、設定を追加する

## インストール完了後に再起動
再起動後にコンソールにログインが表示される

## 初期設定
### ログイン
コンソールからログインすることもできるが、IPアドレスを確認できたら、SSHでログインする
`ssh mdxuser@IPアドレス`

`sudo -s`で管理者になって、設定の変更

### 公開鍵の登録

### ユーザー既定値の変更

### 不要なデーモンの停止
- NTP: `systemctl disable --now chronyd`

### カーネルパラメーター
#### sysctl.d/99-nies
IPv6の一時アドレスの無効化
```sh
net.ipv6.conf.all.use_tempaddr=0
net.ipv6.conf.default.use_tempaddr=0
```


## 新規インストール時に行う事

- ユーザー管理の設定
  - ローカルユーザーのデフォルトユーザーの設定変更
    - デフォルトグループをusersに変更、ユーザー名グループが作成された場合は消す
    - umaskを077
    - 管理ユーザーの所属をwheel
    - `visudo`でwheelをNOPASSWSでsudoできるようにする
    - 既存ユーザーのファイル/ディレクトリを`find ./ | xargs chmod go-rwx`
    - 公開鍵の保存先を作る: `mkdir .ssh && touch .ssh/authorized_keys`
    - 使っている公開鍵をコピーする
  - NTPの停止と、vmtoolの時刻自国同期のオン
    - chronyを止める
  - IPv6の一時的なv6アドレスを無効化する
    - 99-nies.conf (NIESで使う場合という事で)
  - ブートシーケンスを表示させるため、`splash=silent quiet`を`/etc/default/grub`から消す






