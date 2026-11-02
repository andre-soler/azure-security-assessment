# Executive Summary — Cloud Security Assessment

**Client:** Nuvelo Eventos (fictional) · **Date:** November 2, 2026 · **Assessor:** André Soler

---

## The situation in one sentence

Nuvelo's Azure environment has serious, easily exploitable weaknesses, but nearly all of them can be fixed within days without any downtime.

## Key numbers

- **Microsoft Secure Score:** 18 out of 100.
- **17 confirmed findings:** 3 critical, 7 high, 7 medium.
- Every finding was manually verified using read-only access. No configuration was changed.

## The three risks that require immediate action

1. **Guest lists can be downloaded by anyone on the internet.** Files uploaded by event agencies, containing attendees' names, emails and national ID numbers (CPF), sit in a publicly readable folder. Anyone with the link can download them, no password required.
2. **The database accepts connection attempts from anywhere in the world.** A "temporary" firewall rule allows every internet address, exposing the database to automated password-guessing bots.
3. **An automated integration holds the master key to the entire environment.** It was granted full ownership of the subscription, when it only needs access to the file storage and the database. Whoever compromises it can delete, copy or hold any resource for ransom.

On top of that, **no one would be alerted**: activity logs are not retained, no alerts are configured, and no contact is registered to receive Microsoft's security notifications.

## What could happen

- A leak of attendees' personal data.
- A mandatory breach notification to Brazil's data protection authority (ANPD) and to affected individuals, with potential fines under the LGPD (Brazil's data protection law).
- Loss of the contract currently being negotiated with a hotel chain that has already requested security evidence.

## Remediation plan

| Timeframe | What to fix | Why |
| --- | --- | --- |
| **48 hours** | Close the file folder and enforce encrypted connections; close the database to the internet; reduce the integration's permissions; remove leftover open network rules; register a security contact | The three critical risks, plus fixes that take minutes each |
| **30 days** | Enable auditing and activity logging; protect the secrets vault and files against deletion; turn on Microsoft Defender for the services in use; enable corporate sign-in for the database | Require some planning or carry a monthly cost |
| **90 days** | Move the secrets vault to a private network; modernize vault permissions; create alerts for critical changes | Structural changes, no longer urgent once the first two phases are done |

## The hotel chain questionnaire

Once the 48-hour and 30-day phases are complete, Nuvelo will have solid, verifiable answers to questions on personal data protection, encryption, access control and activity logging.

## Next step

Nuvelo's team can carry out the fixes using the technical report, which details each item, or the remediation can be contracted separately. Either way, a follow-up verification at the 30-day mark is recommended to confirm every issue has been resolved.
