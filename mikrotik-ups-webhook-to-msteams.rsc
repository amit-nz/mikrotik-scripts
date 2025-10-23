# Optional - verify UPS works first
system ups print

# Create a new script
/system/script/add name=ups-monitor-webhook

# Put this in the script. Replace "https://YOUR_TEAMS_WEBHOOK_URL" with your url on lines 19&25
:local currentState [/system/ups/get 0 on-line]
:global lastState

:if ([:typeof $lastState] = "nothing") do={ :global lastState $currentState }

:if ($currentState != $lastState) do={
  :if ($currentState = false) do={
    /tool fetch http-method=post http-header-field="Content-Type: application/json" \
    http-data=("{\"@type\": \"MessageCard\", \"@context\": \"https://schema.org/extensions\", \
    \"themeColor\": \"ff0000\", \"title\": \"Alert from Mikrotik device " . [/system identity get name] . "\", \
    \"text\": \"Power outage - UPS on battery.\"}") \
    url="https://YOUR_TEAMS_WEBHOOK_URL"
  } else={
    /tool fetch http-method=post http-header-field="Content-Type: application/json" \
    http-data=("{\"@type\": \"MessageCard\", \"@context\": \"https://schema.org/extensions\", \
    \"themeColor\": \"36a64f\", \"title\": \"Recovery - Mikrotik device " . [/system identity get name] . "\", \
    \"text\": \"A/C restored.\"}") \
    url="https://YOUR_TEAMS_WEBHOOK_URL"
  }
  :global lastState $currentState
}

# Tell the scheduler to run this script every 10 seconds 
/system/scheduler/add name=ups-check interval=10s on-event=ups-monitor-webhook
