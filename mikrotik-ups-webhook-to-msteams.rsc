# Verify UPS works first
system ups print

# Create a new script
/system/script/add name=ups-monitor-webhook

# Tell the scheduler to run this script every 5 seconds 
/system/scheduler/add name=ups-check interval=5s on-event=ups-monitor-webhook

# Add the script - Replace "https://YOUR_TEAMS_WEBHOOK_URL" with your url - note, this needs a trailing slash for escaping.
/system script
add dont-require-permissions=no name=ups-monitor owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":local currentState [/system/ups/get 0 on-line]\
    \n:global lastState\
    \n\
    \n:local routerName [/system identity get name]\
    \n:local webhookUrl \"HTTPS://YOUR_WEBHOOK_GOES_HERE\"\
    \n\
    \n:if ([:typeof \$lastState] = \"nothing\") do={\
    \n    :set lastState \$currentState\
    \n}\
    \n\
    \n:if (\$currentState != \$lastState) do={\
    \n\
    \n    :local msg \"\"\
    \n\
    \n    :if (\$currentState = false) do={\
    \n        :set msg (\"\F0\9F\AA\AB UPS on Battery - \" . \$routerName)\
    \n    } else={\
    \n        :set msg (\"\E2\9C\85 UPS back on A/C - \" . \$routerName)\
    \n    }\
    \n\
    \n    :local payload (\"{\\\"text\\\":\\\"\" . \$msg . \"\\\"}\")\
    \n\
    \n    /tool fetch \\\
    \n        url=\$webhookUrl \\\
    \n        http-method=post \\\
    \n        http-header-field=\"Content-Type: application/json\" \\\
    \n        http-data=\$payload \\\
    \n        keep-result=no\
    \n\
    \n    :set lastState \$currentState\
    \n}"
