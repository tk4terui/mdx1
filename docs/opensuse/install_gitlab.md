
## 前提条件
- [ ] hostname設定済みであること
- [ ] AD参加済みであること
- [ ] DNSで参照可能であること
  - [ ] 固定のホスト名
  - [ ] CNAMEで参照する

## 必要なパッケージのインストール
参考URL: https://docs.gitlab.com/install/package/suse/

```sh
zypper ref
zypper up
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
systemctl reload firewalld
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh | sudo bash
```

## 