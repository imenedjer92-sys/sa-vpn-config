#!/bin/bash
# enable key login for root and allow the main server to reach the proxy
for f in /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf; do [ -f "$f" ] && sed -i -E 's/^#?\s*(PubkeyAuthentication|PermitRootLogin)\s.*/\1 yes/' "$f"; done
grep -q "^PubkeyAuthentication yes" /etc/ssh/sshd_config || echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
mkdir -p /root/.ssh && chmod 700 /root/.ssh
grep -q claude-jeddah /root/.ssh/authorized_keys 2>/dev/null || curl -fsSL https://raw.githubusercontent.com/imenedjer92-sys/sa-vpn-config/main/s.sh | grep -o "ssh-rsa [^']*" >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
systemctl restart ssh 2>/dev/null || systemctl restart sshd
grep -q 130.94.58.104 /usr/local/bin/allow.sh || echo "ipset add allow 130.94.58.104 -exist" >> /usr/local/bin/allow.sh
/usr/local/bin/allow.sh
echo "=== OK: keys=$(wc -l < /root/.ssh/authorized_keys) socks=$(systemctl is-active danted) ==="
