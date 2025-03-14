
# はじめに
mdx1を利用する上で注意すべき制限のメモ

# TPM
- TPMモジュールは使用できない。
- OVFにItem要素で手動で追加してからインポートしようとしても失敗する。
- キープロバイダが構成されたら、将来的に利用できる可能性はあるが、現状はできない _2025-03-14時点_

## TPMをOVFに追加する方法
- vSphereでWindows 11をインストールする方法: https://www.vmware.com/docs/windows-11-support-on-vsphere
- vSphere 8.0でTPMを有効化する方法: https://techdocs.broadcom.com/us/en/vmware-cis/vsphere/vsphere-sdks-tools/8-0/ovf-tool-user-s-guide/examples-of-ovf-tool-syntax/modifying-an-ovf-package/tpm-as-a-virtual-device-in-ovf.html
- OVFを編集して直接TPMデバイスを追加する方法

```xml
<Item ovf:required="false">
  <rasd:AutomaticAllocation>false</rasd:AutomaticAllocation>
  <rasd:ElementName>Virtual TPM</rasd:ElementName>
  <rasd:InstanceID>13</rasd:InstanceID>
  <rasd:ResourceSubType>vmware.vtpm</rasd:ResourceSubType>
  <rasd:ResourceType>1</rasd:ResourceType>
</Item>
```