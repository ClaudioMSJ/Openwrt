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
uci add system led
uci set system.@led[-1].name='Blue'
uci set system.@led[-1].sysfs='blue:status'
uci set system.@led[-1].trigger='none'
uci set system.@led[-1].default='0'

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

# ==== Bloquear DNS Provedor ====
uci set network.wan.peerdns='0'
uci set network.wan.dns='127.0.0.1'

# ==== Dnsmasq Config ====
uci set dhcp.@dnsmasq[0].noresolv='1'
uci set dhcp.@dnsmasq[0].cachesize='2000'
uci set dhcp.@dnsmasq[0].min_cache_ttl='120'
uci set dhcp.@dnsmasq[0].max_cache_ttl='86400'
uci set dhcp.@dnsmasq[0].boguspriv='1'
uci set dhcp.@dnsmasq[0].filterwin2k='1'
uci set dhcp.@dnsmasq[0].localservice='1'
uci set dhcp.@dnsmasq[0].allservers='1'
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
cat <<'EOF'>/root/adblock.sh
#!/bin/sh
URL=https://raw.githubusercontent.com/sjhgvr/oisd/refs/heads/main/dnsmasq2_small.txt
while ! ping -c1 -W1 8.8.8.8 >/dev/null; do sleep 1; done
wget -qO- "$URL" | sed '/^\s*#/d;/^\s*$/d' > /etc/dnsmasq.conf
/etc/init.d/dnsmasq restart
EOF
chmod +x /root/adblock.sh

# ==== rc.local sem sobrescrever completamente ====
grep -qxF 'sh /root/adblock.sh' /etc/rc.local || sed -i '/^exit 0/i sleep 30 && sh /root/adblock.sh' /etc/rc.local
grep -qxF 'echo 3 > /proc/sys/vm/drop_caches' /etc/rc.local || sed -i '/^exit 0/i sleep 60 && sync && echo 3 > /proc/sys/vm/drop_caches' /etc/rc.local

# ==== Cron Jobs ====
(crontab -l 2>/dev/null; echo '0 6 * * * sync && echo 3 > /proc/sys/vm/drop_caches') | crontab -
(crontab -l 2>/dev/null; echo '0 5 * * * sh /root/adblock.sh') | crontab -
service cron restart

# ==== Salvar Configs ====
uci commit

reboot
