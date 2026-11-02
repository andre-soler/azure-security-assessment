import csv

with open("scans/triagem-prowler.csv", encoding="utf-8") as f:
    for l in csv.DictReader(f, delimiter=";"):
        partes = [p.strip() for p in l["COMPLIANCE"].split("|")]
        cis = [p for p in partes if p.startswith("CIS") and "6.0" in p]
        print(f"{l['CHECK_ID']:60} {', '.join(cis) or '-'}")
