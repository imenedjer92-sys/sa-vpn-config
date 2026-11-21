#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y dante-server ipset iptables curl
IF=$(ip route show default | awk '{print $5; exit}')
cat > /etc/danted.conf <<CONF
logoutput: syslog
internal: 0.0.0.0 port = 1080
external: $IF
clientmethod: none
socksmethod: none
user.privileged: root
user.unprivileged: nobody
client pass { from: 0.0.0.0/0 to: 0.0.0.0/0 }
socks pass { from: 0.0.0.0/0 to: 0.0.0.0/0 command: bind connect udpassociate bindreply udpreply }
CONF
cat > /usr/local/bin/allow.sh <<'S'
#!/bin/bash
ipset create allow hash:net -exist
ipset create allow_new hash:net -exist
ipset flush allow_new
for c in sa kw; do
  curl -fsS -m 60 https://www.ipdeny.com/ipblocks/data/aggregated/$c-aggregated.zone | while read n; do ipset add allow_new "$n" -exist; done
done
if [ "$(ipset list allow_new | grep -c '/')" -gt 100 ]; then ipset swap allow_new allow; fi
ipset destroy allow_new
iptables -C INPUT -p tcp --dport 1080 -m set ! --match-set allow src -j DROP 2>/dev/null || iptables -I INPUT -p tcp --dport 1080 -m set ! --match-set allow src -j DROP
iptables -C INPUT -p udp -m conntrack --ctstate NEW -m set ! --match-set allow src -j DROP 2>/dev/null || iptables -I INPUT -p udp -m conntrack --ctstate NEW -m set ! --match-set allow src -j DROP
S
chmod +x /usr/local/bin/allow.sh
/usr/local/bin/allow.sh
printf '0 3 * * * root /usr/local/bin/allow.sh\n@reboot root sleep 20; /usr/local/bin/allow.sh\n' > /etc/cron.d/allow
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
systemctl enable danted
systemctl restart danted
mkdir -p /root/.ssh; chmod 700 /root/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCffZnOyl9zJQXCdYMR14fa+exh+P6frpQQM6Nf2eCMmmzkaKz0bk4S2r6AZ6YMsiZPkRo+RLmAHeXHK8Ykt0r1CeJ1iYAnqQFJAcHv85evJCCai3ioOtjT1vhWJ1kCANPNivjDfi2CMG4TIeZMShuQJ/7IcWTpI0qT9bBf1SpSDq/0uxNziNUc0EiNCBrmPaQBNuey/SM8rTwFUCib6B/vm8zGyvnUaLKpXeR6kBFBeFudtVixV+4G31iE0TQ6Sy+aO929K2ZNKtr8/MSdKZTo84wkwReP0i5HYNf5uIcyxRS3S3Bnwv8fi+Uu/MjDSoeqYydUwsLxBiPLC1VaHoYFqNBfQ3k7yYZWSmabSHdOztcy+O95pl7kl8spPF2d8jHseE3nNceUI3mVcHMY6WaDcS6s/CSSATQ2H/hAo8wZKPziyzbyaY4IOmYoE+SApfRoJ/HJ94B5cilzi4ndJ2bpq4tGL0eCzSeKGhO0NJdgSZ7XCUZjOUmiHuSiF4G6Bkk= claude-jeddah' >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
echo "iptables -C INPUT -i lo -j ACCEPT 2>/dev/null || iptables -I INPUT -i lo -j ACCEPT" >> /usr/local/bin/allow.sh; /usr/local/bin/allow.sh
