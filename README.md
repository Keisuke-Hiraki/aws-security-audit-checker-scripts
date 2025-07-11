# aws-security-audit-checker-scripts

IAM Identity Center を使用して複数の AWS アカウントにスイッチロールし、セキュリティサービスの有効化状況をチェックするスクリプト集です。

詳細は、下記ブログをご参照ください。



## 概要

このスクリプトセットは以下のAWSセキュリティサービスの有効化状況を一括でチェックできます：

- **AWS Security Hub**
- **AWS GuardDuty** 
- **IAM Access Analyzer**

## ファイル構成

```
aws-security-audit-checker-scripts/
├── check_security_hub_status.sh  # Security Hubチェックスクリプト
├── check_guardduty_status.sh     # GuardDutyチェックスクリプト
├── check_analyzer_status.sh      # Access Analyzerチェックスクリプト
├── accounts.list                 # チェック対象アカウント一覧
├── regions.list                  # チェック対象リージョン一覧
└── README.md                     # このファイル
```

## 前提条件

- AWS CLI v2 がインストール済み
- jq がインストール済み
- IAM Identity Center のプロファイルが設定済み
- 各アカウントにスイッチロール用の IAM ロールが作成済み

## クイックスタート

### 1. 設定ファイルの編集

```bash
# アカウントリストを編集
vi accounts.list

# リージョンリストを編集  
vi regions.list

# スクリプト内の変数を環境に合わせて変更
vi check_security_hub_status.sh    # PROFILE_NAME と ASSUME_ROLE_NAME を変更
vi check_guardduty_status.sh       # PROFILE_NAME と ASSUME_ROLE_NAME を変更
vi check_analyzer_status.sh        # PROFILE_NAME と ASSUME_ROLE_NAME を変更
```

### 2. 実行権限の付与

```bash
chmod +x check_security_hub_status.sh check_guardduty_status.sh check_analyzer_status.sh
```

### 3. スクリプトの実行

```bash
# 各サービスの状況確認
./check_security_hub_status.sh > security_hub_status.csv
./check_guardduty_status.sh > guardduty_status.csv
./check_analyzer_status.sh > analyzer_status.csv
```

## 設定項目

各スクリプトで共通して使用する変数：

```bash
PROFILE_NAME="your-profile-name"      # IAM Identity Center のプロファイル名
ASSUME_ROLE_NAME="YourAssumeRoleName" # 各アカウントのスイッチロール名
ACCOUNT_FILE="./accounts.list"        # チェック対象アカウント一覧ファイル
REGION_FILE="./regions.list"          # チェック対象リージョン一覧ファイル
```

## 出力形式

各スクリプトはCSV形式で結果を出力します：

```csv
AccountId,Region,ServiceStatus
123456789012,us-east-1,ENABLED
123456789012,us-east-2,DISABLED
456789012345,ALL,FailedToAssumeRole
```
---

**注意**: 実際の使用前に、ブログ記事で詳細な設定手順と注意事項を必ずご確認ください。 
