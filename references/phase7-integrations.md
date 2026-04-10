# Phase 7: Communication Bridges & Integrations

This phase covers all Tier 2A communication plugins and Tier 2B enterprise API integrations.
Only set up the sections that were selected during the Planning interview.

For every plugin: add its required domain(s) to the egress whitelist (via `nemoclaw <n>
policy-add`), store credentials in `.env` (mode 600), configure the channel in the host
config, start services, and test.

## ⚠️ Read this first: Authoritative Telegram source

Before doing anything Telegram-related, check the canonical NVIDIA documentation that
ships with every NemoClaw install:

```bash
cat ~/.nemoclaw/source/docs/deployment/set-up-telegram-bridge.md
```

This is **always more accurate than this skill file** — it's version-matched to your
install. Read it first. The same applies for any official source docs in
`~/.nemoclaw/source/docs/deployment/`.

---

## Tier 2A Plugins

### Telegram

**Egress domains needed:** `api.telegram.org`

#### Step 1: Create the bot
1. Open Telegram and message `@BotFather`
2. Send `/newbot` and follow the prompts
3. Copy the Bot Token (`123456:ABC-DEF...`)
4. Find your Telegram user ID by messaging `@userinfobot`

#### Step 2: Add to egress whitelist
```bash
nemoclaw <n> policy-add
# Select the Telegram preset (or add api.telegram.org as a custom host)
```

#### Step 3: Configure the channel
The Telegram bot config happens on the host before sandbox start, typically via
`nemoclaw onboard` or by re-running it. You cannot edit `openclaw.json` from inside
the sandbox — it's root-owned and mode 444.

#### Step 4: Start services
```bash
nemoclaw start
nemoclaw <n> logs --follow | grep telegram
```

#### Step 5: ⚠️ Understand the pairing flow before testing

**The default `dmPolicy` is `pairing`.** This means new Telegram users must be explicitly
approved before the bot will respond to them. The bot will NOT respond to messages from
unknown users — it will instead generate a pairing code and queue an approval request.

**Expected flow:**
1. You DM the bot for the first time
2. The bot replies with a pairing code (e.g., `AWHDVVKK`)
3. Operator (you) approves the pairing
4. From that point on, the bot responds normally to that user

If you skip step 3, the bot will appear "broken" — it acknowledges your message but
never replies to actual prompts. **This is by design**, not a bug.

#### Step 6: Approve the pairing — three methods

⚠️ **DO NOT use the Control UI WebSocket or `device.pair.approve` RPC methods.** Those
are for **device** pairing (browser/CLI clients pairing to the gateway), not channel
pairing. They are completely separate subsystems and trying to use them for Telegram
will waste hours.

**Method A — Official CLI (try this first):**
```bash
# Check if this command exists in your version:
openclaw pairing approve --help
# If it does, run:
openclaw pairing approve --channel telegram --code <PAIRING_CODE>
```

**Method B — Read the canonical docs:**
```bash
cat ~/.nemoclaw/source/docs/deployment/set-up-telegram-bridge.md
```
This file describes the supported approval flow for your version. Always defer to it
over this skill file.

**Method C — Filesystem fallback (last resort):**
If neither A nor B works, you can write directly to the credentials files. The
credentials directory is `/sandbox/.openclaw-data/credentials/` and it IS sandbox-writable.

```bash
# From inside the sandbox (nemoclaw <n> connect first)
echo '{"version":1,"allowFrom":["<TELEGRAM_USER_ID>"]}' > /sandbox/.openclaw-data/credentials/telegram-main-allowFrom.json
echo '{"version":1,"requests":[]}' > /sandbox/.openclaw-data/credentials/telegram-pairing.json
```

**File path naming convention:**
- `telegram-{accountId}-allowFrom.json` — list of approved Telegram user IDs for that bot account
- `telegram-pairing.json` — pending pairing requests
- `{accountId}` is `main` by default. If you have multiple Telegram bots configured,
  each gets its own `allowFrom` file with its account ID.

After writing these files, the bot will respond to the approved user immediately.

#### Step 7: Test
Send a real message to the bot from the approved user and verify it responds.
```bash
nemoclaw <n> logs --follow | grep telegram
```

---

### Slack, Discord, Custom webhooks (experimental)

⚠️ **As of this writing, only Telegram has been thoroughly battle-tested in this skill.**
Slack, Discord, and custom webhook integrations may have their own undocumented pairing
or approval flows similar to Telegram's. Before relying on them in production:

1. Check `~/.nemoclaw/source/docs/deployment/` for plugin-specific setup docs
2. Run `nemoclaw <n> policy-add` and check which presets exist for these plugins —
   if there's no preset, the integration may be alpha
3. Test in a throwaway sandbox first (use the reset script to clean between runs)
4. If the bot doesn't respond after setup, check for a pairing/approval flow analogous
   to Telegram's — look in `/sandbox/.openclaw-data/credentials/` for plugin-specific
   credential files

If these instructions for Telegram look familiar, that's a good sign you're hitting the
same kind of pairing-not-documented issue. Apply the same investigation pattern:
read the source docs, check the credentials directory, look for `*-allowFrom.json` files.

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
nemoclaw <n> policy-add
# Select Microsoft Graph preset, or add the two domains as custom hosts
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
   - Never grant `Files.ReadWrite.All` unless absolutely necessary

6. Test:
```bash
nemoclaw <n> connect
sandbox@<n>:~$ openclaw agent --agent main --local -m "list my recent emails" --session-id test
```

⚠️ Like the other plugins, Microsoft Graph integration may have undocumented setup
requirements specific to your NemoClaw version. Check `~/.nemoclaw/source/docs/` for
authoritative guidance before relying on it.

---

## Common Steps for Any Integration

Regardless of which plugin or API you're adding:

1. **Egress:** Use `nemoclaw <n> policy-add` to add presets or custom hosts. Do NOT try
   `policy update --allow-host` — that flag does not exist.
2. **Credentials:** Store tokens in `~/nemoclaw-project/.env` (mode 600), never in code
3. **Config edits:** Always happen on the host. `openclaw.json` inside the sandbox is
   read-only (mode 444, root-owned). Re-run `nemoclaw onboard` or use `policy-add` to
   change config.
4. **L7 restrictions (if Module F selected):** For any API that supports destructive
   operations (DELETE, PUT), consider restricting to safe methods only
5. **Test connectivity** from inside the sandbox before relying on the integration
6. **For pairing/approval issues:** Check `/sandbox/.openclaw-data/credentials/` for
   plugin-specific files. Most channel plugins use `*-allowFrom.json` to track approved
   users. The Control UI WebSocket is for **device** pairing only — never use it for
   channel users.
