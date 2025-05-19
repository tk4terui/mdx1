- [はじめに](#はじめに)
- [手順](#手順)
  - [準備作業](#準備作業)
  - [Live環境のブート](#live環境のブート)
  - [不足しているパッケージのインストール](#不足しているパッケージのインストール)
  - [GPartedの縮小作業](#gpartedの縮小作業)
  - [ddでシュリンク先の仮想ストレージにクローン](#ddでシュリンク先の仮想ストレージにクローン)
  - [Gpartedで拡張作業](#gpartedで拡張作業)
  - [/etc/fstabの編集](#etcfstabの編集)
  - [VMのエクスポート/インポート](#vmのエクスポートインポート)
    - [該当行](#該当行)
- [おわりに](#おわりに)

## はじめに
mdx1で提供されているUbuntuテンプレートは、仮想ストレージを40GiB消費する。
特定用途にしぼった運用を想定する場合、仮想ストレージを縮退させる必要がある。
この手順を記す。

## 手順

### 準備作業
- 作業環境は、mdx1のESXi環境を利用する。ローカルで仮想環境を使用しない。
- UEFIのセキュアブートを有効にした場合でも使用できるよう、同じディストリビューションのLive CDを利用する
- mdx1の`01_Ubnuntu-2204-server`から最小資源でデプロイのみする
  - CPU: 4
  - 仮想ストレージ: 40
  - サービスネットワーク: 仮想NIC
  - 起動しない
  - mdxuserの公開鍵を登録済み
- デプロイ後にシュリンク後のコピー先の仮想ストレージ2を10GiBで追加する
- `ubuntu-22.04-5-desktop-amd64.iso`を入手してアップロード

### Live環境のブート
1. デプロイしたVMに、ISOファイルをマウントしてブート
2. 仮想コンソールから、GRUBのブートエントリ選択画面で、`UEFI Firmware Settings`を選ぶ
3. `CDROM Drive`を選択し、CDからブート
   1. 一番上の`Try and Install`を選択する。
   2. 2番目だと、言語選択の後にブートが失敗する
3. ブートに成功するとLive環境が起動する
4. Welcomeの画面で、`English`と`Try Ubuntu`を選択する
5. Live環境のデスクトップが起動する

> *NOTE*
> 1. コマンド入力はTerminalやコンソールからの入力である
> 2. UEFI Firmware画面でCDROM Driveが二つ以上存在していた場合、いずれかのCDROM Driveにマウントされているので、片っ端から選択する
> 3. 仮想ストレージ1が**sda**、仮想ストレージ2が**sdb**になると仮定する

### 不足しているパッケージのインストール
Live環境でも不足しているパッケージの追加インストールが可能である。

- パーティション操作を行うために必要なパッケージをインストールする。
  - `sudo apt install mtools`

### GPartedの縮小作業
1. `sudo gparted`でGPartedを起動させる
2. `/dev/sda`のパーティションが表示されるが、自動マウントされているパーティションがあれば全部アンマウントする
3. パーティションにラベルをつけるため、パーティションを選択し、右クリックから`Label File System`を選択し、任意のラベル名を設定する
   1. `/dev/sda1`は`BOOT`
   2. `/dev/sda2`は`ROOT`
4. パーティションサイズを最小容量までリサイズするため、パーティションを選択し、右クリックから`Resize/Move` 
   1. `/dev/sda1`は最小容量`33MiB`までシュリンク
   2. `/dev/sda2`は最小容量までシュリンクし、`/dev/sda1`を縮小した領域を詰める
   3. パーティションの移動や縮小について警告がでるが、OKしてすすめる
5. GPartedのパーティション操作の作業を実行するため、`Apply All Oprations`を押す

### ddでシュリンク先の仮想ストレージにクローン
ddコマンドを使うと、パーティションの先頭からデータを順番にコピーされていくので、最小パーティションサイズのデータ構造がそのままコピーされる。

ただし、パーティションテーブルは壊れるので、gdiskコマンドを使ってクローン後にパーティションテーブルを再構築する

1. `sudo dd if=/dev/sda of=/dev/sdb bs=1M`
2. パーティションテーブルの再構築
   1. `sudo gdisk /dev/sdb`
   2. レスキューモード(`r`)
   3. パーティションテーブルをリビルド(`d`)
   4. 新しいパーティションテーブルを書込み(`w`)

### Gpartedで拡張作業
1. `sudo gparted`でGPartedを起動させる
2. `/dev/sdb`のパーティションを表示させる
3. `/dev/sdb2`を選択し、空きパーティションの最大まで拡張
4. GPartedのパーティション操作の作業を実行するため、`Apply All Oprations`を押す
5. 作業が完了したら、Live環境をシャットダウンして、VMを止める

### /etc/fstabの編集
`/dev/sdb2`の`/etc/fstab`を編集して、UUIDからLABELでマウントするようにする。

LABELを使用する理由は以下の通り
- UUIDはマシンIDやディスクIDなどの固有IDを変更した場合に使用できなくなる。
- デバイスパーティションを直接使用する場合、ブートして認識された順番で、名前つけが逆になる場合もある。

ただし、複数のディスクで同一のLABELが存在させないように注意する事

```sh
LABEL=ROOT / ext4 defaults 0 1
LABEL=BOOT /boot/efi vfat defaults 0 1
```

### VMのエクスポート/インポート
VMをエクスポートして、縮退後の仮想ストレージのみの仮想マシンにして、インポートする
1. VMをエクスポートする
   1. disk-0は不要なのでダウンロードしなくてもよい。
2. ダウンロードしたファイルの整理
   1. `disk-0.vmdk`をダウンロードしていた場合は削除
   2. `disk-1.vmdk`を`disk-0.vmdk`に名前を変更
3. OVFの編集
   1. `disk-1.vmdk`に関係する行を削除、該当行にまとめて記す
   2. 仮想ストレージサイズの変更、vmdisk1はdisk-0の事を示すため、変更後のサイズにする。
      1. 変更前: `<Disk ovf:capacity="40" ovf:capacityAllocationUnits="byte * 2^30" ovf:diskId="vmdisk1" ovf:fileRef="file1" ovf:format="http://www.vmware.com/interfaces/specifications/vmdk.html#streamOptimized"/>`
      2. 変更後: `<Disk ovf:capacity="10" ovf:capacityAllocationUnits="byte * 2^30" ovf:diskId="vmdisk1" ovf:fileRef="file1" ovf:format="http://www.vmware.com/interfaces/specifications/vmdk.html#streamOptimized"/>`
4. VMのインポートで、OVFファイルと、`disk-0.vmdk`を選択する
   1. インポート時のCPUパック数に制約はないので、1にしておく(使用リソースの最小化)
   2. ネットワークに指定は無し。指定されたネットワークによって、OVFは自動設定される。
5. インポート後のVMの仮想ストレージ1のサイズが10GiBとなっていることを確認する

#### 該当行
以下のテキストが含まれる行を削除する。
- 一部の数字はエクスポートした時の状況で変更されている可能性あり。
- `disk-1.vmdk`に関係するタグをすべて削除しておく。

```xml
    <File ovf:href="disk-1.vmdk" ovf:id="file2" ovf:size="9783495109"/>
    <Disk ovf:capacity="10" ovf:capacityAllocationUnits="byte * 2^30" ovf:diskId="vmdisk2" ovf:fileRef="file2" ovf:format="http://www.vmware.com/interfaces/specifications/vmdk.html#streamOptimized"/>
      <Item>
        <rasd:AddressOnParent>1</rasd:AddressOnParent>
        <rasd:ElementName>Hard disk 2</rasd:ElementName>
        <rasd:HostResource>ovf:/disk/vmdisk2</rasd:HostResource>
        <rasd:InstanceID>11</rasd:InstanceID>
        <rasd:Parent>4</rasd:Parent>
        <rasd:ResourceType>17</rasd:ResourceType>
        <vmw:Config ovf:required="false" vmw:key="backing.writeThrough" vmw:value="false"/>
      </Item>
```

## おわりに
これで、VMにより消費される、仮想ストレージのサイズを40GiBから10GiBへ縮退できた。
デスクトップやGPU用のテンプレートの場合でも、必要な大きさに縮退可能。
この後の設定は、ログイン後に行うか、`cloud-init`を利用することが可能である。

不要なパッケージの削除や、必要なデーモンの有効化などは、縮退後に実施すること