# Phase 7: Communication Bridges & Integrations

This phase covers all Tier 2A communication plugins and Tier 2B enterprise API integrations.
Only set up the sections that were selected during the Planning interview.

For every plugin: add its required domain(s) to the egress whitelist, store credentials
in `.env` (mode 600), configure the channel in `openclaw.json`, start services, and test.

---

## Tier 2A Plugins

### Telegram

**Egress domains needed:** `api.telegram.org`

1. Create a bot: open Telegram → message `@BotFather` → `/newbot` → copy the Bot Token
2. Find your user ID: message `@userinfobot` on Telegram
3. Add to egress whitelist:
```bash
nemoclaw <n> policy update --allow-host api.telegram.org
```
4. Configure in `openclaw.json`:
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
5. Start and test:
```bash
nemoclaw start
nemoclaw <n> logs --follow | grep telegram
```
Send a message to your bot — verify it appears in logs and gets a response.

---

### Slack

**Egress domains needed:** `slack.com`, `api.slack.com`, `wss-primary.slack.com`

1. Create a Slack App at https://api.slack.com/apps → "Create New App"
2. Under OAuth & Permissions, add bot scopes: `chat:write`, `channels:read`, `im:read`, `im:write`
3. Install to workspace → copy Bot User OAuth Token (`xoxb-xxxx`)
4. Get your workspace ID and channel ID(s) from Slack (right-click channel → "Copy link")
5. Add to egress whitelist:
```bash
nemoclaw <n> policy update --allow-host slack.com
nemoclaw <n> policy update --allow-host api.slack.com
nemoclaw <n> policy update --allow-host wss-primary.slack.com
```
6. Configure in `openclaw.json`:
```json
{
  "channels": {
    "slack": {
      "token": "<SLACK_BOT_TOKEN>",
      "workspaceId": "<WORKSPACE_ID>",
      "channels": ["<CHANNEL_ID>"],
      "dmPolicy": "allowlist",
      "allowedUsers": ["<SLACK_USER_ID>"]
    }
  }
}
```
7. Start and test:
```bash
nemoclaw start
nemoclaw <n> logs --follow | grep slack
```
Send a message in the configured channel — verify the agent responds.

---

### Discord

**Egress domains needed:** `discord.com`, `gateway.discord.gg`

1. Create a bot at https://discord.com/developers/applications → "New Application"
2. Under Bot tab → copy the Bot Token
3. Under OAuth2 → URL Generator, select scopes `bot` with permissions: Send Messages, Read Message History
4. Use the generated URL to invite the bot to your server
5. Get server ID and channel ID(s): enable Developer Mode in Discord settings, right-click → "Copy ID"
6. Add to egress whitelist:
```bash
nemoclaw <n> policy update --allow-host discord.com
nemoclaw <n> policy update --allow-host gateway.discord.gg
```
7. Configure in `openclaw.json`:
```json
{
  "channels": {
    "discord": {
      "token": "<DISCORD_BOT_TOKEN>",
      "serverId": "<SERVER_ID>",
      "channels": ["<CHANNEL_ID>"],
      "dmPolicy": "allowlist",
      "allowedUsers": ["<DISCORD_USER_ID>"]
    }
  }
}
```
8. Start and test:
```bash
nemoclaw start
nemoclaw <n> logs --follow | grep discord
```

---

### Custom Webhook

**Egress domains needed:** the domain of your webhook endpoint

1. Determine your webhook URL and any authentication headers
2. Add the webhook domain to egress whitelist:
```bash
nemoclaw <n> policy update --allow-host your-webhook-domain.com
```
3. Configure in `openclaw.json`:
```json
{
  "channels": {
    "webhook": {
      "url": "https://your-webhook-domain.com/endpoint",
      "method": "POST",
      "headers": {
        "Authorization": "Bearer <TOKEN>"
      },
      "events": ["message", "action", "error"]
    }
  }
}
```
4. Test by triggering an agent action and verifying the webhook receives the payload.

---

## Tier 2B Enterprise Integrations

### Outlook / Microsoft Graph API (Module E)

**Egress domains needed:** `graph.microsoft.com`, `login.microsoftonline.com`

1. Register an Azure AD App:
   - Azure Portal → App Registrations → New Registration
   - Grant API permissions: `Files.Read`, `Mail.Send` (minimum)
   - Generate a client secret
   - Note: Tenant ID, Client ID, Client Secret

2. Add credentials to `.env`:
```
MSGRAPH_TENANT_ID=xxxx
MSGRAPH_CLIENT_ID=xxxx
MSGRAPH_CLIENT_SECRET=xxxx
```

3. Add to egress whitelist:
```bash
nemoclaw <n> policy update --allow-host graph.microsoft.com
nemoclaw <n> policy update --allow-host login.microsoftonline.com
```

4. Optional L7 restrictions (Module F) — restrict the agent to safe operations:
```yaml
network:
  allowedEgressHosts:
    - host: graph.microsoft.com
      protocol: rest
      methods: [GET, POST]    # no DELETE — prevents accidental data loss
```

5. Security guardrails:
   - Restrict SharePoint access to specific site IDs
   - Limit `Mail.Send` to specific recipients or domains
   - Log all Graph API interactions in `audit.json`
   - Never grant `Files.ReadWrite.All` unless absolutely necessary

6. Test:
```bash
nemoclaw <n> connect
sandbox@<n>:~$ openclaw agent --agent main --local -m "list my recent emails" --session-id test
```

---

## Common Steps for Any Integration

Regardless of which plugin or API you're adding:

1. **Egress:** Add every required domain to `allowedEgressHosts` or via
   `nemoclaw <n> policy update --allow-host <domain>`
2. **Credentials:** Store tokens in `~/nemoclaw-project/.env` (mode 600), never in code
3. **L7 restrictions (if Module F selected):** For any API that supports destructive
   operations (DELETE, PUT), consider restricting to safe methods only
4. **Audit:** Verify interactions appear in `~/ta-agent/logs/audit.json`
5. **Test connectivity** from inside the sandbox before relying on the integration
