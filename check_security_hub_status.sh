#!/bin/bash

# --- 設定項目 ---
PROFILE_NAME="your-profile-name"
ASSUME_ROLE_NAME="YourAssumeRoleName"
ACCOUNT_FILE="./accounts.list"
REGION_FILE="./regions.list"

# 設定ファイルの存在チェック
if [[ ! -f "$ACCOUNT_FILE" ]]; then
    echo "エラー: アカウントリストファイル '$ACCOUNT_FILE' が見つかりません。" >&2
    exit 1
fi
if [[ ! -f "$REGION_FILE" ]]; then
    echo "エラー: リージョンリストファイル '$REGION_FILE' が見つかりません。" >&2
    exit 1
fi

# ファイルからアカウントIDとリージョンを配列に読み込む
mapfile -t TARGET_ACCOUNTS < "$ACCOUNT_FILE"
mapfile -t REGIONS < "$REGION_FILE"

# SSOログインセッションを開始/更新
echo "IAM Identity Centerのログインセッションを更新します..." >&2
aws sso login --profile ${PROFILE_NAME} >&2

# CSVヘッダーを出力
echo "AccountId,Region,SecurityHubStatus"

# 各アカウントに対してループ処理
for ACCOUNT_ID in "${TARGET_ACCOUNTS[@]}"; do
  # 空行はスキップ
  [[ -z "$ACCOUNT_ID" ]] && continue

  echo "--- Checking Account: ${ACCOUNT_ID} ---" >&2
  ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ASSUME_ROLE_NAME}"

  # IAM Identity Centerのプロファイルを使ってAssumeRoleを実行
  TEMP_CREDS=$(aws sts assume-role \
    --role-arn ${ROLE_ARN} \
    --role-session-name "SecurityHubCheck-$(date +%s)" \
    --profile ${PROFILE_NAME} \
    --output json)

  # assume-roleに失敗した場合はスキップ
  if [ $? -ne 0 ]; then
    echo "${ACCOUNT_ID},ALL,FailedToAssumeRole"
    continue
  fi

  # 一時的な認証情報を環境変数にエクスポート
  export AWS_ACCESS_KEY_ID=$(echo $TEMP_CREDS | jq -r .Credentials.AccessKeyId)
  export AWS_SECRET_ACCESS_KEY=$(echo $TEMP_CREDS | jq -r .Credentials.SecretAccessKey)
  export AWS_SESSION_TOKEN=$(echo $TEMP_CREDS | jq -r .Credentials.SessionToken)

  # 各リージョンに対してループ処理
  for REGION in "${REGIONS[@]}"; do
    # 空行はスキップ
    [[ -z "$REGION" ]] && continue

    # Security Hubのステータスを確認
    if aws securityhub describe-hub --region ${REGION} > /dev/null 2>&1; then
      STATUS="ENABLED"
    else
      STATUS="DISABLED_OR_NOT_AVAILABLE"
    fi
    echo "${ACCOUNT_ID},${REGION},${STATUS}"
  done

  # 環境変数をクリア
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
done

echo "--- All checks completed. ---" >&2
