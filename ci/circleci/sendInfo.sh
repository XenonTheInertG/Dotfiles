#!/bin/bash
BOT_TOKEN=
CHAT_ID=
 
# Send info plox
function sendinfo() {
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
                        -d CHAT_ID=$CHAT_ID \
                        -d "disable_web_page_preview=true" \
                        -d "parse_mode=html" \
                        -d text="<b>YeetAnotherPerf</b> new build is up%0AStarted on <code>Circle CI</code>%0AFor device $(echo ${device})%0AUnder commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0AStarted on <code>$(TZ=Asia/Jakarta date)</code>%0A<b>CI Workflow information:</b> <a href='https://circleci.com/workflow-run/${CIRCLE_WORKFLOW_ID}'>here</a>"
}

if [ "$is_test" = true ]; then
     echo "Its alpha test build"
     unset CHAT_ID
     unset BOT_TOKEN
     else
     echo "Its beta release build"
     sendinfo
fi
 
