# Resumo executivo — Diagnóstico de segurança da nuvem

**Cliente:** Nuvelo Eventos (fictício) · **Data:** 02/11/2026 · **Responsável:** André Soler

---

## A situação em uma frase

O ambiente da Nuvelo no Azure tem problemas graves e fáceis de explorar, mas quase todos se corrigem em poucos dias, sem parar o sistema.

## Os números

- **Pontuação de segurança da Microsoft:** 18 de 100.
- **17 problemas confirmados:** 3 críticos, 7 altos e 7 médios.
- Todos foram verificados um a um, com acesso somente de leitura. Nenhuma configuração foi alterada.

## Os três riscos que exigem ação imediata

1. **As listas de convidados podem ser baixadas por qualquer pessoa na internet.** Os arquivos que as agências enviam, com nome, e-mail e CPF dos participantes, ficam numa pasta aberta. Basta ter o link, sem senha.
2. **O banco de dados aceita tentativas de acesso de qualquer lugar do mundo.** Uma regra "temporária" libera todos os endereços da internet. O banco fica exposto a robôs que testam senhas o dia inteiro.
3. **Uma integração automática tem a chave mestra de todo o ambiente.** Ela recebeu permissão de dono sobre tudo, quando só precisaria acessar os arquivos e o banco. Se essa integração for comprometida, quem a controlar pode apagar, copiar ou sequestrar qualquer coisa.

Somado a isso, **ninguém seria avisado**: não há registro de atividades guardado, nem alertas configurados, nem um contato que receba os avisos de segurança da Microsoft.

## O que pode acontecer

- Vazamento de dados pessoais de participantes de eventos.
- Obrigação de comunicar o incidente à ANPD e às pessoas afetadas, com risco de multa prevista na LGPD.
- Perda do contrato em negociação com a rede de hotéis, que já pediu evidências de segurança.

## Plano de correção

| Prazo | O que corrigir | Por quê |
| --- | --- | --- |
| **48 horas** | Fechar a pasta de arquivos e exigir conexão criptografada; fechar o banco para a internet; reduzir a permissão da integração; remover regras de rede abertas que sobraram; cadastrar um contato de segurança | Os três riscos críticos e ajustes de poucos minutos cada |
| **30 dias** | Ligar auditoria e registro de atividades; proteger o cofre de senhas e os arquivos contra exclusão; ativar a proteção da Microsoft nos serviços usados; login corporativo no banco | Exigem algum planejamento ou têm custo mensal |
| **90 dias** | Isolar o cofre de senhas na rede interna; modernizar as permissões do cofre; criar alertas para mudanças críticas | Mudanças de estrutura, sem urgência imediata depois dos dois primeiros prazos |

## E o questionário da rede de hotéis

Com os prazos de 48 horas e de 30 dias cumpridos, a Nuvelo passa a ter respostas sólidas e verificáveis para as perguntas sobre proteção de dados pessoais, criptografia, controle de acesso e registro de atividades.

## Próximo passo

As correções podem ser feitas pela equipe da Nuvelo a partir do relatório técnico, que detalha cada item, ou contratadas separadamente. Em ambos os casos, recomenda-se uma nova verificação ao fim dos 30 dias para confirmar que tudo foi resolvido.
