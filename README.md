# Azure Security Assessment

A read-only security assessment of an Azure subscription, delivered the way a consultant would deliver it to a real client: briefing, automated scanning, manual validation with evidence, and a two-part report for the business owner and the engineering team.

The client is fictional. The environment, the findings and the evidence are real: everything was built, scanned and validated on a live Azure subscription, then destroyed.

## The scenario

**Nuvelo Eventos** is a 15-person B2B SaaS for corporate event agencies. A developer set up their Azure environment in a hurry, then left the company. Nobody knows exactly what is running. A large hotel chain has just sent them an 80-question security questionnaire before signing a contract.

The ask: *"Tell me where we're exposed and what to fix first, in language I can understand."*

Constraints: read-only access, no downtime, five business days.

Full briefing: [`docs/briefing.md`](docs/briefing.md)

## What was delivered

| Deliverable | Audience | File |
| --- | --- | --- |
| Executive summary (1 page) | Business owner | [`report/resumo-executivo.md`](report/resumo-executivo.md) (PT) · [`report/executive-summary-en.md`](report/executive-summary-en.md) (EN) |
| Technical report | Engineering team | [`report/relatorio-tecnico.md`](report/relatorio-tecnico.md) |
| Findings register | Both | [`report/achados.csv`](report/achados.csv) |
| Evidence, one file per finding | Auditors | [`report/evidencias/`](report/evidencias/) |

**Result:** Microsoft Secure Score of 18%, and **17 validated findings: 3 critical, 7 high, 7 medium**, each mapped to the CIS Microsoft Azure Foundations Benchmark v6.0, with evidence and a Terraform remediation.

## Method

1. **Build the client's environment.** Terraform creates a subscription with 14 deliberate misconfigurations across storage, networking, SQL, Key Vault, identity, logging and Defender, recorded in an answer key ([`docs/gabarito.md`](docs/gabarito.md)).
2. **Get client-grade access.** A service principal with the Reader role only. Verified before the scan: it can list resources but fails to create one.
3. **Scan with two independent tools.** [Prowler](https://github.com/prowler-cloud/prowler) (open source, run in Docker) and Microsoft Defender for Cloud.
4. **Triage.** Small Python scripts in [`scripts/`](scripts/) filter the raw output to the client's scope, group findings by rule and extract CIS controls: from 107 Prowler checks and 26 Defender recommendations down to 17 consolidated findings.
5. **Validate every finding by hand.** Azure CLI commands run with the same read-only identity, outputs saved with a timestamp. Evidence proves exposure without exposing data: the public file is proven downloadable by its HTTP status code, the secret's missing expiry by its metadata, never its value.
6. **Re-rate severity by business impact.** A publicly readable container is "high" for a generic scanner; for a company storing national ID numbers it is critical.
7. **Report in two voices**, then destroy everything.

## What the tools caught and missed

Because the misconfigurations were planted, it was possible to measure each tool against a known answer key:

| Planted misconfiguration | Prowler | Defender for Cloud |
| --- | --- | --- |
| Storage allows public containers | ✅ | ✅ |
| HTTPS not enforced on storage | ✅ | ✅ |
| Anonymous read on the upload container | ⚠️ account-level only | ⚠️ account-level only |
| SSH open to the internet | ✅ | ❌ |
| RDP open to the internet | ✅ | ❌ |
| SQL firewall open to all IPs | ✅ | ⚠️ flags public access only |
| SQL auditing off | ✅ | ✅ |
| Key Vault purge protection off | ✅ | ✅ |
| Key Vault open to all networks | ⚠️ checks private endpoints only | ✅ |
| Key Vault using legacy access policies | ✅ | ✅ |
| Secret without expiry | ✅ | ❌ |
| **Integration identity with Owner on the subscription** | **❌** | **❌** |
| No diagnostic logs | ✅ | ⚠️ Key Vault only |
| Defender plans off | ✅ | ✅ |
| **Total** | **11 ✅ · 2 ⚠️ · 1 ❌** | **7 ✅ · 4 ⚠️ · 3 ❌** |

Three takeaways:

- **The most dangerous issue was invisible to both tools.** A managed identity with Owner over the whole subscription was only found by manually reviewing role assignments. Running a scanner and forwarding its output would have missed the one finding that hands over the entire environment.
- **Defender only checks management ports on existing VMs.** An NSG left behind by a deleted VM, still attached to its subnet, went unnoticed. Prowler evaluates the NSG itself.
- **The tools complement each other.** Prowler was more complete overall; Defender was better on Key Vault network exposure and surfaced a gap Prowler didn't: no security contact, so alerts would reach no one.

## Repository structure

```
infra/      Terraform for the client's vulnerable environment
docs/       Briefing, answer key, assessment constraints
scripts/    Triage scripts (filter, group, CIS mapping, Defender cross-check)
report/     Findings register, reports and evidence
scans/      Raw scanner output — git-ignored on purpose
```

Raw scan output, Terraform state and credentials are never committed: in a real engagement they are a map of the client's weaknesses.

## Reproducing it

Requirements: Azure CLI, Terraform ≥ 1.6, Docker, Python 3, and an Azure subscription where you are Owner.

```bash
# 1. Build the environment (costs cents; SQL Server without databases is free)
cd infra
export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
terraform init && terraform apply

# 2. Create read-only access and store it in .env (git-ignored)
az ad sp create-for-rbac --name sp-prowler-leitura --role Reader \
  --scopes /subscriptions/$ARM_SUBSCRIPTION_ID

# 3. Scan
docker run --rm --env-file .env -v "$(pwd)/scans:/home/prowler/output" \
  toniblyx/prowler:stable azure --sp-env-auth --output-formats csv html

# 4. Triage
python3 scripts/filtrar_prowler.py
python3 scripts/agrupar_achados.py
python3 scripts/controles_cis.py

# 5. Clean up
terraform destroy
az ad app delete --id <client-id>
```

Regions are set in `infra/variables.tf`. Adjust them to what your subscription allows.

## Limitations

- **Entra ID out of scope.** The assessment ran on an Azure for Students subscription inside a university directory, so the read-only identity had no Microsoft Graph permissions. Users, MFA and Conditional Access are covered in a later project.
- **Configuration review, not penetration testing.** No exploitation, application testing or credential attacks.
- **Lab constraints.** The SQL Server sits in a different region because the student offer blocks SQL provisioning in the main one.

## Author

André Soler — Cloud Security · [LinkedIn](https://linkedin.com/in/andresolereng) · [GitHub](https://github.com/andre-soler)

This is project 1 of 20 in a cloud security portfolio built around real client-style engagements.
