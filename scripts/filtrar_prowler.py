import csv
import glob
from collections import Counter

ARQUIVO = sorted(glob.glob("scans/prowler-nuvelo-*.csv"))[-1]
SAIDA = "scans/triagem-prowler.csv"
GRUPO = "/resourcegroups/rg-nuvelo-prod/"
COLUNAS = [
    "CHECK_ID", "CHECK_TITLE", "SEVERITY", "SERVICE_NAME",
    "RESOURCE_NAME", "RESOURCE_UID", "STATUS_EXTENDED",
    "REMEDIATION_RECOMMENDATION_TEXT", "COMPLIANCE",
]


def da_nuvelo(uid):
    uid = uid.lower()
    return GRUPO in uid or "/resourcegroups/" not in uid


with open(ARQUIVO, encoding="utf-8") as f:
    linhas = list(csv.DictReader(f, delimiter=";"))

print("Arquivo:", ARQUIVO)
print("Status:", Counter(l["STATUS"] for l in linhas))

falhas = [l for l in linhas if l["STATUS"] == "FAIL"]
nuvelo = [l for l in falhas if da_nuvelo(l["RESOURCE_UID"])]

print("Reprovados no total:", len(falhas))
print("Reprovados da Nuvelo ou da assinatura:", len(nuvelo))
print("Por gravidade:", Counter(l["SEVERITY"] for l in nuvelo))
print("Por serviço:", Counter(l["SERVICE_NAME"] for l in nuvelo))

with open(SAIDA, "w", encoding="utf-8", newline="") as f:
    escritor = csv.DictWriter(f, fieldnames=COLUNAS, delimiter=";", extrasaction="ignore")
    escritor.writeheader()
    escritor.writerows(nuvelo)

print("Salvo em", SAIDA)
