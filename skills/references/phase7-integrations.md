# Phase 7: Communication Bridges & Integrations

## Telegram Bridge

### 7.1 Create the Bot
1. Open Telegram and message `@BotFather`
2. Send `/newbot` and follow prompts
3. Copy the Bot Token

### 7.2 Configure in NemoClaw
In the sandbox config or `openclaw.json`, add:

```json
{
  "channels": {
    "telegram": {
      "token": "<BOT_TOKEN>",
      "dmPolicy": "allowlist",
      "allowedUsers": ["<USER_ID_1>", "<USER_ID_2>"]
    }
  }
}
```

The `dmPolicy: allowlist` setting ensures the bot only responds to authorized user IDs.
To find your Telegram user ID, message `@userinfobot` on Telegram.

### 7.3 Start the Bridge
```bash
nemoclaw start    # starts auxiliary services including Telegram bridge
```

### 7.4 Test
Send a message to your bot in Telegram. Check logs:
```bash
nemoclaw <n> logs --follow | grep telegram
```

---

## Microsoft Graph API Integration (Enterprise)

### 7.5 Register Azure AD App
1. Go to Azure Portal → App Registrations → New Registration
2. Grant API permissions: `Files.Read`, `Mail.Send` (minimum)
3. Generate a client secret
4. Note: Tenant ID, Client ID, Client Secret

### 7.6 Configure in NemoClaw
Add Graph API credentials to your `.env` file:
```
MSGRAPH_TENANT_ID=xxxx
MSGRAPH_CLIENT_ID=xxxx
MSGRAPH_CLIENT_SECRET=xxxx
```

Add `graph.microsoft.com` to the egress whitelist:
```bash
nemoclaw <n> policy update --allow-host graph.microsoft.com
```

### 7.7 Security Guardrails
The agent's internal policy filters should prevent accidental exfiltration of sensitive
material. Configure restrictions on what the agent can read/send:
- Restrict SharePoint access to specific site IDs
- Limit Mail.Send to specific recipients or domains
- Log all Graph API interactions in audit.json

---

## Other Integrations

For any additional API integrations:
1. Add the API domain to `allowedEgressHosts`
2. Store credentials in `.env` (mode 600)
3. Configure L7 restrictions if the API supports destructive operations
4. Test connectivity from inside the sandbox
