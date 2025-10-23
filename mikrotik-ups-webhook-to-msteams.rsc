# Create a new script
/system/script/add name=ups-monitor-webhook

# Put this in the script:
:local currentState [/system/ups/get 0 on-line]
:global lastState

:if ([:typeof $lastState] = "nothing") do={ :global lastState $currentState }

:if ($currentState != $lastState) do={
  :if ($currentState = false) do={
    /tool fetch http-method=post http-header-field="Content-Type: application/json" \
    http-data="{\"text\":\"[POWER OUTAGE] Power outage detected — UPS on battery.\"}" \
    url="https://YOUR_TEAMS_WEBHOOK_URL"
  } else={
    /tool fetch http-method=post http-header-field="Content-Type: application/json" \
    http-data="{\"text\":\"[POWER BACK ON] Power restored — UPS back on mains.\"}" \
    url="https://YOUR_TEAMS_WEBHOOK_URL"
  }
  :global lastState $currentState
}

# Tell the scheduler to run this script every 10 seconds 
/system/scheduler/add name=ups-check interval=10s on-event=ups-monitor-webhook
