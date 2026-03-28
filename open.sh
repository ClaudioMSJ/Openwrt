#!/bin/sh

#================================================================
# CONFIGURAÇÃO OTIMIZADA DO SISTEMA E REDE VIA UCI
#================================================================
uci batch <<EOF
# ---- Desativar IPv6 ----
delete network.wan6
delete network.globals.ula_prefix
set network.lan.ipv6='0'
set network.wan.ipv6='0'
set dhcp.lan.dhcpv6='disabled'
set dhcp.lan.ra='disabled'
set dhcp.lan.ndp='disabled'
set firewall.@defaults[0].disable_ipv6='1'

# ---- Desativar LEDs Azuis ----
add system led
set system.@led[-1].name='Blue'
set system.@led[-1].sysfs='blue:status'
set system.@led[-1].trigger='none'
set system.@led[-1].default='0'

# ---- Horário e Configurações de Log ----
set system.@system[0].zonename='America/Sao_Paulo'
set system.@system[0].timezone='<-03>3'
set system.@system[0].log_size='16'
set system.@system[0].log_rotated='3'

# ---- Ativar Flow Offloading ----
set firewall.@defaults[0].flow_offloading='1'
set firewall.@defaults[0].flow_offloading_hw='1'

# ---- Desativar Regra Allow-Ping ----
set firewall.@rule[1].enabled='0'

# ---- Forçar DNS Local (Bloquear DNS do Provedor) ----
set network.wan.peerdns='0'
set network.wan.dns='127.0.0.1'
delete dhcp.@dnsmasq[0].server
add_list dhcp.@dnsmasq[0].server='127.0.0.1#5053'
add_list dhcp.@dnsmasq[0].server='127.0.0.1#5054'

# ---- Otimizar Dnsmasq ----
set dhcp.@dnsmasq[0].noresolv='1'
set dhcp.@dnsmasq[0].min_cache_ttl='3600'
set dhcp.@dnsmasq[0].max_cache_ttl='86400'
set dhcp.@dnsmasq[0].boguspriv='1'
set dhcp.@dnsmasq[0].localservice='1'
set dhcp.@dnsmasq[0].confdir='/etc/dnsmasq.d'

# ---- Bloquear Requisições DNS Diretas na WAN (IPv4) ----
add firewall rule
set firewall.@rule[-1].name='Block-DNS-Direct'
set firewall.@rule[-1].src='lan'
set firewall.@rule[-1].dest='wan'
set firewall.@rule[-1].proto='tcp udp'
set firewall.@rule[-1].dest_port='53'
set firewall.@rule[-1].target='REJECT'
set firewall.@rule[-1].family='ipv4'
EOF

#================================================================
# CRIAR DIRETÓRIO PARA CONFIGS DO DNSMASQ
#================================================================
mkdir -p /etc/dnsmasq.d

#================================================================
# SCRIPT DE ADBLOCK
#================================================================
cat <<'EOF' > /root/adblock.sh
#!/bin/sh
URL="https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/dnsmasq/light.txt"
CONF="/etc/dnsmasq.d/blacklist.conf"
TMP="/tmp/adblock_list.txt"
while ! ping -c1 -W1 8.8.8.8 >/dev/null 2>&1; do sleep 1; done
wget -qO- "$URL" | sed '/^\s*#/d;/^\s*$/d' > "$TMP" && [ -s "$TMP" ] && mv "$TMP" "$CONF" && /etc/init.d/dnsmasq restart
EOF

# Tornar o script de adblock executável
chmod +x /root/adblock.sh

#================================================================
# AGENDAMENTO DO SCRIPT DE ADBLOCK
#================================================================
# Executar na inicialização do roteador (após 30s)
sed -i -e "/^exit 0/i sleep 30 && sh /root/adblock.sh &\n" /etc/rc.local

# Adicionar tarefa ao Cron para executar diariamente às 05:00
echo "0 5 * * * sh /root/adblock.sh" >> /etc/crontabs/root
/etc/init.d/cron enable
/etc/init.d/cron start

#================================================================
# SALVAR E REINICIAR
#================================================================
uci commit
echo "Configurações aplicadas com sucesso! O roteador será reiniciado."
sleep 2
reboot