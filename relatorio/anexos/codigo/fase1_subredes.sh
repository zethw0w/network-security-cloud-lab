#!/usr/bin/env bash
# Fase 1 — Cálculo da divisão de 192.168.50.0/24 em sub-redes /26 (não precisa de root).
source "$(dirname "$0")/comum.sh"
ARQ="fase1_subredes.txt"
titulo "$ARQ" "Cálculo de sub-redes (python3 ipaddress)"

python3 - <<'PY' | tee -a "$EVID_DIR/$ARQ"
import ipaddress as ip

rede = ip.ip_network("192.168.50.0/24")
m26 = ip.ip_network("0.0.0.0/26").netmask
bits = ".".join(f"{int(o):08b}" for o in str(m26).split("."))

print(f"Rede original : {rede}  máscara {rede.netmask}  hosts úteis: {rede.num_addresses - 2}")
print("Nova máscara  : /26 = 24 bits de rede + 2 bits emprestados do host")
print(f"               {m26} = {bits}")
print("Sub-redes     : 2^2 = 4 | endereços por sub-rede: 2^6 = 64 | hosts úteis: 64 - 2 = 62")
print()
print(f"{'Sub-rede':<9}{'Endereço de rede':<20}{'1º host':<16}{'Último host':<16}{'Broadcast':<16}Hosts")
for nome, s in zip("ABCD", rede.subnets(new_prefix=26)):
    hosts = list(s.hosts())
    print(f"{nome:<9}{str(s):<20}{str(hosts[0]):<16}{str(hosts[-1]):<16}{str(s.broadcast_address):<16}{len(hosts)}")
print()
print("Uso no laboratório: A (192.168.50.0/26) = servidor .10 e cliente .20;")
print("                    B (192.168.50.64/26) = teste de segmentação (cliente em .70).")
print("Observação: dividir a /24 em exatamente duas metades exigiria /25 (126 hosts cada);")
print("            as duas /26 usadas ocupam metade do espaço e deixam C e D livres.")
PY
