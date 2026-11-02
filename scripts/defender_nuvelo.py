import csv
import glob
from collections import Counter

ARQUIVO = sorted(glob.glob("scans/defender-nuvelo-*.csv"))[-1]
GRUPO = "rg-nuvelo-prod"
NAO_INTEGRO = {"unhealthy", "não íntegro"}

with open(ARQUIVO, encoding="utf-8-sig") as f:
    linhas = list(csv.DictReader(f))

print("Arquivo:", ARQUIVO)
print("Estados encontrados:", Counter(l["state"] for l in linhas))


def da_nuvelo(grupo):
    return grupo.lower() == GRUPO or grupo == ""


problemas = [
    l for l in linhas
    if l["state"].lower() in NAO_INTEGRO and da_nuvelo(l["resourceGroup"])
]

for l in sorted(problemas, key=lambda x: x["resourceName"]):
    print(f"{l['resourceName']:25} | {l['gravidade']:8} | {l['recommendationDisplayName']}")

print(f"\n{len(problemas)} recomendações não íntegras da Nuvelo ou da assinatura")
