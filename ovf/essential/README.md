
# mdx1用最小構成VM用のOVF
mdx1にインポートすると、以下の構成のVMが作成される。

- ファームウェア: BIOS
- 仮想ハードディスクのSCSIコントローラ: LSI Logic
- 仮想CD/DVDのコントローラ: IDE
- 仮想ハードディスクの容量: 64 KiB
- ハードウェア時刻同期: 無効
- 仮想マシン一時休止: ソフト

# 64KiB.vmdkの作成方法
- 作成環境: openSUSE-Tumbleweed on WSL2
- 必要パッケージ: `qemu-img`, `open-vmdk`
- `qemu-img`単体でESXiでインポート可能なvmdkを出力できないので、`vmdk-convert`による変換が必要
- vmdkの最小容量は64 KiB

~~~sh
#!bin/bash
qemu-img create -f vmdk src.vmdk 64k
vmdk-convert src.vmdk 64KiB.vmdk
rm src.vmdk
~~~

# 参考URL
https://docs.redhat.com/ja/documentation/red_hat_enterprise_linux/5/html/virtualization/sect-virtualization-tips_and_tricks-using_qemu_img#sect-Virtualization-Tips_and_tricks-Using_qemu_img
https://gitlab.com/qemu-project/qemu/-/issues/2532
https://gitlab.com/qemu-project/qemu/-/issues/2086
https://bugs.launchpad.net/qemu/+bug/1828508
https://x.com/JakubJirutka/status/1233894997566611462
