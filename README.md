
---

```
  ███╗   ██╗███████╗████████╗███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗
  ████╗  ██║██╔════╝╚══██╔══╝████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗
  ██╔██╗ ██║█████╗     ██║   ██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝
  ██║╚██╗██║██╔══╝     ██║   ██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗
  ██║ ╚████║███████╗   ██║   ██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║
  ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝

  TCP/IP + DNS + HTTP  ─  Learn networking hands-on
```
[![version](https://img.shields.io/badge/version-1.0.0-blue)](#)
[![bash](https://img.shields.io/badge/requires-bash%204.0%2B-lightgrey)](#)
[![platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Git%20Bash-brightgreen)](#)
[![license](https://img.shields.io/badge/license-MIT-green)](#)
---

## What is this?

`netmaster` is an interactive, terminal-based training tool for learning **TCP/IP, DNS and HTTP** from the ground up.

It runs entirely in your shell. No browser. No signup. No account.

You answer questions. Get them wrong and the script teaches you — shows you why, then asks again. Get them right and you move forward. Zone 7 takes it further: you open a real terminal alongside, run live `dig` commands, and walk the DNS tree yourself from root nameserver to authoritative answer. That's the part interviewers and examiners actually ask you to demonstrate.

Finish all 8 zones and you'll know your OSI layers, understand why your MAC address can't be seen by `example.com`, explain what an authoritative nameserver does, and know the difference between a 401 and a 403.

---

## Quick start

**Download and run:**

```bash
curl -O https://raw.githubusercontent.com/bixson/netmaster/main/netmaster.sh
bash netmaster.sh
```

**Or clone:**

```bash
git clone https://github.com/bixson/netmaster.git
cd netmaster
bash netmaster.sh
```

No installation needed. No dependencies beyond `bash 4.0+` and (optionally) `dig` for the live DNS lab in Zone 7.

---

## The 8 zones

| # | Zone | Topics covered | Live lab |
|---|------|---------------|----------|
| 1 | OSI & TCP/IP Model | Layer names, what each layer does, OSI vs TCP/IP differences | — |
| 2 | IP & MAC Addresses | Local vs public IPs, private ranges, MAC layer, ifconfig/ipconfig | — |
| 3 | Router, Switch & Ports | Switch vs router, DHCP, standard port numbers (22, 53, 80, 443…) | — |
| 4 | TCP Packet Fields | SRC/DST, ACK (and why UDP doesn't have it), TTL as hopcount, traceroute | — |
| 5 | DNS Basics & Record Types | A, AAAA, CNAME, MX, NS, TXT, PTR — tools: nslookup / host / dig | — |
| 6 | TTL in DNS & Nameserver Types | High vs low TTL strategy, authoritative vs caching resolver, non-authoritative answers | — |
| **7** | **dig Lab** | **Walk the DNS tree live: root → TLD → authoritative** | **✓** |
| 8 | HTTP Methods, Codes & Headers | GET vs POST, 2xx/3xx/4xx/5xx, Accept vs Content-Type, cookies & sessions | — |

---

## The dig lab (Zone 7)

Zone 7 is the centrepiece of `netmaster`. Instead of multiple choice, you work in a real terminal alongside the script.

You simulate being a recursive resolver — asking each level of the DNS hierarchy manually until you reach the authoritative answer:

```bash
# Step 1: Ask a root nameserver
dig @a.root-servers.net A example.com
# → AUTHORITY SECTION: com nameservers (a.gtld-servers.net, b.gtld-servers.net …)

# Step 2: Ask the .com TLD nameserver
dig @a.gtld-servers.net A example.com
# → AUTHORITY SECTION: example.com nameservers (a.iana-servers.net …)

# Step 3: Ask the authoritative nameserver
dig @a.iana-servers.net A example.com
# → ANSWER SECTION: example.com. 86400 IN A 93.184.216.34  ✓
```

After each step, `netmaster` asks you questions about what you saw and why it happened. If `dig` is not installed on your system, the zone falls back to a theory walk-through automatically.

**Install `dig` if needed:**

```bash
# macOS
brew install bind

# Ubuntu / Debian
sudo apt install dnsutils

# Windows
# Use WSL, or download BIND tools from isc.org
```

---

## What happens when you get an answer wrong

```
  Q: What does TTL mean in a TCP/IP packet — and what would be a better name?

    1) Seconds until the packet expires in a cache
    2) Max hops before packet is dropped — better name: 'hopcount'
    3) Size limit of the packet in bytes
    4) Time to wait for an ACK before retrying

  Your answer (number): 1

  ✗ Not quite.
    Try again (include the key term)...

  Your answer (number): 3

  ✗ Not quite.

  ╔══ HINT ══════════════════════════════════════════════════╗
  ║  Correct answer: Max hops before packet is dropped —    ║
  ║  better name: 'hopcount'                                ║
  ╚══════════════════════════════════════════════════════════╝
```

Two wrong attempts reveal the answer and explanation. You still move forward — nothing blocks you. First-try correct answers are the ones that count toward your score.

---

## Scoring

| Score | Grade estimate |
|-------|---------------|
| 90%+ | ★ Expert (12) |
| 75–89% | ★ Proficient (10) |
| 60–74% | ★ Competent (7) |
| 40–59% | ★ Developing (4) |
| Below 40% | ★ Needs work (02/below) |

Your score is saved between sessions in `~/.netmaster/score.txt`. Run `--reset` to start fresh.

---

## Controls

| Key / Input | Action |
|-------------|--------|
| `1` `2` `3` `4` | Select multiple-choice answer |
| `Enter` | Confirm / move to next step |
| `Ctrl+C` | Exit at any point |

---

## All flags

```
bash netmaster.sh               # Full run — all 8 zones in sequence
bash netmaster.sh --zone 7      # Jump straight to the dig lab
bash netmaster.sh --list        # Show zone map with completion status
bash netmaster.sh --reset       # Wipe saved score and zone progress
bash netmaster.sh --version     # Print version
bash netmaster.sh --help        # Print this help
```

---

## Zone details

<details>
<summary><strong>Zone 1 — OSI & TCP/IP Model</strong></summary>

The OSI model has 7 layers. The TCP/IP model has 4. Understanding why they differ — and which layer maps to which — is a foundational exam question in networking.

**Questions cover:**
- How many layers does TCP/IP have?
- Which layer handles IP addresses?
- Which layer do TCP and UDP belong to?
- What does WireShark's "Ethernet II" line correspond to?
- What are the two structural differences between OSI and TCP/IP?

</details>

<details>
<summary><strong>Zone 2 — IP & MAC Addresses</strong></summary>

Two address types, two completely different layers. The distinction matters in WireShark and in any networking exam.

**Questions cover:**
- IP (logical) vs MAC (physical/hardware) — what is each?
- What is a private/local IP address? What ranges count?
- Why can you NOT see `example.com`'s MAC address in WireShark?
- Which command finds your local IP on Mac vs Windows?

</details>

<details>
<summary><strong>Zone 3 — Router, Switch & Ports</strong></summary>

Two devices that look similar on the outside but operate at completely different layers — and a number table you should have memorised.

**Questions cover:**
- What is the difference between a router and a switch?
- What does DHCP do, and who runs it?
- What port does HTTPS use? SSH? DNS? MySQL?
- What is a port, and why does it exist?

</details>

<details>
<summary><strong>Zone 4 — TCP Packet Fields</strong></summary>

Reading a WireShark packet dissection is a common exam demonstration. Know what every field means.

**Questions cover:**
- What does `Src Port` tell you vs `Dst Port`?
- What does ACK do — and which protocol skips it?
- What does TTL mean in TCP (and what's a better name)?
- What is traceroute used for?

</details>

<details>
<summary><strong>Zone 5 — DNS Basics & Record Types</strong></summary>

DNS record types come up in both theory and demonstration questions. You need to know all of them and what each one does.

**Questions cover:**
- What does an A record do?
- What is the difference between A and CNAME?
- Which record type handles email routing?
- Which tool shows all record types at once without specifying them?
- What port does DNS use?

</details>

<details>
<summary><strong>Zone 6 — TTL in DNS & Nameserver Types</strong></summary>

TTL appears in two places in networking — and means something different in each. Nameserver types are a classic exam question.

**Questions cover:**
- What does TTL mean in DNS vs in TCP/IP?
- When would you lower your DNS TTL — and when raise it?
- What does "Non-authoritative answer" in nslookup mean?
- Authoritative vs caching/recursive resolver — what is each?

</details>

<details>
<summary><strong>Zone 7 — dig Lab (Root → TLD → Authoritative)</strong></summary>

The hands-on DNS walk-through. You run real `dig` commands in a second terminal and interpret the output at each step.

**Lab tasks:**

| Step | Command | Expected section | What you learn |
|------|---------|-----------------|----------------|
| 1 | `dig @a.root-servers.net A example.com` | AUTHORITY | Root returns TLD nameservers for `.com` |
| 2 | `dig @a.gtld-servers.net A example.com` | AUTHORITY | TLD returns example.com's own nameservers |
| 3 | `dig @a.iana-servers.net A example.com` | ANSWER | Authoritative server returns the IP |
| Bonus | `dig +trace example.com` | All | Full recursive walk in one command |

</details>

<details>
<summary><strong>Zone 8 — HTTP Methods, Status Codes & Headers</strong></summary>

HTTP is the top of the stack. Know your methods, your codes, and the difference between Accept and Content-Type.

**Questions cover:**
- When to use GET vs POST — and why passwords go in POST
- What status code to return when a resource is created (201 vs 200)
- The difference between 401 and 403
- Accept vs Content-Type headers
- How cookies enable sessions on a stateless protocol

</details>

---

## Contributing

Contributions are welcome — new zones, improved questions, better explanations.

1. Fork the repo
2. Create a branch: `git checkout -b zone/wireshark` or `git checkout -b fix/typo-zone5`
3. Make your changes
4. Open a PR with a short description of what changed and why

---

## Roadmap

- [ ] `--quick` mode: theory questions only, skip lab steps
- [ ] `--drill` mode: rapid-fire questions, no explanations between
- [ ] Zone 9: WireShark filters and reading packet captures
- [ ] Zone 10: HTTPS — TLS handshake, certificates, port 443
- [ ] Score history: track improvement across multiple runs

---

## Related

If you want to train the Linux terminal alongside networking, check out [dojomaster](https://github.com/bixson/dojomaster) — the same format, covering `ssh`, `grep`, `chmod`, pipes and more.

For Docker and containerisation, check out [dockermaster](https://github.com/bixson/dockermaster) — Dockerfile, images, compose, port mapping, volumes and multi-stage builds.

---

## License

MIT

---

<div align="center">

Made for anyone learning networking from the command line.

If this helped you — consider leaving a star.

</div>