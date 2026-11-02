# Relatório técnico — Diagnóstico de segurança da nuvem Azure

**Cliente:** Nuvelo Eventos (fictício) · **Data:** 02/11/2026 · **Responsável:** André Soler
**Referência principal:** CIS Microsoft Azure Foundations Benchmark v6.0

---

## 1. Escopo e método

### Escopo

- Uma assinatura Azure, com os recursos do grupo `rg-nuvelo-prod` e as configurações da própria assinatura.
- Áreas analisadas: permissões na assinatura (RBAC) e identidades gerenciadas, rede, armazenamento de arquivos, banco de dados, cofre de senhas, registro de atividades e Microsoft Defender for Cloud.

### Método

1. **Acesso somente leitura.** Toda a análise foi feita com uma identidade de serviço com papel Reader na assinatura. Antes de começar, foi confirmado que essa identidade não consegue criar nem alterar recursos.
2. **Varredura automatizada** com duas ferramentas independentes: Prowler (open source) e Microsoft Defender for Cloud.
3. **Revisão manual** das atribuições de papéis, que nenhuma das duas ferramentas cobre por completo.
4. **Validação** de cada achado com comandos do Azure CLI, executados com a mesma identidade de leitura. As saídas foram registradas, com data e hora, nos arquivos da pasta `evidencias/`.
5. **Classificação** pelo impacto no negócio da Nuvelo, considerando que o ambiente armazena dados pessoais de participantes de eventos.

### Escala de gravidade

| Gravidade | Critério |
| --- | --- |
| **Crítico** | Exploração simples e impacto direto: vazamento de dados pessoais ou controle do ambiente |
| **Alto** | Expõe o ambiente ou impede a investigação de um incidente |
| **Médio** | Enfraquece a defesa, mas depende de outra falha para causar dano |

### Resultado da varredura

| Etapa | Volume |
| --- | --- |
| Checagens do Prowler | 107 regras avaliadas, 79 reprovadas |
| Reprovações no escopo da Nuvelo | 62 regras |
| Recomendações não atendidas no Defender | 26 |
| **Achados consolidados e validados** | **17** |

---

## 2. Limitações

- **Entra ID fora do escopo.** Usuários, grupos, MFA e políticas de acesso condicional do diretório não foram avaliados. A identidade de leitura não tinha permissões no Microsoft Graph.
- **Acesso elevado na raiz do diretório.** Existe uma atribuição do papel User Access Administrator no escopo raiz (`/`), feita por um administrador do diretório e herdada pela assinatura. Está fora do controle da Nuvelo e do escopo contratado, mas o controle CIS 5.3.3 recomenda remover esse tipo de acesso assim que deixa de ser usado. Recomenda-se levar o ponto ao administrador do diretório.
- **Avaliação de configuração, não de exploração.** Não foram feitos testes de invasão, testes no código da aplicação nem tentativas de acesso com credenciais. A única ação externa foi baixar um arquivo de teste sem autenticação, para comprovar o achado A-01.
- **Fotografia de um momento.** O resultado reflete o ambiente em 02/11/2026.

---

## 3. Achados

### Resumo

| ID | Achado | Gravidade | Prazo |
| --- | --- | --- | --- |
| A-01 | Arquivos das agências legíveis sem login | Crítico | 48 horas |
| A-02 | Banco aceita conexão de qualquer IP | Crítico | 48 horas |
| A-03 | Integração com controle total da assinatura | Crítico | 48 horas |
| A-04 | SSH e RDP liberados para a internet | Alto | 48 horas |
| A-05 | Storage aceita tráfego sem criptografia | Alto | 48 horas |
| A-06 | Storage aberto a qualquer rede e com chaves compartilhadas | Alto | 30 dias |
| A-07 | Banco sem auditoria | Alto | 30 dias |
| A-08 | Cofre sem proteção contra purga | Alto | 30 dias |
| A-09 | Sem logs de diagnóstico | Alto | 30 dias |
| A-10 | Defender desligado nos serviços em uso | Alto | 30 dias |
| A-11 | Cofre aberto a qualquer rede | Médio | 90 dias |
| A-12 | Cofre com modelo de permissão antigo | Médio | 90 dias |
| A-13 | Senha do banco sem expiração | Médio | 30 dias |
| A-14 | Sem alertas para mudanças críticas | Médio | 90 dias |
| A-15 | Banco só com login por senha | Médio | 30 dias |
| A-16 | Arquivos sem proteção contra exclusão acidental | Médio | 30 dias |
| A-17 | Ninguém é avisado de alertas de segurança | Médio | 48 horas |

---

### A-01 — Arquivos das agências legíveis sem login

**Gravidade:** Crítico · **Recurso:** `stnuveloishadm` / container `uploads-agencias`
**Referência:** CIS 9.3.8 · Prowler `storage_blob_public_access_level_is_disabled` · Defender "Storage account public access should be disallowed"

**O que está errado.** A conta de armazenamento permite containers públicos, e o container onde as agências enviam arquivos está configurado com leitura anônima. Qualquer pessoa com o endereço de um arquivo consegue baixá-lo.

**Evidência** (`evidencias/A-01.txt`):

| Verificação | Resultado |
| --- | --- |
| Acesso público permitido na conta | `true` |
| Nível de acesso do container | `Blob` (leitura anônima) |
| Download de um arquivo sem autenticação | HTTP `200` (sucesso) |

O conteúdo do arquivo não foi registrado na evidência.

**Risco para a Nuvelo.** As listas de convidados contêm nome, e-mail e CPF. Endereços de arquivos vazam com facilidade: em e-mails encaminhados, históricos de navegador, mensagens. Um vazamento obriga a comunicar a ANPD e os titulares e expõe a empresa a sanções da LGPD.

**Correção.**

1. Mudar o container para privado.
2. Desativar o acesso público na conta, o que impede que alguém volte a abrir um container no futuro.
3. Para compartilhar um arquivo com uma agência, gerar um link SAS com prazo curto e somente leitura.

```hcl
resource "azurerm_storage_account" "arquivos" {
  # ...
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "uploads" {
  # ...
  container_access_type = "private"
}
```

---

### A-02 — Banco aceita conexão de qualquer IP

**Gravidade:** Crítico · **Recurso:** `sql-nuvelo-ishadm`
**Referência:** benchmark de banco de dados do CIS · Prowler `sqlserver_unrestricted_inbound_access` · Defender "Public network access on Azure SQL Database should be disabled"

**O que está errado.** O servidor aceita conexões pela internet, e a regra de firewall `liberar-tudo-temporario` permite todos os endereços, de `0.0.0.0` a `255.255.255.255`.

**Evidência** (`evidencias/A-02.txt`):

| Verificação | Resultado |
| --- | --- |
| Acesso de rede público | `Enabled` |
| Regra de firewall | `liberar-tudo-temporario`: `0.0.0.0` a `255.255.255.255` |

**Risco para a Nuvelo.** Servidores SQL expostos recebem tentativas automáticas de senha continuamente. Como o acesso é só por usuário e senha (ver A-15), uma senha descoberta dá acesso direto aos dados de agências e participantes.

**Correção.**

1. Remover a regra `liberar-tudo-temporario`.
2. Liberar apenas os endereços de saída da aplicação ou, preferencialmente, usar um endpoint privado e desligar o acesso público.

```hcl
resource "azurerm_mssql_server" "dados" {
  # ...
  public_network_access_enabled = false
}
# remover o recurso azurerm_mssql_firewall_rule "liberado"
```

---

### A-03 — Integração com controle total da assinatura

**Gravidade:** Crítico · **Recurso:** identidade gerenciada `id-nuvelo-integracao`
**Referência:** princípio do menor privilégio · **Identificado por revisão manual**; não foi detectado por nenhuma das ferramentas automatizadas

**O que está errado.** A identidade usada pela integração automática tem o papel Owner em toda a assinatura. Esse papel permite criar, alterar e apagar qualquer recurso e conceder acesso a outras pessoas.

**Evidência** (`evidencias/A-03.txt`): a lista de atribuições do papel Owner na assinatura contém o identificador da integração (`396341e1-…`), com tipo `ServicePrincipal`, ao lado do usuário dono da assinatura.

**Risco para a Nuvelo.** Quem conseguir usar essa identidade, por exemplo explorando uma falha na integração, passa a controlar o ambiente inteiro: pode copiar todos os dados, apagar os backups, criar recursos para mineração de criptomoeda na conta da Nuvelo ou trancar a empresa fora da própria nuvem.

**Correção.**

1. Levantar o que a integração realmente faz: ler e gravar no container de uploads e acessar o banco.
2. Atribuir apenas os papéis necessários, no escopo de cada recurso. Para os arquivos, Storage Blob Data Contributor na conta de armazenamento. Para o banco, um usuário do Entra ID dentro do banco com as permissões mínimas (depende do A-15).
3. Remover a atribuição de Owner.

```hcl
resource "azurerm_role_assignment" "integracao_arquivos" {
  scope                = azurerm_storage_account.arquivos.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.integracao.principal_id
  principal_type       = "ServicePrincipal"
}
# remover o recurso azurerm_role_assignment "integracao_owner"
```

---

### A-04 — SSH e RDP liberados para a internet

**Gravidade:** Alto · **Recurso:** `nsg-vm-legado`, associado à sub-rede `snet-vm-legado`
**Referência:** CIS 7.1 e 7.2 · Prowler `network_ssh_internet_access_restricted`, `network_rdp_internet_access_restricted` · não detectado pelo Defender

**O que está errado.** O grupo de segurança de rede permite conexões nas portas 22 (SSH) e 3389 (RDP) vindas de qualquer endereço da internet, e continua associado à sub-rede da máquina virtual antiga, que já foi removida.

**Evidência** (`evidencias/A-04.txt`): regras `permitir-ssh` (porta 22) e `permitir-rdp` (porta 3389), ambas com origem `Internet` e ação `Allow`; NSG associado à sub-rede.

**Risco para a Nuvelo.** Hoje não há máquina na sub-rede, mas qualquer VM criada ali amanhã já nasce exposta às portas mais atacadas da internet. O Defender só avalia essas portas em VMs existentes, por isso não sinalizou o problema.

**Correção.** Remover as duas regras, o NSG e a sub-rede, se não forem mais usados. Se uma VM voltar a ser necessária, liberar acesso administrativo apenas por Azure Bastion ou a partir de um IP fixo conhecido.

---

### A-05 — Storage aceita tráfego sem criptografia

**Gravidade:** Alto · **Recurso:** `stnuveloishadm`
**Referência:** CIS 9.3.4 · Prowler `storage_secure_transfer_required_is_enabled` · Defender "Secure transfer to storage accounts should be enabled"

**O que está errado.** A conta aceita conexões por HTTP, sem criptografia.

**Evidência** (`evidencias/A-05.txt`): HTTPS obrigatório `false`; download do arquivo de teste por `http://` com resposta `200`.

**Risco para a Nuvelo.** Arquivos transmitidos por HTTP podem ser lidos por qualquer pessoa no mesmo caminho de rede, como um Wi-Fi público usado por um funcionário de agência.

**Correção.**

```hcl
resource "azurerm_storage_account" "arquivos" {
  # ...
  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"
}
```

---

### A-06 — Storage aberto a qualquer rede e com chaves compartilhadas

**Gravidade:** Alto · **Recurso:** `stnuveloishadm`
**Referência:** CIS 9.3.2.2, 9.3.2.3, 9.3.1.3, 9.3.3.1, 9.3.1.2 · Prowler (5 regras de storage) · Defender "Storage accounts should restrict network access using virtual network rules", "Storage accounts should prevent shared key access"

**O que está errado.** A conta aceita conexões de qualquer rede, a regra padrão é permitir, e as chaves mestras da conta estão habilitadas, sem rotação registrada.

**Evidência** (`evidencias/A-06.txt`): rede pública `Enabled`; regra padrão `Allow`; chaves compartilhadas `True`.

**Risco para a Nuvelo.** Uma chave de conta dá acesso total a todos os arquivos, sem login e sem registro de quem a usou. Chaves desse tipo costumam acabar em código, arquivos de configuração e conversas.

**Correção.**

1. Mudar a regra padrão de rede para negar e liberar apenas a rede da aplicação.
2. Migrar a aplicação e a integração para autenticação pelo Entra ID (identidades gerenciadas) e então desativar as chaves compartilhadas.

```hcl
resource "azurerm_storage_account" "arquivos" {
  # ...
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}
```

A desativação das chaves deve vir **depois** da migração da aplicação, para não interromper o serviço.

---

### A-07 — Banco sem auditoria

**Gravidade:** Alto · **Recurso:** `sql-nuvelo-ishadm`
**Referência:** benchmark de banco de dados do CIS · Prowler `sqlserver_auditing_enabled`, `sqlserver_auditing_retention_90_days` · Defender "Auditing on SQL server should be enabled"

**O que está errado.** A auditoria do servidor está desligada.

**Evidência** (`evidencias/A-07.txt`): estado da política de auditoria `Disabled`.

**Risco para a Nuvelo.** Em caso de vazamento, não há como saber quem consultou quais dados nem quando. A LGPD exige que a comunicação de um incidente descreva os dados afetados, e sem auditoria a Nuvelo não conseguiria fazer isso com precisão.

**Correção.** Ativar a auditoria no nível do servidor, enviando para o Log Analytics (ver A-09), com retenção mínima de 90 dias.

---

### A-08 — Cofre sem proteção contra purga

**Gravidade:** Alto · **Recurso:** `kv-nuvelo-ishadm`
**Referência:** CIS 8.3.5 · Prowler `keyvault_recoverable` · Defender "Key vaults should have deletion protection enabled"

**O que está errado.** A exclusão reversível está ativa (o Azure a impõe em cofres novos), mas a proteção contra purga está desligada e a retenção é a mínima, de 7 dias.

**Evidência** (`evidencias/A-08.txt`): exclusão reversível `true`; proteção contra purga `null`; retenção `7` dias.

**Risco para a Nuvelo.** Sem proteção contra purga, alguém com acesso ao cofre pode apagar um segredo e eliminá-lo em definitivo na sequência. Um invasor faria isso para causar indisponibilidade; um funcionário, por engano.

**Correção.**

```hcl
resource "azurerm_key_vault" "cofre" {
  # ...
  purge_protection_enabled   = true
  soft_delete_retention_days = 90
}
```

A proteção contra purga não pode ser desligada depois de ativada. É o comportamento desejado.

---

### A-09 — Sem logs de diagnóstico

**Gravidade:** Alto · **Recurso:** assinatura e `kv-nuvelo-ishadm`
**Referência:** CIS 6.1.1.1, 6.1.1.2, 6.1.1.4 · Prowler `monitor_diagnostic_settings_exists`, `monitor_diagnostic_setting_with_appropriate_categories`, `keyvault_logging_enabled` · Defender "Diagnostic logs in Key Vault should be enabled"

**O que está errado.** O Activity Log da assinatura não é exportado, e o cofre não registra quem acessa os segredos.

**Evidência** (`evidencias/A-09.txt`): nenhuma configuração de diagnóstico na assinatura (`[]`) nem no cofre (`[]`).

**Risco para a Nuvelo.** O Activity Log registra quem criou, alterou ou apagou cada recurso, e o Azure o mantém por apenas 90 dias. Sem exportação, a investigação de um incidente descoberto tarde não teria dados.

**Correção.** Criar um workspace do Log Analytics e enviar para ele o Activity Log da assinatura e os eventos de auditoria do cofre (`AuditEvent`). Os mesmos destinos servem para a auditoria do banco (A-07).

---

### A-10 — Defender desligado nos serviços em uso

**Gravidade:** Alto · **Recurso:** assinatura
**Referência:** CIS 8.1.5.1, 8.1.8.1, 8.1.7.3, 8.1.9.1 · Prowler (regras `defender_*` e `sqlserver_microsoft_defender_enabled`) · Defender (planos de Storage, Key Vault, SQL e Resource Manager)

**O que está errado.** Os planos de proteção do Microsoft Defender estão no nível gratuito para os quatro serviços que a Nuvelo usa.

**Evidência** (`evidencias/A-10.txt`): `StorageAccounts`, `KeyVaults`, `SqlServers` e `Arm` com nível `Free`.

**Risco para a Nuvelo.** O nível gratuito só avalia configuração. Ele não detecta comportamento suspeito, como downloads em massa, tentativas de senha no banco ou acessos ao cofre a partir de locais incomuns.

**Correção.** Ativar o plano pago do Defender para Storage, Key Vault, SQL e Resource Manager. Os planos são cobrados por recurso, então vale estimar o custo mensal antes. Com o plano de SQL, também passam a funcionar as varreduras de vulnerabilidade do banco.

---

### A-11 — Cofre aberto a qualquer rede

**Gravidade:** Médio · **Recurso:** `kv-nuvelo-ishadm`
**Referência:** CIS 8.3.7, 8.3.8 · Prowler `keyvault_private_endpoints` · Defender "Azure Key Vaults should use private link", "Firewall should be enabled on Key Vault"

**O que está errado.** O cofre aceita conexões da internet, não tem regras de rede e não usa endpoint privado.

**Evidência** (`evidencias/A-11.txt`): rede pública `Enabled`; regra padrão `null` (sem regras); `0` endpoints privados.

**Risco para a Nuvelo.** O cofre continua exigindo autenticação, por isso o risco é médio. Mas, se uma credencial vazar, ela poderá ser usada de qualquer lugar.

**Correção.** No curto prazo, ativar o firewall do cofre liberando só as redes da aplicação. No médio prazo, usar endpoint privado e desligar o acesso público.

---

### A-12 — Cofre com modelo de permissão antigo

**Gravidade:** Médio · **Recurso:** `kv-nuvelo-ishadm`
**Referência:** CIS 8.3.6 · Prowler `keyvault_rbac_enabled` · Defender "Role-Based Access Control should be used on Azure Keyvault Services"

**O que está errado.** O cofre usa políticas de acesso (modelo antigo) em vez do RBAC do Azure.

**Evidência** (`evidencias/A-12.txt`): RBAC `false`; `1` política de acesso.

**Risco para a Nuvelo.** As permissões do cofre ficam fora da revisão de acessos do resto do Azure. Quem audita os papéis da assinatura não enxerga quem tem acesso aos segredos.

**Correção.** Recriar as permissões como papéis do Azure (por exemplo, Key Vault Secrets User para quem só lê segredos) e ativar a autorização RBAC no cofre. No Terraform, o atributo é `rbac_authorization_enabled` (ou `enable_rbac_authorization` em versões anteriores do provider azurerm).

---

### A-13 — Senha do banco sem expiração

**Gravidade:** Médio · **Recurso:** segredo `senha-admin-sql`
**Referência:** CIS 8.3.4 · Prowler `keyvault_non_rbac_secret_expiration_set` · não detectado pelo Defender

**O que está errado.** A senha do administrador do banco está guardada no cofre sem data de expiração.

**Evidência** (`evidencias/A-13.txt`): os metadados do segredo não têm o campo `exp`. O valor da senha não foi lido.

**Risco para a Nuvelo.** Senha que não expira não é trocada. Ela continua válida mesmo depois da saída de quem a conhecia, como o desenvolvedor que montou o ambiente.

**Correção.** Trocar a senha agora, definir uma data de expiração e uma rotina de rotação.

```hcl
resource "azurerm_key_vault_secret" "conexao_banco" {
  # ...
  expiration_date = "2027-02-01T00:00:00Z"
}
```

---

### A-14 — Sem alertas para mudanças críticas

**Gravidade:** Médio · **Recurso:** assinatura
**Referência:** CIS 6.1.2.1 a 6.1.2.11 · Prowler (11 regras `monitor_alert_*`) · não detectado pelo Defender

**O que está errado.** Não existe nenhum alerta do Activity Log.

**Evidência** (`evidencias/A-14.txt`): lista de alertas vazia (`[]`).

**Risco para a Nuvelo.** Se alguém abrir uma regra de firewall, apagar um grupo de segurança ou desligar uma política, ninguém fica sabendo.

**Correção.** Criar alertas do Activity Log para criação, alteração e exclusão de: grupos de segurança de rede, regras de firewall do SQL, atribuições de políticas e soluções de segurança, enviando para o contato do A-17.

---

### A-15 — Banco só com login por senha

**Gravidade:** Médio · **Recurso:** `sql-nuvelo-ishadm`
**Referência:** benchmark de banco de dados do CIS · Prowler `sqlserver_azuread_administrator_enabled` · Defender "SQL servers should have an Azure Active Directory administrator provisioned"

**O que está errado.** O único acesso administrativo é o usuário SQL `nuveloadmin`, com senha. Não há administrador do Entra ID.

**Evidência** (`evidencias/A-15.txt`): login administrativo `nuveloadmin`; lista de administradores do Entra ID vazia (`[]`).

**Risco para a Nuvelo.** Sem login corporativo, não há MFA, não há desativação automática quando alguém sai da empresa, e a senha é compartilhada por quem precisa de acesso.

**Correção.** Configurar um grupo do Entra ID como administrador do servidor, migrar aplicação e integração para identidades gerenciadas e, ao final, permitir apenas autenticação pelo Entra ID.

---

### A-16 — Arquivos sem proteção contra exclusão acidental

**Gravidade:** Médio · **Recurso:** `stnuveloishadm`
**Referência:** CIS 9.2.1, 9.2.2, 9.2.3 · Prowler `storage_ensure_soft_delete_is_enabled`, `storage_blob_versioning_is_enabled` · não detectado pelo Defender

**O que está errado.** Arquivos e containers apagados não são retidos, e versões anteriores não são guardadas.

**Evidência** (`evidencias/A-16.txt`): exclusão reversível `False`; versionamento não configurado.

**Risco para a Nuvelo.** Uma exclusão por engano, ou um ransomware que sobrescreva os arquivos, levaria os dados em definitivo.

**Correção.**

```hcl
resource "azurerm_storage_account" "arquivos" {
  # ...
  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }
}
```

---

### A-17 — Ninguém é avisado de alertas de segurança

**Gravidade:** Médio · **Recurso:** assinatura
**Referência:** Defender "Subscriptions should have a contact email address for security issues", "Email notification for high severity alerts should be enabled"

**O que está errado.** Não há contato de segurança cadastrado no Defender, e as notificações de alertas graves estão desligadas.

**Evidência** (`evidencias/A-17.txt`).

**Risco para a Nuvelo.** Mesmo que a Microsoft detecte uma atividade suspeita, o aviso não chega a ninguém.

**Correção.** Cadastrar um e-mail de segurança (de preferência uma lista, não uma pessoa) e ativar as notificações de alertas de gravidade alta para os Owners.

---

## 4. Itens avaliados e não priorizados

| Item | Motivo |
| --- | --- |
| Proteção DDoS Standard | Custo mensal elevado, desproporcional ao porte da empresa. A proteção básica da plataforma já está ativa |
| Azure Bastion | Não há máquinas virtuais |
| Defender para Cosmos DB, DNS, containers, App Services, IoT, servidores e bancos open source | Serviços não utilizados pela Nuvelo |
| Chaves gerenciadas pelo cliente e criptografia de infraestrutura | Os dados já são criptografados pela plataforma. Recomendável só com exigência regulatória específica |
| Criptografia de canal SMB | Não há compartilhamentos de arquivos |
| Application Insights e Network Watcher | Não se aplicam aos recursos atuais |
| Geo-redundância do storage | Decisão de custo e continuidade do negócio. Ver observações |

---

## 5. Observações

- **Um único dono humano.** A assinatura tem apenas um usuário com papel Owner, e esse usuário aparece com duas atribuições idênticas. Ter um único dono foi o que deixou a empresa sem saber o que existia no ambiente quando o responsável saiu. Recomenda-se dois Owners nominais, com MFA, e a remoção da atribuição duplicada.
- **Redundância geográfica.** Os arquivos ficam em um único datacenter (LRS). Se a perda dos arquivos de uma região for inaceitável para o negócio, avaliar a replicação para outra região.
- **Dados em região diferente.** O servidor de banco está em uma região diferente do restante do ambiente. Recomenda-se confirmar se isso é intencional e se está de acordo com os compromissos de localização de dados assumidos com os clientes.
