# Phase 1: Security Hardening

## Overview
Transition the Linux server from default SSH on port 22 to a hardened configuration.
This is the highest-risk phase — an error here can lock you out permanently.

## Prerequisites
- Active SSH session on port 22
- Access to your cloud provider's firewall/network rules (or iptables for bare metal)
- Know your public IP address (use `curl ifconfig.me`)

## Steps

### 1.1 Install UFW (do NOT enable yet)
```bash
sudo apt update && sudo apt install -y ufw
sudo ufw allow 2222/tcp    # new SSH port
sudo ufw allow 80/tcp      # web gateway (if needed)
sudo ufw allow 443/tcp     # HTTPS (if needed)
```
**WARNING:** Do NOT run `sudo ufw enable` yet. Enabling before SSH is moved will lock you out.

### 1.2 Disable systemd ssh.socket
Modern Ubuntu uses systemd socket activation which overrides sshd_config port settings.
This is the #1 cause of "I changed the port but it's still on 22" issues.

```bash
sudo systemctl disable --now ssh.socket
sudo systemctl stop ssh.socket
```

Verify it's gone:
```bash
systemctl status ssh.socket   # should show "inactive (dead)"
```

### 1.3 Configure sshd_config
```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

sudo sed -i 's/^#\?Port .*/Port 2222/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
```

Verify the changes:
```bash
grep -E '^(Port|PermitRootLogin|PasswordAuthentication)' /etc/ssh/sshd_config
```
Expected output:
```
Port 2222
PermitRootLogin no
PasswordAuthentication no
```

### 1.4 Restart SSH service
```bash
sudo systemctl restart ssh
```

### 1.5 Verify from a SECOND terminal (critical!)
Open a new terminal window and test:
```bash
ssh -i <key.pem> -p 2222 ubuntu@<public-ip>
```

**Only proceed if this succeeds.** If it fails, you still have your original session to fix things.

### 1.6 Enable UFW
Only after confirming SSH on 2222 works:
```bash
sudo ufw enable
sudo ufw status verbose
```

### 1.7 Update Cloud Firewall / Perimeter Rules

You MUST also update the firewall at your cloud provider level (in addition to UFW on the host).
Remove the old port 22 rule and add port 2222 restricted to your IP.

**AWS EC2:**
1. EC2 Console → Security Groups → your instance's SG
2. Remove inbound rule for port 22
3. Add: Custom TCP, Port 2222, Source: `<your-ip>/32`

**Azure VM:**
1. Azure Portal → VM → Networking → Inbound port rules
2. Remove port 22 rule
3. Add: Port 2222, Protocol TCP, Source: `<your-ip>/32`

**Hostinger / DigitalOcean / Other VPS:**
1. Open provider's firewall panel (if available)
2. Remove port 22, add port 2222 restricted to your IP
3. If no cloud firewall exists, UFW alone handles it — ensure it's enabled

**Bare Metal:**
UFW is your only perimeter. Ensure it is enabled and correct.

Ensure ports 80 and 443 are open if web gateway is needed.

### 1.8 Verify old port is closed
```bash
sudo ss -tlnp | grep :22    # should show nothing
sudo ss -tlnp | grep :2222  # should show sshd
```

## VSCode SSH Config Update
If using VSCode Remote SSH, update `~/.ssh/config`:
```
Host nemoclaw-server
    HostName <public-ip-or-elastic-ip>
    User ubuntu
    Port 2222
    IdentityFile ~/.ssh/<key.pem>
```

## Rollback Plan
If locked out:
- **AWS:** Use EC2 Instance Connect, Serial Console, or detach/reattach root volume via another instance
- **Azure:** Use Serial Console or Run Command in Azure Portal
- **Hostinger/DO:** Use provider's web console / VNC access
- **Bare metal:** Physical or IPMI/iLO/iDRAC console access
