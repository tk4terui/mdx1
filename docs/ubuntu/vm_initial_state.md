- ホスト名: ubuntu-2204
- スワップ: 有効
  - スワップ方法: スワップファイル
  - スワップサイズ: 2GiB
- セキュリティモジュール: AppArmor
- 初期ユーザ
  - root: パスワードの設定無し
  - mdxuser: 初回ログイン時にパスワードの強制設定, sudo可能
- ファイアウォール: 無効
- 自動アップデート: 無効
  - パッケージ更新の通知はオン
- tmp.mount: 無効
- SSH: 有効
- NTP: 有効
- VMware Tools: インストール済み
  - ホストとの時刻同期: 有効
- Lustreクライアント: インストール済み
- OFEDドライバ: インストール済み
  - dkmsだがカーネルアップデートに伴う自動ビルドは失敗する
- Lustreマウントをするためのスクリプトは配置済み
  - マウントのオンオフは`/etc/fstab`と`lustre_client`を有効にする必要がある
- OpenMPI: インストール済み
  - バージョン: 4.1.5a1
  - インストールパス: `/usr/mpi/gcc/openmpi-4.1.5a1`
  - PATHには未定義
- OpenMPI用のベンチマークソフト: インストール済み
  - インストールパス: `/usr/mpi/gcc/openmpi-4.1.5a1/tests`
  - imb
  - osu-micro-benchmark
- マシン固有のIDがテンプレートで共通 (要確認)
  - machine-id
  - disk-id
  - network-id