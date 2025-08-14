#!/bin/sh

# ==== Desativar IPv6 ====
uci delete network.wan6
uci set network.lan.ipv6='0'
uci set network.wan.ipv6='0'
uci set dhcp.lan.dhcpv6='disabled'
uci set dhcp.lan.ra='disabled'
uci set dhcp.lan.ndp='disabled'
uci set firewall.@defaults[0].disable_ipv6='1'

# ==== Desativar LEDs Azuis ====
for led in $(ls /sys/class/leds | grep blue); do
    echo none > /sys/class/leds/$led/trigger
    echo 0 > /sys/class/leds/$led/brightness
done

# ==== Horário e Log ====
uci set system.@system[0].zonename='America/Sao Paulo'
uci set system.@system[0].timezone='<-03>3'
uci set system.@system[0].log_size='16'
uci set system.@system[0].log_rotated='3'

# ==== Flow Offloading (MT7981 suporta) ====
uci set firewall.@defaults[0].flow_offloading='1'
uci set firewall.@defaults[0].flow_offloading_hw='1'

# ==== Desativar Allow-Ping ====
uci set firewall.@rule[1].enabled='0'

# ==== DNS Manual + DoH Cloudflare ====
uci set network.wan.peerdns='0'
uci set network.wan.dns='127.0.0.1'

# Limpa config antiga do https-dns-proxy
while uci -q delete https-dns-proxy.@https-dns-proxy[0]; do :; done
uci set https-dns-proxy.dns="https-dns-proxy"
uci set https-dns-proxy.dns.bootstrap_dns="1.1.1.1,1.0.0.1"
uci set https-dns-proxy.dns.resolver_url="https://cloudflare-dns.com/dns-query"
uci set https-dns-proxy.dns.listen_addr="127.0.0.1"
uci set https-dns-proxy.dns.listen_port="5053"

# ==== Dnsmasq Config ====
uci set dhcp.@dnsmasq[0].noresolv='1'
uci delete dhcp.@dnsmasq[0].server
uci set dhcp.@dnsmasq[0].server='127.0.0.1#5053'
uci set dhcp.@dnsmasq[0].dhcpv6='disabled'

# ==== Bloqueio DNS Direto (somente IPv4) ====
uci add firewall rule
uci set firewall.@rule[-1].name='Block-DNS-Direct'
uci set firewall.@rule[-1].src='lan'
uci set firewall.@rule[-1].dest='wan'
uci set firewall.@rule[-1].proto='tcp udp'
uci set firewall.@rule[-1].dest_port='53'
uci set firewall.@rule[-1].target='REJECT'
uci set firewall.@rule[-1].family='ipv4'

# ==== Script Adblock ====
cat << 'EOF' > /root/adblock.sh
#!/bin/sh
URL="https://raw.githubusercontent.com/sjhgvr/oisd/refs/heads/main/dnsmasq_small.txt"
until ping -c1 -W1 8.8.8.8 >/dev/null 2>&1; do sleep 1; done
wget -q "$URL" -O - | sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' > /etc/dnsmasq.conf
/etc/init.d/dnsmasq restart
EOF
chmod +x /root/adblock.sh

# ==== rc.local sem sobrescrever completamente ====
grep -qxF 'sh /root/adblock.sh' /etc/rc.local || sed -i '/^exit 0/i sleep 30 && sync && sh /root/adblock.sh' /etc/rc.local
grep -qxF 'echo 3 > /proc/sys/vm/drop_caches' /etc/rc.local || sed -i '/^exit 0/i sleep 30 && echo 3 > /proc/sys/vm/drop_caches' /etc/rc.local

# ==== Cron Jobs ====
(crontab -l 2>/dev/null; echo '0 6 * * * sync && echo 3 > /proc/sys/vm/drop_caches') | crontab -
(crontab -l 2>/dev/null; echo '0 5 * * * sh /root/adblock.sh') | crontab -
service cron restart

# ==== Salvar Configs ====
uci commit

reboot
