- [VMテンプレートのインポート](#vmテンプレートのインポート)
- [言語設定](#言語設定)
- [リポジトリ](#リポジトリ)
- [System Role](#system-role)
- [ディスク構成](#ディスク構成)
- [時刻設定](#時刻設定)
- [Local Users](#local-users)
- [Summary](#summary)
  - [Software](#software)
  - [Network Configuration](#network-configuration)
- [インストール完了後に再起動](#インストール完了後に再起動)
- [初期設定](#初期設定)
  - [ログイン](#ログイン)
  - [ユーザー既定値の変更](#ユーザー既定値の変更)
    - [UMASK](#umask)
      - [leap](#leap)
      - [tw](#tw)
    - [/etc/skelの変更](#etcskelの変更)
  - [公開鍵の登録](#公開鍵の登録)
  - [sudoグループの追加](#sudoグループの追加)
  - [不要なデーモンの停止](#不要なデーモンの停止)
  - [カーネルパラメーター](#カーネルパラメーター)
    - [sysctl.d/99-nies](#sysctld99-nies)
  - [GRUBパラメータの更新](#grubパラメータの更新)

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

### ユーザー既定値の変更
#### UMASK
- 022だと、グループと他ユーザーも読み込み可能になるため、既定を077にする
- `login.defs`にUMASKの既定値が定義されるが、`login.defs.d`以下に既定値が設定される場合もある
- `login.defs`の値が優先されるので、`login.defs`が存在するなら、こちらを編集する

##### leap
`/etc/login.defs`のUMASkの定義業を077に変更

```sh
sed -i -E 's/^(UMASK[[:space:]]+)022/\1077/' /etc/login.defs
```

##### tw
- `/etc/login.defs`が無いので、差分を`/etc/login.defs.d/99-nies.defs`として作成する
- システムの既定値は、`/usr/etc/login.defs`にある

```sh
echo "UMASK 077" > /etc/login.defs.d/99-nies.defs && chmod 644 /etc/login.defs.d/99-nies.defs
```

#### /etc/skelの変更
- UMASK 077に合わせて、テンプレートもオーナ以外の権限を無くす
- .ssh/authorized_keysを作成する

```sh
find /etc/skel/ | xargs chmod go-rwx
mkdir /etc/skel/.ssh
touch /etc/skel/.ssh/authorized_keys
```

### 公開鍵の登録
- VMの共通ユーザーに`.ssh/authorized_keys`を作成して、公開鍵を登録する

### sudoグループの追加
- `/etc/sudoers.d/`以下に、sudoを許可する設定を作成する

```sh
touch /etc/sudoers.d/sudo_groups
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers.d/sudo_groups
```

- ユーザーにwheelを追加
```sh
usermod -aG wheel $ユーザー
```

### 不要なデーモンの停止
- NTPデーモンの停止

```sh
systemctl disable --now chronyd`
```

### カーネルパラメーター
#### sysctl.d/99-nies
IPv6の一時アドレスの無効化
```sh
#!/bin/bash
touch /etc/sysctl.d/99-nies.conf
chmod 644 /etc/sysctl.d/99-nies.conf
echo "net.ipv6.conf.all.use_tempaddr=0" >> /etc/sysctl.d/99-nies.conf
echo "net.ipv6.conf.default.use_tempaddr=0" >> /etc/sysctl.d/99-nies.conf
```

### GRUBパラメータの更新
ブートシーケンスのサイレント表示をやめる

変更前: `GRUB_CMDLINE_LINUX_DEFAULT="splash=silent preempt=full mitigations=auto quiet security=apparmor"`
変更後: `GRUB_CMDLINE_LINUX_DEFAULT="preempt=full mitigations=auto security=apparmor"`

```sh
#!/bin/bash
sed -i 's/\<splash=silent\>\s*//; s/\<quiet\>\s*//' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
```
