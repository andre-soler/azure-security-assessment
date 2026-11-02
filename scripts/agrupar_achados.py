import csv
from collections import defaultdict

ORDEM = {"critical": 0, "high": 1, "medium": 2, "low": 3}

grupos = defaultdict(set)
with open("scans/triagem-prowler.csv", encoding="utf-8") as f:
    for l in csv.DictReader(f, delimiter=";"):
        chave = (l["SEVERITY"], l["SERVICE_NAME"], l["CHECK_ID"])
        grupos[chave].add(l["RESOURCE_NAME"])

itens = sorted(grupos.items(), key=lambda x: (ORDEM.get(x[0][0], 9), x[0][1]))

for (gravidade, servico, check), recursos in itens:
    print(f"{gravidade:8} | {servico:11} | {check}")
    print(f"           recursos: {', '.join(sorted(recursos))}")

print(f"\n{len(itens)} regras diferentes reprovadas")
