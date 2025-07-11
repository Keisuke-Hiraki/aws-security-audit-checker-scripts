#!/bin/bash

# --- 設定項目 ---
PROFILE_NAME="your-profile-name"
ASSUME_ROLE_NAME="YourAssumeRoleName"
ACCOUNT_FILE="./accounts.list"
REGION_FILE="./regions.list"

# --- スクリプト本体 ---
if [[ ! -f "$ACCOUNT_FILE" ]]; then
    echo "エラー: アカウントリストファイル '$ACCOUNT_FILE' が見つかりません。" >&2
    exit 1
fi
if [[ ! -f "$REGION_FILE" ]]; then
    echo "エラー: リージョンリストファイル '$REGION_FILE' が見つかりません。" >&2
    exit 1
fi

mapfile -t TARGET_ACCOUNTS < "$ACCOUNT_FILE"
mapfile -t REGIONS < "$REGION_FILE"

echo "IAM Identity Centerのログインセッションを更新します..." >&2
aws sso login --profile ${PROFILE_NAME} >&2

echo "AccountId,Region,GuardDutyStatus"

for ACCOUNT_ID in "${TARGET_ACCOUNTS[@]}"; do
  [[ -z "$ACCOUNT_ID" ]] && continue
  echo "--- Checking GuardDuty on Account: ${ACCOUNT_ID} ---" >&2
  ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ASSUME_ROLE_NAME}"

  TEMP_CREDS=$(aws sts assume-role --role-arn ${ROLE_ARN} --role-session-name "GuardDutyCheck" --profile ${PROFILE_NAME} --output json)
  if [ $? -ne 0 ]; then
    echo "${ACCOUNT_ID},ALL,FailedToAssumeRole"
    continue
  fi

  export AWS_ACCESS_KEY_ID=$(echo $TEMP_CREDS | jq -r .Credentials.AccessKeyId)
  export AWS_SECRET_ACCESS_KEY=$(echo $TEMP_CREDS | jq -r .Credentials.SecretAccessKey)
  export AWS_SESSION_TOKEN=$(echo $TEMP_CREDS | jq -r .Credentials.SessionToken)

  for REGION in "${REGIONS[@]}"; do
    [[ -z "$REGION" ]] && continue
    
    # list-detectorsでDetectorIdのリストを取得し、その数が0より大きいか確認
    if aws guardduty list-detectors --region ${REGION} --output json | jq -e '.DetectorIds | length > 0' > /dev/null 2>&1; then
      STATUS="ENABLED"
    else
      STATUS="DISABLED"
    fi
    echo "${ACCOUNT_ID},${REGION},${STATUS}"
  done

  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
done

echo "--- GuardDuty checks completed. ---" >&2
