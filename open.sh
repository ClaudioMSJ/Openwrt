#!/bin/sh

uci_batch() { uci batch <<'EOF'
# ==== IPv6 Off ====
delete network.wan6
set network.lan.ipv6='0'
set network.wan.ipv6='0'
set dhcp.lan.dhcpv6='disabled'
set dhcp.lan.ra='disabled'
set dhcp.lan.ndp='disabled'
set firewall.@defaults[0].disable_ipv6='1'

# ==== Hora / Log ====
set system.@system[0].zonename='America/Sao Paulo'
set system.@system[0].timezone='<-03>3'
set system.@system[0].log_size='16'
set system.@system[0].log_rotated='3'

# ==== Flow Offload & Ping ====
set firewall.@defaults[0].flow_offloading='1'
set firewall.@defaults[0].flow_offloading_hw='1'
set firewall.@rule[1].enabled='0'

# ==== DNS + DoH ====
set network.wan.peerdns='0'
set network.wan.dns='127.0.0.1'
delete https-dns-proxy.@https-dns-proxy[0]
set https-dns-proxy.dns=https-dns-proxy
set https-dns-proxy.dns.bootstrap_dns='1.1.1.1,1.0.0.1'
set https-dns-proxy.dns.resolver_url='https://cloudflare-dns.com/dns-query'
set https-dns-proxy.dns.listen_addr='127.0.0.1'
set https-dns-proxy.dns.listen_port='5053'

# ==== Dnsmasq ====
set dhcp.@dnsmasq[0].noresolv='1'
delete dhcp.@dnsmasq[0].server
set dhcp.@dnsmasq[0].server='127.0.0.1#5053'
set dhcp.@dnsmasq[0].dhcpv6='disabled'

# ==== Bloqueio DNS IPv4 ====
add firewall rule
set firewall.@rule[-1].name='Block-DNS-Direct'
set firewall.@rule[-1].src='lan'
set firewall.@rule[-1].dest='wan'
set firewall.@rule[-1].proto='tcp udp'
set firewall.@rule[-1].dest_port='53'
set firewall.@rule[-1].target='REJECT'
set firewall.@rule[-1].family='ipv4'
EOF
}

# ==== Aplicar todas as configs UCI ====
uci_batch

# ==== Desativar LEDs Azuis ====
for led in /sys/class/leds/*blue*; do echo none >$led/trigger; echo 0 >$led/brightness; done

# ==== Adblock Script ====
cat <<'EOF' > /root/adblock.sh
#!/bin/sh
URL="https://raw.githubusercontent.com/sjhgvr/oisd/refs/heads/main/dnsmasq_small.txt"
until ping -c1 -W1 8.8.8.8 >/dev/null; do sleep 1; done
wget -q "$URL" -O - | sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' > /etc/dnsmasq.conf
/etc/init.d/dnsmasq restart
EOF
chmod +x /root/adblock.sh

# ==== rc.local & Cron ====
for cmd in \
    "sleep 30 && sync && sh /root/adblock.sh" \
    "sleep 30 && echo 3 > /proc/sys/vm/drop_caches"
do grep -qxF "$cmd" /etc/rc.local || sed -i "/^exit 0/i $cmd" /etc/rc.local; done
(crontab -l 2>/dev/null; echo '0 6 * * * sync && echo 3 > /proc/sys/vm/drop_caches') | crontab -
(crontab -l 2>/dev/null; echo '0 5 * * * sh /root/adblock.sh') | crontab -
service cron restart

# ==== Salvar & Reboot ====
uci commit && reboot
