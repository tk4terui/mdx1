- [はじめに](#はじめに)
  - [mdx1とVMware](#mdx1とvmware)
  - [脱VMwareの候補](#脱vmwareの候補)
  - [仮想化基盤の互換性](#仮想化基盤の互換性)
- [準備](#準備)
  - [対象Linux](#対象linux)
  - [利用ソフトウェア](#利用ソフトウェア)
  - [実行環境](#実行環境)
- [方法](#方法)
  - [最小容量のVMDKの仮想ディスクを作成する](#最小容量のvmdkの仮想ディスクを作成する)
  - [QCOW2からVMDK](#qcow2からvmdk)
    - [Ubuntu](#ubuntu)
    - [openSUSE](#opensuse)
    - [Rocky](#rocky)
  - [QCOW2からVHDX](#qcow2からvhdx)
    - [Ubuntu](#ubuntu-1)
    - [openSUSE](#opensuse-1)
    - [Rocky](#rocky-1)
- [参考URL](#参考url)

# はじめに
主要ディストリビューションは仮想化基盤向けにVMイメージが提供されている。
これらのVMイメージを利用することで、mdx1上でISOからのインストールを省略することができる。
VMイメージの仮想ハードディスクは、特定の仮想化基盤向けにフォーマットされている必要がある。
動作対象とする仮想化基盤向けにフォーマットされたVMイメージは複数用意されている。
ただし、すべての仮想化基盤を対象に用意されているとは限らない。
ユーザーや市場の需要、コミュニティの方針により、商用仮想化基盤について用意されていない場合もある。

## mdx1とVMware
mdx1の場合は、VMware ESXiを使用しているため、OVFとVMDKの組合せたVMイメージ必要になる。
VMDKはVMware用の仮想ハードディスクで、OVFは仮想マシンの構成が定義された設定ファイルである。
これらをアーカイブ化したものがOVAで、OVAを伸長することで、OVFとVMDKの組合せを得ることができる。
また、VMware WorkStationを利用することで、ユーザのローカル環境でVMを作成してから、エクスポートすることで独自のOVFとVMDKを得ることも可能である。

VMware自体は2023年11月にBroadcomに買収されてから、ESXiの提供は終了し、ライセンス費用は高騰化、ユーザーにとって不安定な環境になっている。
そのため、昨今では脱VMwareの潮流が形成され、ディストリビューションとしてVMware用のVMイメージを提供する動機が弱まっている。

## 脱VMwareの候補
脱VMwareの候補の一つとして、OpenStackが存在する。オープンソースの仮想環境として歴史と認知度があり、ディストリビューションによる商用サポートも提供されている。
オンプレミスの仮想化基盤として構築されている実績もあり、ベンダーロックインの回避のため、選択されている。
実際にmdx2では、OpenStackによる仮想化基盤が構築された。

これら以外に、オンプレミスで採用されている仮想化基盤として、マイクロソフトのWindows ServerによるHyper-Vがある。

そして、ディストリビューションから、OpenStackやHyper-V向けのVMイメージや仮想ハードディスクが提供されている。

## 仮想化基盤の互換性
ユーザー側では、以下のような問題が発生する。
- mdx1やmdx2では異なる仮想化基盤が利用されている
- ユーザーの所属機関ではさらに異なるハイパーバイザが利用されている場合もある
- 複数の仮想化環境を動作環境とした場合、ユーザーで開発環境や検証環境を用意することは大きな負担となる

そのため、ユーザー側で用意する仮想化基盤は少なくし、仮想マシンのインポートとエクスポートで複数の仮想化基盤に対応できる方が理想である。
しかし、単一の仮想化基盤の機能だけで、異なる仮想化基盤の相互運用できるようにするには限界がある。
そのため、仮想化基盤に依らずに、異なる仮想化基盤への移行方法や、マルチ環境を考慮した開発体制を整えておく必要がある。

本稿では、異なる仮想化環境に対応した、VMイメージや仮想ハードディスクの相互変換方法について記す。
Linux上で利用可能なオープンソースのソフトウェアのみを利用する。

# 準備
## 対象Linux 
[OS選定](./os_selection.md)の**仮想ディスクイメージからインストール可能なOS**で、OpenStack用のqcow2イメージが、提供されているものが望ましい。

今回、検証したのは以下の3つのOpenStack用のqcow2
- Ubuntu
- openSUSE Minimal
- Rocky Linux

## 利用ソフトウェア
- `qemu-img`: https://github.com/qemu/qemu
- `open-vmdk`: https://github.com/vmware/open-vmdk

`qemu-img`は仮想ディスクイメージを、変換するためのツール。
今回は、qcow2イメージをVMDKやVHDXへ変換し、仮想化基盤間のインポート/エクスポートを行えるようにする。

`open-vmdk`は不正なVMDKフォーマットを正常化させるために使用する。

`qemu-img create`で空の仮想ディスクイメージを作成し、VMDKへ変換した場合のみ、不正なVMDKになる。
このVMDKはESXiでインポートできないため、`open-vmdk`に付属する`vmdk-convert`を使って、VMDKからVMDKへ再変換をかけて正常化させる必要がある。

コミュニティから提供されている、空ではないqcow2の場合は、`qemu-img convert`で、問題のないVMDKに変換される。

## 実行環境
- WSL2上のopenSUSE Tumbleweed
- 利用ソフトウェアのインストール: `zypper in qemu-img open-vmdk`

`qemu-img`はほとんどのディストリビューションのパッケージマネージャ経由でインストールが可能である。
一方で、`open-vmdk`は、**openSUSE**のみパッケージマネージャー経由でインストールでき、それ以外は上記のgithubリポジトリからソースコードをダウンロードして、ビルドする必要がある。
手間を省くなら、WSL上のopenSUSEを利用するのが手っ取り早い

# 方法
変換方法について、実際の用途とコマンドを事例に記す

## 最小容量のVMDKの仮想ディスクを作成する
最小容量の64KiB.vmdkを作成する。

VMDKの仕様上、最小限の容量は64KiBである。
ワンライナーのコマンドで以下の通り。

`qemu-img create -f vmdk src.vmdk 64k && vmdk-convert src.vmdk 64KiB.vmdk && rm src.vmdk`

- `qemu-img create`で、64KiBで、空のVMDKを作成する。
- `vmdk-convert`で、フォーマットを校正する。
- 不要なVMDKを削除する

## QCOW2からVMDK
ディストリビューションから提供されているOpenStack用QCOW2をVMDKに変換する。

`qemu-img convert -p -f qcow2 -O vmdk -o adapter_type=lsilogic,subformat=streamOptimized,compat6 変換元QCOW2イメージ 変換先VMDK`

ESXi用VMDKのオプションの意味は以下の通り。
- adapter_type=lsilogic: デフォルトだとIDEを使用とするので指定する
- subformat=streamOptimized,compat6: デフォルトだとVMware4の古いVMDKになるため、ESXi6以降の新しいフォーマットを指定する

mdx1の場合は、ESXi用のVMDKのほかにOVFが必要になるが、こちらは別途用意する。

各ディストリビューションの適用例は以下の通りで、出力先の`disk-0.vmdk`はmdx1でOVFを作成した際の既定のファイル名

### Ubuntu
`qemu-img convert -p -f qcow2 -O vmdk -o adapter_type=lsilogic,subformat=streamOptimized,compat6 jammy-server-cloudimg-amd64.img disk-0.vmdk`

### openSUSE
`qemu-img convert -p -f qcow2 -O vmdk -o adapter_type=lsilogic,subformat=streamOptimized,compat6 openSUSE-Leap-15.6-Minimal-VM.x86_64-Cloud.qcow2 disk-0.vmdk`

### Rocky
`qemu-img convert -p -f qcow2 -O vmdk -o adapter_type=lsilogic,subformat=streamOptimized,compat6 Rocky-9-GenericCloud-Base.latest.x86_64.qcow2 disk-0.vmdk`

## QCOW2からVHDX
Hyper-V用のVHDXに変換する場合は、以下のコマンドである

`qemu-img convert -p -f qcow2 -O vhdx -o subformat=dynamic 変換元QCOW2イメージ 変換先VHDX`

オプションの意味は以下の通り
- subformat=dynamic: 動的VHDXを有効にする

### Ubuntu
`qemu-img convert -p -f qcow2 -O vhdx -o subformat=dynamic jammy-server-cloudimg-amd64.img os.vhdx`

### openSUSE
`qemu-img convert -p -f qcow2 -O vhdx -o subformat=dynamic openSUSE-Leap-15.6-Minimal-VM.x86_64-Cloud.qcow2 os.vhdx`

### Rocky
`qemu-img convert -p -f qcow2 -O vhdx -o subformat=dynamic Rocky-9-GenericCloud-Base.latest.x86_64.qcow2 os.vhdx`

# 参考URL
- [qimg-imgの使用](https://docs.redhat.com/ja/documentation/red_hat_enterprise_linux/5/html/virtualization/sect-virtualization-tips_and_tricks-using_qemu_img#sect-Virtualization-Tips_and_tricks-Using_qemu_img)
- [empty vmdk disk created by qemu-img cann't import to vmware ESXi or Workstation](https://gitlab.com/qemu-project/qemu/-/issues/2532)
- [qemu-img created VMDK files lead to "Unsupported or invalid disk type 7" on ESXi](https://gitlab.com/qemu-project/qemu/-/issues/2086)
- [qemu-img created VMDK files lead to "Unsupported or invalid disk type 7"](https://bugs.launchpad.net/qemu/+bug/1828508)
- [vmdkのXの投稿](https://x.com/JakubJirutka/status/1233894997566611462)

