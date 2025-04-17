

## はじめに
異なる仮想環境からVMを移行して、ブート可能になったとしても、Linuxの場合、初期RAMである`initrd`のデバイスが異なるため、必要最低限のデバイスドライバをロードできず、ブートが中断される。
そのため、レスキュー用のLive CDから、OSを起動させて、`initrd`を再作成する必要がある。

ここでは、openSUSEを例に、`initrd`の再作成の手順と、GRUB再設定の手順を記述する。

なお、Windowsは、異なるデバイスでロードした場合、自動的にデバイスドライバが再構築される。

## 検証環境
検証環境は以下の通り。

- 移行元: mdx1のVMware ESXi
- 移行先: Hyper-V on Windows 11 pro
- 対象VM: openSUSE 15.5 のゴールデンイメージ
- 仮想マシンのハードウェア構成
  - ファームウェア: EFI
  - セキュアブート: on
  - CPU: 1コア
  - メモリ: 2GiB
  - NIC: 1つ
- Live CD: openSUSE LiveのISOイメージ

mdx1からエクスポートしたVMのVMDKをHyper-V用のVHDXにコンバートし、Hyper-VのVMの仮想ディスクとして接続した。
Live CDは仮想DVDドライブにイメージファイルとしてマウントした。
DVDをブートオーダーの最初にして起動した。

##　手順
1. openSUSE Liveを起動する
2. 起動したOS環境で、`/mnt/root`を作成し、仮想ディスクの`ROOTパーティション`をマウントする
3. 以下のディレクトリをバインドする
```sh
sudo mount --bind /dev /mnt/root/dev
sudo mount --bind /proc /mnt/root/proc
sudo mount --bind /sys /mnt/root/sys
```
4. `/mnt/root/`にchrootする: `sudo chroot /mnt/root`
5. initrdを再作成する
   - openSUSEの場合は、`dracut`を使用する
   - 指定のカーネルのモジュールをロードするため、`/lib/module/`以下の最新のディレクトリ名を`<kernel_version>`として、指定する
   - `uname -r`で表示されるカーネルは、Live CDのものなので、指定できない。
   - `sudo dracut -f /boot/initrd-<kernel_version> <kernel_version>`
6. grub設定を更新する: `sudo grub2-mkconfig -o /boot/grub2/grub.cfg`
7. VMを停止する
8. VMのブートオーダーを変更して、仮想ディスクから起動する
9. 問題なく起動したら、現在の環境で、`initrd`を作成するか、カーネルのバージョンアップをパッケージマネージャから行う
   - 再作成を行う場合: `sudo dracut -f /boot/initrd-$(uname -r) $(uname -r)`
   - アップデート行う場合: `sudo zypper up -y`
19. Hyper-V用のデーモンやモジュールを入れる: `sudo zypper in hyper-v`
11. 後処理
    1.  仮想DVDデバイスは不要なので削除する
    2.  元の仮想化基盤で入れていたドライバやデーモンは様子を見ながら無効化や削除する

## 備考
- 起動できるかどうかの確認だけなら、セキュアブートを無効化して、`SystemRescueCD`のLinux Rootを自動探索して起動する方法を使う。
- 起動に成功した後に、`initrd`の再作成や、カーネルのアップデートを実行できるなら、`chroot`を使わずに省略もできる。
- Genericな方法として採用できるが、基本としてLive CDやインストールディスクのレスキューモードを使用する方法を知っておくほうが安全である。