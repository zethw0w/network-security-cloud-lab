# Lab Network Security & Cloud Essentials

Laboratório pronto para a atividade, mais o relatório técnico em LaTeX (abnTeX2 / ABNT NBR 14724).

- Duas VMs Ubuntu 22.04 (`servidor` e `cliente`) numa **rede interna** do VirtualBox (`lab-net`), isolada do host e da LAN.
- Os scripts de cada fase executam os passos do enunciado e **gravam cada comando, a saída e o código de saída** em `relatorio/evidencias/`.
- O relatório insere essas evidências automaticamente. Enquanto um arquivo de evidência não existe, aparece uma caixa vermelha "EVIDÊNCIA PENDENTE".

```
network-security-cloud-lab/
├── Vagrantfile              # as duas VMs
├── rodar_lab.ps1            # executa as fases 1–4 em ordem
├── compilar_relatorio.ps1   # gera relatorio/main.pdf via Docker (TeX Live)
├── lab/                     # scripts das fases + política IAM (politica-lab-rw.json)
└── relatorio/               # main.tex, capitulos/, anexos/, evidencias/, figuras/
```

## 1. Pré-requisitos

- VirtualBox (já instalado nesta máquina: 7.2.6).
- Vagrant:

```powershell
winget install --id Hashicorp.Vagrant -e
```

Feche e reabra o terminal depois da instalação do Vagrant.

## 2. Rodar o laboratório

Abra o PowerShell na pasta do projeto.

```powershell
vagrant up
```

```powershell
.\rodar_lab.ps1
```

- `vagrant up` cria e provisiona as duas VMs (na primeira vez baixa a box `bento/ubuntu-22.04`).
- `rodar_lab.ps1` roda todas as fases. A varredura completa do nmap depois do firewall leva cerca de 1,5 min.
- Para rodar só algumas fases: `.\rodar_lab.ps1 -Fase 3,4`.

No fim, as Fases 4 imprimem um placar. O esperado é **13 testes no servidor e 5 no cliente, todos com PASSOU**.

Ordem e o que cada script gera: Anexo A do relatório (`relatorio/anexos/anexos.tex`).

## 3. Gerar o PDF

O script gera **dois PDFs**:

- `relatorio/main.pdf`: versão compacta para entrega (**27 páginas**). Usa resumos das saídas longas e traz só a tabela dos scripts.
- `relatorio/main-completo.pdf`: versão completa (**52 páginas**), com todas as saídas e o código-fonte dos scripts.

Com Docker (local):

```powershell
.\compilar_relatorio.ps1
```

Com Overleaf:

1. Compacte o **conteúdo** da pasta `relatorio/` num zip e envie como novo projeto.
2. O compilador é LuaLaTeX; o `latexmkrc` já configura isso.

Depois, complete os trechos em vermelho `[PREENCHER: ...]`: nome, instituição, professor, cidade e comentários pessoais. Salve os prints pedidos em `relatorio/figuras/` com os nomes indicados no Anexo B.

## 4. Decisões e pontos de atenção

- **MinIO → SILO.**
  - O MinIO open-source foi arquivado e o download oficial responde `410 Gone`; a imagem `minio/minio` do Docker Hub está sem tags.
  - A Fase 3 usa o [SILO](https://github.com/pgsty/silo), fork comunitário mantido, com a mesma API S3 e de admin. O cliente é o `mcli`, com os mesmos comandos do `mc`.
  - Versão fixada `RELEASE.2026-11-12`, com SHA-256 conferido no script.
- **SSH na Fase 2 × Fase 4.**
  - O enunciado pode ser lido como "SSH só a partir do cliente", mas a Fase 4 exige que **só a 8080** esteja acessível a partir do cliente. O padrão segue a Fase 4.
  - Para a outra leitura, rode `fase2_firewall.sh` e `fase4_cliente.sh` com `PERMITIR_SSH_CLIENTE=1`. Confirme com o professor.
- **Exceção de gerência do Vagrant.**
  - O `ufw` libera a porta 22 só no adaptador NAT e só vindo do host (10.0.2.2); sem isso o `vagrant ssh` para de funcionar. Essa regra não é alcançável pela rede do lab.
  - Para desligar: `LAB_VAGRANT_MGMT=0`.
- **Testes anônimos no bucket.** Rodam no próprio servidor (API local), porque o firewall bloqueia a 9000 para o cliente. Isso separa o teste do IAM do teste do firewall.
- **Segredos.** As credenciais do SILO são geradas na VM (`/etc/silo-lab.env` e `/root/.silo-lab-user`, modo 600) e aparecem mascaradas nas evidências (`$LAB_SECRET`).
- **Arquitetura.** Os pacotes fixados são amd64. Em host ARM, ajuste `fase3_silo.sh`.

## 5. Sem Vagrant (VMs criadas à mão)

1. Crie duas VMs Ubuntu Server 22.04:
   - adaptador 1: NAT;
   - adaptador 2: Rede interna `lab-net`.
2. Copie a pasta do projeto para as duas.
3. Rode `sudo bash lab/provision.sh <servidor|cliente>` em cada VM.
4. Autorize o cliente no servidor com `ssh-copy-id`.
5. Rode os mesmos comandos do `rodar_lab.ps1` dentro das VMs, com `LAB_IFACE=<interface do adaptador 2>` e `LAB_VAGRANT_MGMT=0`.
6. Junte os arquivos de `relatorio/evidencias/` das duas VMs numa pasta só.

## 6. Limpeza

```powershell
vagrant destroy -f
```

## O que foi testado e o que não foi

Testado em dois containers Ubuntu 22.04 com systemd, numa rede Docker 192.168.50.0/24, com o SILO real instalado:

- Fase 1: ping, ssh por chave, cálculo das sub-redes e teste de segmentação.
- Fase 2: completa. Antes do firewall: 22 e 8080 abertas. Depois: só 8080 aberta, 65.534 portas filtradas.
- Fase 3: completa. O bucket público deu HTTP 200 em leitura, listagem e escrita anônimas. O privado deu HTTP 403.
- Fase 4: 13/13 testes no servidor e 5/5 no cliente.
- Nenhum segredo aparece nas evidências.
- O relatório compila sem referências indefinidas.

Depois, executado de ponta a ponta nas VMs reais (Vagrant 2.4.9 + VirtualBox 7.2.6, box `bento/ubuntu-22.04` v202510.26.0, interface do lab `eth1`) em 2026-11-19: todas as fases sem erro, 24 testes com PASSOU e nenhum FALHOU. As evidências em `relatorio/evidencias/` são dessa execução.

Re-execução: `.\rodar_lab.ps1` pode ser rodado de novo. A Fase 1 desliga o firewall e para o SILO para voltar ao estado inicial do enunciado.
