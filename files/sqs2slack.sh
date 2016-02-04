#!/bin/bash

# AWS configuration
SQS_URL="<sqs url>"
REGION="<region>"

# slack configuration
SLACK_CHANNEL="<channel name>"
SLACK_USERNAME="CloudWatchAlarmBot"
SLACK_ICON="<icon_name>"
SLACK_WEBHOOK_URL="<slack webhook url>"

# project configuration
PROJECT="<project name>"

warn(){
  echo $1 >&2
  sleep 10
  continue
}

delete_queue(){
  handle=$1
  aws sqs delete-message --queue-url ${SQS_URL} --region ${REGION} --receipt-handle ${handle}
}

push2slack(){
  messages=($@)

  set -- ${messages[*]}
  name=$1
  description=$2
  state=$3
  metric=$4
  operator=$5
  threshold=$6
  period=$7
  evaluation_periods=$8

data=`cat << EOF
    payload={
    "channel": "${SLACK_CHANNEL}",
    "username": "${SLACK_USERNAME}",
    "icon_emoji": "${SLACK_ICON}",
    "link_names": 1 ,
    "attachments": [{
        "fallback": "Alarm",
        "color": "#993300",
        "pretext": "CloudWatch Alarm" ,
        "title": "${description} ",
        "text": "確認お願いします @channel",
        "fields": [
          {
            "title": "Project",
            "value": "$PROJECT",
            "short": true
          },
          {
            "title": "Detail",
            "value": "${metric} ${operator} ${threshold} . check in every ${period} seconds. failed ${evaluation_periods} times.",
            "short": true
          }
        ]
      }]
  }
EOF`

  curl -X POST --data-urlencode "${data}" ${SLACK_WEBHOOK_URL}
}

main(){
  while true
  do
    res=`aws sqs receive-message --queue-url ${SQS_URL} --region ${REGION}`

    handle=`echo ${res} | jq -r '.Messages[].ReceiptHandle'`
    body=`echo ${res} | jq -r '.Messages[].Body'`

    [[ ${body} == "" || ${handle} == "" ]] && warn 'body or handle not found'

    IFS=$'\n'

    messages=`echo ${body} | jq -r '.Message' | jq -r -c ' \
      .AlarmName, \
      .AlarmDescription, \
      .NewStateReason, \
      .Trigger.MetricName, \
      .Trigger.ComparisonOperator, \
      .Trigger.Threshold, \
      .Trigger.Period, \
      .Trigger.EvaluationPeriods'`

    push2slack ${messages[*]}
    IFS=$' \t\n'

    [[ $? == 0 ]] && delete_queue $handle

    sleep 10
  done
}

main $@
