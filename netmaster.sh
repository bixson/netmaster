#!/usr/bin/env bash
# =============================================================================
#
#   NETMASTER  --  Master TCP/IP and DNS for a networking exam. One zone at a time.
#
#   Covers: OSI/TCP-IP Model, IP & MAC addresses, Router vs Switch,
#           Ports, TCP fields (SRC/DST/ACK/TTL), DNS record types,
#           TTL in DNS, Authoritative vs Caching nameservers,
#           Recursive resolution, dig lab (root → TLD → authoritative),
#           HTTP methods, status codes, headers, cookies & sessions
#
#   Works on: macOS, Linux, Git Bash (Windows)
#   Requires: bash 4.0+   (dig must be installed for Zone 7 lab)
#
#   Usage:
#     bash netmaster.sh               # full journey, all zones
#     bash netmaster.sh --zone 7      # jump straight to the dig lab
#     bash netmaster.sh --list        # show all zones
#     bash netmaster.sh --reset       # wipe saved progress
#     bash netmaster.sh --help        # this help text
#
# =============================================================================

set -uo pipefail

# ── colours ──────────────────────────────────────────────────────────────────
R=$'\e[0;31m';  BOLD=$'\e[1m';    CYAN=$'\e[0;36m'
G=$'\e[0;32m';  YELLOW=$'\e[0;33m'; MAGENTA=$'\e[0;35m'
BLUE=$'\e[0;34m'; WHITE=$'\e[1;37m'; DIM=$'\e[2m'
NC=$'\e[0m'     # no colour

# ── state dir ────────────────────────────────────────────────────────────────
STATE_DIR="${HOME}/.netmaster"
mkdir -p "${STATE_DIR}"
SCORE_FILE="${STATE_DIR}/score.txt"
LOGFILE="${STATE_DIR}/session.log"
[[ -f "${SCORE_FILE}" ]] || echo "0 0" > "${SCORE_FILE}"

read -r SCORE_CORRECT SCORE_TOTAL < "${SCORE_FILE}"

PLAYER_NAME=""

# ── helpers ───────────────────────────────────────────────────────────────────
log() { echo "$(date '+%H:%M:%S') $*" >> "${LOGFILE}" 2>/dev/null; }

press_enter() { echo -e "${DIM}  ↵  Press Enter to continue...${NC}"; read -r; }

header() {
  clear
  echo -e "${CYAN}${BOLD}"
   echo "                     +--------------+ "
     echo "                     |.------------.| "
     echo "                     ||            || "
     echo "                     ||            || "
     echo "                     ||            || "
     echo "                     ||            || "
     echo "                     |+------------+| "
     echo "                     +-..--------..-+ "
     echo "                     .--------------. "
    echo "                    / /============\ \ "
   echo "                   / /==============\ \ "
  echo "                  /____________________\ "
  echo "                  \____________________/ "
  echo "  ███╗   ██╗███████╗████████╗███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗ "
  echo "  ████╗  ██║██╔════╝╚══██╔══╝████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗"
  echo "  ██╔██╗ ██║█████╗     ██║   ██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝"
  echo "  ██║╚██╗██║██╔══╝     ██║   ██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗"
  echo "  ██║ ╚████║███████╗   ██║   ██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║"
  echo "  ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝"
  echo -e "${NC}"
  echo -e "${DIM}  TCP/IP + DNS + HTTP${NC}"
  echo ""
}

score_bar() {
  read -r SC ST < "${SCORE_FILE}"
  local pct=0
  [[ ${ST} -gt 0 ]] && pct=$(( SC * 100 / ST ))
  echo -e "  ${DIM}Score: ${SC}/${ST}  (${pct}%)${NC}"
}

save_score() {
  local correct=$1 total=$2
  SCORE_CORRECT=$(( SCORE_CORRECT + correct ))
  SCORE_TOTAL=$(( SCORE_TOTAL + total ))
  echo "${SCORE_CORRECT} ${SCORE_TOTAL}" > "${SCORE_FILE}"
}

zone_complete() {
  local zone=$1
  touch "${STATE_DIR}/zone${zone}.done"
}

zone_done() {
  [[ -f "${STATE_DIR}/zone${1}.done" ]]
}

grade_label() {
  read -r SC ST < "${SCORE_FILE}"
  [[ ${ST} -eq 0 ]] && echo "No score yet" && return
  local pct=$(( SC * 100 / ST ))
  if   [[ ${pct} -ge 90 ]]; then echo "${G}★ Expert (12)${NC}"
  elif [[ ${pct} -ge 75 ]]; then echo "${CYAN}★ Proficient (10)${NC}"
  elif [[ ${pct} -ge 60 ]]; then echo "${YELLOW}★ Competent (7)${NC}"
  elif [[ ${pct} -ge 40 ]]; then echo "${YELLOW}★ Developing (4)${NC}"
  else echo "${R}★ Needs work (02/below)${NC}"; fi
}

# ── intro: welcome screen with player name ───────────────────────────────────
intro() {
  clear
  header
  echo -e "  ${BOLD}${WHITE}Welcome to netmaster — Master TCP/IP + DNS + HTTP for a networking exam.${NC}"
  echo ""
  echo -e "  ${DIM}8 zones. Multiple-choice questions + a live ${CYAN}dig${NC}${DIM} lab in Zone 7.${NC}"
  echo -e "  ${DIM}Answer wrong? You'll see a hint and the correct answer.${NC}"
  echo -e "  ${DIM}First-try correct answers count toward your score.${NC}"
  echo ""
  echo -e "  ${DIM}Grading: 90%+ = Expert (12)  75%+ = Proficient (10)  60%+ = Competent (7)${NC}"
  echo -e "  ${DIM}         40%+ = Developing (4)  <40% = Needs work (02)${NC}"
  echo ""
  echo -e "${DIM}  ───────────────────────────────────────────────────────────────────${NC}"
  echo ""

  # Name prompt
  printf "  ${CYAN}What should I call you? ${NC}"
  read -r PLAYER_NAME
  PLAYER_NAME="${PLAYER_NAME:-Student}"
  echo ""

  printf "  ${G}Let's go, ${BOLD}%s${NC}${G}.${NC}\n" "${PLAYER_NAME}"
  echo ""
  echo -e "  ${DIM}Tip: run  bash netmaster.sh --zone N  to jump straight to a zone.${NC}"
  echo ""
  log "Session started. Player: ${PLAYER_NAME}"
  press_enter
}

# ── ask_q: single correct answer multiple-choice ──────────────────────────────
# Usage: ask_q "Question text" "correct answer" "opt1" "opt2" "opt3" "opt4"
# Returns 1 if user got it right on first try, 0 otherwise
ask_q() {
  local question="$1"; shift
  local correct="$1"; shift
  local opts=("$@")
  local tries=0
  local first_time=1

  # Save state for undo functionality
  local score_before="${SCORE_CORRECT}" max_before="${SCORE_TOTAL}"

  while true; do
    if [[ ${first_time} -eq 1 ]]; then
      clear
      first_time=0
    fi
    echo ""
    echo -e "${BOLD}${WHITE}  Q: ${question}${NC}"
    echo ""
    local i=1
    for o in "${opts[@]}"; do
      echo -e "    ${CYAN}${i})${NC} ${o}"
      (( i++ ))
    done
    echo ""
    printf "  ${YELLOW}Your answer (number): ${NC}"

    # Read first character to check for Ctrl+N or Ctrl+B
    read -rsn1 ans_first

    # Check for Ctrl+N (skip with correct) or Ctrl+B (undo)
    if [[ "$ans_first" == $'\x0e' ]]; then  # Ctrl+N
      echo
      printf "  ${YELLOW}[SKIPPED - Mark as correct]${NC}\n"
      echo -e "  ${G}${BOLD}✓ Correct!${NC}"
      save_score 1 1
      sleep 0.5
      return 0
    elif [[ "$ans_first" == $'\x02' ]]; then  # Ctrl+B
      echo
      printf "  ${YELLOW}[UNDO - Question reset]${NC}\n"
      SCORE_CORRECT="${score_before}"
      SCORE_TOTAL="${max_before}"
      echo "${SCORE_CORRECT} ${SCORE_TOTAL}" > "${SCORE_FILE}"
      sleep 0.5
      return 0
    fi

    # Echo first character and read rest of line
    printf "%s" "$ans_first"
    local ans_rest
    read -r ans_rest
    local ans="${ans_first}${ans_rest}"

    # find matching option
    local chosen=""
    if [[ "${ans}" =~ ^[0-9]+$ ]] && [[ "${ans}" -ge 1 ]] && [[ "${ans}" -le "${#opts[@]}" ]]; then
      chosen="${opts[$(( ans - 1 ))]}"
    fi

    if [[ "${chosen}" == "${correct}" ]]; then
      if [[ ${tries} -eq 0 ]]; then
        echo -e "  ${G}${BOLD}✓ Correct!${NC}"
        save_score 1 1
        sleep 0.8
        return 0
      else
        echo -e "  ${G}✓ Correct this time.${NC}"
        save_score 0 1
        sleep 0.8
        return 0
      fi
    else
      (( tries++ ))
      echo -e "  ${R}✗ Not quite.${NC}"
      echo ""
      # Give hint / explanation on second wrong try
      if [[ ${tries} -ge 2 ]]; then
        echo -e "  ${MAGENTA}╔══ HINT ══════════════════════════════════════════════════╗${NC}"
        echo -e "  ${MAGENTA}║  Correct answer: ${BOLD}${correct}${NC}${MAGENTA}${NC}"
        echo -e "  ${MAGENTA}╚══════════════════════════════════════════════════════════╝${NC}"
        save_score 0 1
        press_enter
        return 0
      fi
      echo -e "  ${DIM}  Try again...${NC}"
    fi
  done
}

# ── ask_open: typed free answer, correct on keyword match ────────────────────
# ask_open "Question" "keyword1|keyword2" "explanation shown on fail"
ask_open() {
  local question="$1"
  local keywords="$2"
  local explanation="$3"
  local tries=0
  local first_time=1

  # Save state for undo functionality
  local score_before="${SCORE_CORRECT}" max_before="${SCORE_TOTAL}"

  while true; do
    if [[ ${first_time} -eq 1 ]]; then
      clear
      first_time=0
    fi
    echo ""
    echo -e "${BOLD}${WHITE}  Q: ${question}${NC}"
    printf "  ${YELLOW}Answer: ${NC}"

    # Read first character to check for Ctrl+N or Ctrl+B
    read -rsn1 ans_first

    # Check for Ctrl+N (skip with correct) or Ctrl+B (undo)
    if [[ "$ans_first" == $'\x0e' ]]; then  # Ctrl+N
      echo
      printf "  ${YELLOW}[SKIPPED - Mark as correct]${NC}\n"
      echo -e "  ${G}${BOLD}✓ Correct!${NC}"
      save_score 1 1
      sleep 0.5
      return 0
    elif [[ "$ans_first" == $'\x02' ]]; then  # Ctrl+B
      echo
      printf "  ${YELLOW}[UNDO - Question reset]${NC}\n"
      SCORE_CORRECT="${score_before}"
      SCORE_TOTAL="${max_before}"
      echo "${SCORE_CORRECT} ${SCORE_TOTAL}" > "${SCORE_FILE}"
      sleep 0.5
      return 0
    fi

    # Echo first character and read rest of line
    printf "%s" "$ans_first"
    local ans_rest
    read -r ans_rest
    local ans="${ans_first}${ans_rest}"

    local lans="${ans,,}"  # lowercase

    local matched=false
    IFS='|' read -ra kw_list <<< "${keywords}"
    for kw in "${kw_list[@]}"; do
      if [[ "${lans}" == *"${kw,,}"* ]]; then
        matched=true; break
      fi
    done

    if $matched; then
      if [[ ${tries} -eq 0 ]]; then
        echo -e "  ${G}${BOLD}✓ Correct!${NC}"
        save_score 1 1
        sleep 0.8
        return 0
      else
        echo -e "  ${G}✓ Correct this time.${NC}"
        save_score 0 1
        sleep 0.8
        return 0
      fi
    else
      (( tries++ ))
      echo -e "  ${R}✗ Not quite.${NC}"
      if [[ ${tries} -ge 2 ]]; then
        echo ""
        echo -e "  ${MAGENTA}╔══ EXPLANATION ═══════════════════════════════════════════╗${NC}"
        echo -e "${explanation}" | while IFS= read -r line; do
          echo -e "  ${MAGENTA}║${NC}  ${line}"
        done
        echo -e "  ${MAGENTA}╚══════════════════════════════════════════════════════════╝${NC}"
        save_score 0 1
        press_enter
        return 0
      fi
      echo -e "  ${DIM}  Try again (include the key term)...${NC}"
    fi
  done
}

# ─────────────────────────────────────────────────────────────────────────────
# ZONES
# ─────────────────────────────────────────────────────────────────────────────

zone1_osi_model() {
  header
  echo -e "${CYAN}${BOLD}  ┌─────────────────────────────────────────────┐"
  echo -e "  │  ZONE 1 — The TCP/IP & OSI Model             │"
  echo -e "  └─────────────────────────────────────────────┘${NC}"
  echo ""
  echo -e "  The OSI model has 7 layers. The TCP/IP model simplifies"
  echo -e "  to 4 layers — combining the bottom two and the top three."
  echo ""
  echo -e "  ${BOLD}OSI (7 layers)         TCP/IP (4 layers)${NC}"
  echo -e "  ${YELLOW}┌──────────────────┐   ┌──────────────────────┐${NC}"
  echo -e "  ${YELLOW}│ 7. Application   │   │                      │${NC}"
  echo -e "  ${YELLOW}│ 6. Presentation  │   │  4. Application      │${NC}"
  echo -e "  ${YELLOW}│ 5. Session       │   │     (HTTP, DNS, SSH) │${NC}"
  echo -e "  ${YELLOW}├──────────────────┤   ├──────────────────────┤${NC}"
  echo -e "  ${CYAN}│ 4. Transport     │   │  3. Transport        │${NC}"
  echo -e "  ${CYAN}│   (TCP, UDP)     │   │     (TCP, UDP, ports)│${NC}"
  echo -e "  ${CYAN}├──────────────────┤   ├──────────────────────┤${NC}"
  echo -e "  ${G}│ 3. Network       │   │  2. Internet         │${NC}"
  echo -e "  ${G}│   (IP addresses) │   │     (IP addresses)   │${NC}"
  echo -e "  ${G}├──────────────────┤   ├──────────────────────┤${NC}"
  echo -e "  ${BLUE}│ 2. Data Link     │   │                      │${NC}"
  echo -e "  ${BLUE}│   (MAC, frames)  │   │  1. Link/Network IF  │${NC}"
  echo -e "  ${BLUE}│ 1. Physical      │   │     (MAC, cables)    │${NC}"
  echo -e "  ${BLUE}└──────────────────┘   └──────────────────────┘${NC}"
  echo ""
  press_enter

  ask_q \
    "How many layers does the TCP/IP model have?" \
    "4" \
    "4" "5" "7" "3"

  ask_q \
    "Which TCP/IP layer handles IP addresses and routing?" \
    "Internet layer (Layer 2 in TCP/IP)" \
    "Transport layer" \
    "Internet layer (Layer 2 in TCP/IP)" \
    "Link layer" \
    "Application layer"

  ask_q \
    "Which TCP/IP layer does TCP and UDP belong to?" \
    "Transport layer" \
    "Internet layer" \
    "Transport layer" \
    "Application layer" \
    "Link layer"

  ask_q \
    "WireShark shows: Frame, Ethernet II, IPv4, TCP — which layer is 'Ethernet II'?" \
    "Link/Network Interface layer (MAC, frames)" \
    "Internet layer (IP)" \
    "Transport layer (TCP)" \
    "Link/Network Interface layer (MAC, frames)" \
    "Application layer"

  ask_q \
    "The OSI model has 7 layers. What is the key difference between OSI and TCP/IP?" \
    "TCP/IP combines the bottom 2 OSI layers AND the top 3 OSI layers (= 4 total)" \
    "TCP/IP only covers the top 4 layers" \
    "TCP/IP combines the bottom 2 OSI layers AND the top 3 OSI layers (= 4 total)" \
    "TCP/IP is the same as OSI but with different names" \
    "OSI has more protocols than TCP/IP"

  echo ""
  echo -e "${G}${BOLD}  ✓ Zone 1 complete!${NC}"
  score_bar
  zone_complete 1
  press_enter
}

# ─────────────────────────────────────────────────────────────────────────────

zone2_ip_mac() {
  header
  echo -e "${CYAN}${BOLD}  ┌─────────────────────────────────────────────┐"
  echo -e "  │  ZONE 2 — IP Addresses & MAC Addresses       │"
  echo -e "  └─────────────────────────────────────────────┘${NC}"
  echo ""
  echo -e "  ${BOLD}IP Address${NC} = logical address. Assigned by network."
  echo -e "  Lives on the ${YELLOW}Internet layer${NC} (Layer 3 OSI / Layer 2 TCP/IP)."
  echo ""
  echo -e "  ${BOLD}MAC Address${NC} = physical hardware address. Burned into your NIC."
  echo -e "  Lives on the ${BLUE}Data Link layer${NC} (Layer 2 OSI / Layer 1 TCP/IP)."
  echo ""
  echo -e "  ${BOLD}Local (private) addresses:${NC}"
  echo -e "    10.x.x.x        (e.g. on a campus network)"
  echo -e "    192.168.x.x     (e.g. at home)"
  echo -e "    172.16.x.x      (e.g. mobile hotspot)"
  echo ""
  echo -e "  ${BOLD}Public address:${NC} unique globally, routable on the internet."
  echo -e "  Your router does NAT: many private IPs share one public IP."
  echo ""
  echo -e "  ${DIM}  Find your local IP:  ifconfig (Mac/Linux)  /  ipconfig (Windows)"
  echo -e "  Find your public IP: visit ipinfo.io or similar${NC}"
  echo ""
  press_enter

  ask_q \
    "What is the key difference between an IP address and a MAC address?" \
    "IP is logical/network-assigned; MAC is physical/hardware-burned-in" \
    "IP is 48 bits; MAC is 32 bits" \
    "IP is physical/hardware-burned-in; MAC is logical/network-assigned" \
    "IP is logical/network-assigned; MAC is physical/hardware-burned-in" \
    "They are the same thing with different names"

  ask_q \
    "You see 192.168.1.45 in your ifconfig. What type of address is this?" \
    "Private (local) IP address — not routable on the public internet" \
    "Public IP address" \
    "MAC address" \
    "IPv6 address" \
    "Private (local) IP address — not routable on the public internet"

  ask_q \
    "Why can you NOT see example.com\'s MAC address in WireShark when you visit example.com?" \
    "MAC addresses only work locally between two directly connected devices" \
    "example.com does not have a MAC address" \
    "WireShark does not support MAC address display" \
    "MAC addresses are encrypted by HTTPS" \
    "MAC addresses only work locally between two directly connected devices"

  ask_q \
    "Which command finds your local IP address on a Mac?" \
    "ifconfig" \
    "ipconfig" \
    "ifconfig" \
    "netstat" \
    "traceroute"

  echo ""
  echo -e "${G}${BOLD}  ✓ Zone 2 complete!${NC}"
  score_bar
  zone_complete 2
  press_enter
}

# ─────────────────────────────────────────────────────────────────────────────

zone3_router_switch_ports() {
  header
  echo -e "${CYAN}${BOLD}  ┌─────────────────────────────────────────────┐"
  echo -e "  │  ZONE 3 — Router, Switch & Ports             │"
  echo -e "  └─────────────────────────────────────────────┘${NC}"
  echo ""
  echo -e "  ${BOLD}Switch${NC} = operates at Layer 2 (MAC addresses)."
  echo -e "  Forwards frames to the correct device on the SAME network."
  echo -e "  Like a post room inside one building — knows every desk."
  echo ""
  echo -e "  ${BOLD}Router${NC} = operates at Layer 3 (IP addresses)."
  echo -e "  Routes packets BETWEEN different networks."
  echo -e "  Like a post office that knows how to reach other cities."
  echo ""
  echo -e "  ${BOLD}DHCP${NC} = Dynamic Host Configuration Protocol."
  echo -e "  Automatically assigns IP addresses to devices on a network."
  echo -e "  Your router runs a DHCP server — that's how your phone gets 192.168.x.x."
  echo ""
  echo -e "  ${BOLD}Ports:${NC} Transport layer numbers that identify which app gets the data."
  echo ""
  echo -e "  ${YELLOW}  Port  │ Protocol${NC}"
  echo -e "  ${YELLOW}  ──────┼─────────────────────────────────────${NC}"
  echo -e "    22   │ SSH"
  echo -e "    53   │ DNS (UDP)"
  echo -e "    80   │ HTTP"
  echo -e "    443  │ HTTPS (TLS)"
  echo -e "    3306 │ MySQL"
  echo -e "    5432 │ PostgreSQL"
  echo -e "    8080 │ Common dev/app port"
  echo ""
  press_enter

  ask_q \
    "What is the main difference between a router and a switch?" \
    "Switch routes by MAC (same network); Router routes by IP (between networks)" \
    "They do the same thing but at different speeds" \
    "Router routes by MAC (same network); Switch routes by IP (between networks)" \
    "Switch routes by MAC (same network); Router routes by IP (between networks)" \
    "Routers are only used in datacenters, switches are for home use"

  ask_q \
    "What does DHCP do?" \
    "Automatically assigns IP addresses to devices on a network" \
    "Encrypts network traffic" \
    "Translates domain names to IP addresses" \
    "Automatically assigns IP addresses to devices on a network" \
    "Manages firewall rules"

  ask_q \
    "What standard port does HTTPS use?" \
    "443" \
    "80" \
    "8080" \
    "443" \
    "22"

  ask_q \
    "What standard port does SSH use?" \
    "22" \
    "22" \
    "21" \
    "53" \
    "443"

  ask_q \
    "What is a port, and why do we have ports?" \
    "A number that tells the OS which application should receive the incoming data" \
    "A physical socket on the network card" \
    "A number that identifies which network the packet belongs to" \
    "A number that tells the OS which application should receive the incoming data" \
    "A firewall rule for blocking traffic"

  echo ""
  echo -e "${G}${BOLD}  ✓ Zone 3 complete!${NC}"
  score_bar
  zone_complete 3
  press_enter
}

# ─────────────────────────────────────────────────────────────────────────────

zone4_tcp_packet() {
  header
  echo -e "${CYAN}${BOLD}  ┌─────────────────────────────────────────────┐"
  echo -e "  │  ZONE 4 — TCP Packet Fields (SRC/DST/ACK/TTL)│"
  echo -e "  └─────────────────────────────────────────────┘${NC}"
  echo ""
  echo -e "  WireShark shows this for a TCP/IP packet:"
  echo ""
  echo -e "  ${DIM}  Frame 54243: 66 bytes"
  echo -e "  ${BLUE}  Ethernet II, Src: 08:bf:b8:0b:fd:a8, Dst: 60:3e:5f:57:59:58${NC}"
  echo -e "  ${G}  Internet Protocol v4, Src: 185.67.45.84, Dst: 192.168.50.38, TTL: 64${NC}"
  echo -e "  ${CYAN}  Transmission Control Protocol, Src Port: 443, Dst Port: 50060, Seq: 4331, Ack: 1408${NC}"
  echo ""
  echo -e "  ${BOLD}IP layer fields:${NC}"
  echo -e "    ${G}Src${NC} = source IP — who sent this packet"
  echo -e "    ${G}Dst${NC} = destination IP — where it is going"
  echo -e "    ${G}TTL (Time To Live)${NC} = max hops before packet is dropped"
  echo -e "    ${DIM}  Better name: 'hopcount'. Each router decrements by 1. Hits 0 = discarded.${NC}"
  echo -e "    ${DIM}  Use traceroute to visualise the hops!${NC}"
  echo ""
  echo -e "  ${BOLD}TCP layer fields:${NC}"
  echo -e "    ${CYAN}Src Port${NC} = which port on the sender"
  echo -e "    ${CYAN}Dst Port${NC} = which port on the receiver (e.g. 443 = HTTPS)"
  echo -e "    ${CYAN}Ack${NC}     = acknowledgement — TCP confirms each segment received"
  echo -e "    ${DIM}  Ack is what makes TCP reliable. UDP does not have Ack.${NC}"
  echo ""
  echo -e "  ${BOLD}⚠  TTL in DNS means something different!${NC}"
  echo -e "  ${DIM}  In DNS: TTL = seconds before a cached record expires${NC}"
  echo -e "  ${DIM}  In TCP: TTL = max hop count (should be called 'hopcount')${NC}"
  echo ""
  press_enter

  ask_q \
    "In a TCP packet: what does 'Src Port' tell you?" \
    "Which port on the SENDING device this data comes from" \
    "Which port the data is going TO on the destination" \
    "Which port on the SENDING device this data comes from" \
    "The IP address of the sender" \
    "The number of bytes in the packet"

  ask_q \
    "What does ACK do in TCP — and which protocol does NOT have it?" \
    "ACK confirms receipt; UDP does not have ACK (unreliable)" \
    "ACK encrypts data; ICMP does not have ACK" \
    "ACK sets the TTL; IP does not have ACK" \
    "ACK confirms receipt; UDP does not have ACK (unreliable)" \
    "ACK fragments large packets; DNS does not have ACK"

  ask_q \
    "What does TTL mean in a TCP/IP packet — and what would be a better name?" \
    "Max hops before packet is dropped — better name: 'hopcount'" \
    "Seconds until the packet expires in a cache" \
    "Max hops before packet is dropped — better name: 'hopcount'" \
    "Size limit of the packet in bytes" \
    "Time to wait for an ACK before retrying"

  ask_q \
    "What is traceroute used for?" \
    "Visualising each router hop a packet takes to reach its destination" \
    "Checking if a server is online (like ping)" \
    "Showing all open ports on a remote server" \
    "Visualising each router hop a packet takes to reach its destination" \
    "Measuring the speed of a network connection"

  echo ""
  echo -e "${G}${BOLD}  ✓ Zone 4 complete!${NC}"
  score_bar
  zone_complete 4
  press_enter
}

# ─────────────────────────────────────────────────────────────────────────────

zone5_dns_basics() {
  header
  echo -e "${CYAN}${BOLD}  ┌─────────────────────────────────────────────┐"
  echo -e "  │  ZONE 5 — DNS Basics & Record Types          │"
  echo -e "  └─────────────────────────────────────────────┘${NC}"
  echo ""
  echo -e "  ${BOLD}DNS = Domain Name System${NC}"
  echo -e "  Translates human-readable domain names → IP addresses."
  echo -e "  It is decentralised and distributed — no single big database."
  echo ""
  echo -e "  ${BOLD}DNS Record Types:${NC}"
  echo ""
  echo -e "  ${YELLOW}  Type  │ Meaning                      │ Example${NC}"
  echo -e "  ${YELLOW}  ──────┼──────────────────────────────┼─────────────────────────────────${NC}"
  echo -e "    A     │ Domain → IPv4 address        │ example.com → 93.184.216.34"
  echo -e "    AAAA  │ Domain → IPv6 address        │ example.com → 2606:2800:220:1:248:1893:25c8:1946"
  echo -e "    CNAME │ Alias (domain → domain)      │ www.iana.org → iana.org"
  echo -e "    MX    │ Mail server for domain       │ gmail.com → alt1.aspmx.l.google.com"
  echo -e "    NS    │ Nameserver for domain        │ example.com → a.iana-servers.net"
  echo -e "    TXT   │ Free text / verification     │ SPF, domain ownership"
  echo -e "    PTR   │ Reverse: IP → domain         │ 'reverse DNS'"
  echo ""
  echo -e "  ${BOLD}Tools for DNS lookups:${NC}"
  echo -e "    nslookup   (Windows/Mac — basic)"
  echo -e "    host       (Mac/Linux — basic)"
  echo -e "    dig        (all — advanced, must install)"
  echo -e "    dnschecker.org  (browser — visual, all record types)"
  echo ""
  echo -e "  ${DIM}  Standard DNS port: UDP 53${NC}"
  echo ""
  press_enter

  ask_q \
    "What does a DNS A record do?" \
    "Maps a domain name to an IPv4 address" \
    "Maps a domain to another domain (alias)" \
    "Maps a domain name to an IPv4 address" \
    "Specifies the mail server for a domain" \
    "Specifies the nameserver for a domain"

  ask_q \
    "What is the difference between an A record and a CNAME record?" \
    "A = domain to IP; CNAME = domain to domain (alias)" \
    "A = domain to IPv6; CNAME = domain to IPv4" \
    "A = domain to domain (alias); CNAME = domain to IP" \
    "A = domain to IP; CNAME = domain to domain (alias)" \
    "They are identical, just different names"

  ask_q \
    "Which record type tells you which server handles email for a domain?" \
    "MX (Mail Exchange)" \
    "A record" \
    "TXT record" \
    "MX (Mail Exchange)" \
    "NS record"

  ask_q \
    "Which tool can query ALL DNS record types at once, without specifying them?" \
    "dnschecker.org (→ DNS lookup)" \
    "nslookup" \
    "dig" \
    "host" \
    "dnschecker.org (→ DNS lookup)"

  ask_q \
    "What port does DNS use by default?" \
    "UDP port 53" \
    "TCP port 80" \
    "UDP port 443" \
    "TCP port 22" \
    "UDP port 53"

  echo ""
  echo -e "${G}${BOLD}  ✓ Zone 5 complete!${NC}"
  score_bar
  zone_complete 5
  press_enter
}

# ─────────────────────────────────────────────────────────────────────────────

zone6_ttl_nameservers() {
  header
  echo -e "${CYAN}${BOLD}  ┌─────────────────────────────────────────────┐"
  echo -e "  │  ZONE 6 — TTL in DNS & Nameserver Types      │"
  echo -e "  └─────────────────────────────────────────────┘${NC}"
  echo ""
  echo -e "  ${BOLD}TTL in DNS = Time To Live (seconds before cache expires)${NC}"
  echo -e "  ${DIM}  This is different from TTL in TCP! In TCP, TTL = hopcount.${NC}"
  echo ""
  echo -e "    3600  = 1 hour"
  echo -e "    86400 = 24 hours"
  echo -e "    172800= 48 hours"
  echo ""
  echo -e "  ${G}High TTL${NC} → fast (cached), but slow to update if you change the record"
  echo -e "  ${R}Low TTL${NC}  → updates propagate fast, but more DNS lookups happen"
  echo ""
  echo -e "  ${BOLD}Tip:${NC} Lower TTL BEFORE migrating a domain. Raise it back after."
  echo ""
  echo -e "  ─────────────────────────────────────────────────────────────────"
  echo ""
  echo -e "  ${BOLD}Two types of DNS nameservers:${NC}"
  echo ""
  echo -e "  ${G}Authoritative Nameserver${NC}"
  echo -e "    → Has the ACTUAL DNS records (source of truth)"
  echo -e "    → Owned by the domain owner / DNS provider"
  echo -e "    → Does NOT cache — gives direct, final answers"
  echo -e "    → Example: a.iana-servers.net for example.com"
  echo ""
  echo -e "  ${CYAN}Caching / Recursive Resolver${NC}"
  echo -e "    → Stores copies for TTL duration"
  echo -e "    → Asks authoritative servers if cache is expired"
  echo -e "    → Your ISP runs one. Google runs 8.8.8.8"
  echo -e "    → nslookup result says 'Non-authoritative answer' → resolver answered"
  echo ""
  press_enter

  ask_q \
    "You want to migrate example.com to a new server with minimal downtime. What do you do with TTL first?" \
    "Lower the TTL to a few minutes BEFORE the migration so changes propagate fast" \
    "Raise the TTL to 86400 to avoid disruption during migration" \
    "Delete the A record first, then set a new one" \
    "Lower the TTL to a few minutes BEFORE the migration so changes propagate fast" \
    "TTL does not affect migration speed"

  ask_q \
    "nslookup example.com returns 'Non-authoritative answer'. What does this mean?" \
    "A caching resolver (not the domain owner) answered — its copy may be cached" \
    "The answer is wrong or unreliable" \
    "The domain has no authoritative server configured" \
    "A caching resolver (not the domain owner) answered — its copy may be cached" \
    "The query failed and fell back to a local file"

  ask_q \
    "What is the key difference between an authoritative nameserver and a recursive resolver?" \
    "Authoritative holds the real records; resolver caches and asks on your behalf" \
    "Authoritative only handles .dk; resolver handles all TLDs" \
    "Resolver holds the real records; authoritative caches and asks on your behalf" \
    "Authoritative holds the real records; resolver caches and asks on your behalf" \
    "They are the same thing — different names for the same role"

  ask_q \
    "Which of these correctly explains TTL in DNS vs TTL in TCP?" \
    "DNS TTL = seconds to cache; TCP TTL = max hops (hopcount)" \
    "DNS TTL = max hops; TCP TTL = seconds to cache" \
    "Both mean seconds to cache, just in different layers" \
    "DNS TTL = seconds to cache; TCP TTL = max hops (hopcount)" \
    "TTL only exists in DNS; TCP does not have a TTL field"

  echo ""
  echo -e "${G}${BOLD}  ✓ Zone 6 complete!${NC}"
  score_bar
  zone_complete 6
  press_enter
}

# ─────────────────────────────────────────────────────────────────────────────

zone7_dig_lab() {
  header
  echo -e "${CYAN}${BOLD}  ┌─────────────────────────────────────────────┐"
  echo -e "  │  ZONE 7 — Interactive dig Lab                │"
  echo -e "  │  Walk the DNS tree: root → TLD → authoritative│"
  echo -e "  └─────────────────────────────────────────────┘${NC}"
  echo ""
  echo -e "  ${BOLD}This is the exam demo they will ask you to do.${NC}"
  echo -e "  You are going to simulate being a recursive resolver."
  echo -e "  Start from a root nameserver and work your way down to the"
  echo -e "  authoritative answer for ${YELLOW}example.com${NC}."
  echo ""
  echo -e "  ${DIM}  If dig is not installed:"
  echo -e "    macOS:  brew install bind"
  echo -e "    Ubuntu: sudo apt install dnsutils"
  echo -e "    Windows: install from ISC or use WSL${NC}"
  echo ""

  # Check dig is available
  if ! command -v dig &>/dev/null; then
    echo -e "  ${R}⚠  'dig' is not installed on this system.${NC}"
    echo -e "  Install it and come back. Showing the theory walk-through instead."
    echo ""
    press_enter
    zone7_theory_only
    return
  fi

  echo -e "  ${G}  ✓ dig is available.${NC}"
  echo ""
  press_enter

  # ── STEP 1: Root nameserver ──────────────────────────────────────────────
  clear
  echo -e "${CYAN}${BOLD}  ZONE 7 — STEP 1: Ask a root nameserver${NC}"
  echo ""
  echo -e "  Root nameservers know which nameserver handles each TLD (.dk, .com etc.)"
  echo -e "  There are 13 root nameserver clusters: a.root-servers.net .. m.root-servers.net"
  echo ""
  echo -e "${BOLD}${YELLOW}  ▶  YOUR TASK:${NC}"
  echo -e "  Open a terminal and run:"
  echo ""
  echo -e "  ${CYAN}    dig @a.root-servers.net A example.com${NC}"
  echo ""
  echo -e "  Look at the ${BOLD}AUTHORITY SECTION${NC} of the output."
  echo -e "  It will list NS records — the TLD nameservers for .com"
  echo ""
  printf "  ${YELLOW}When done, press Enter...${NC}"; read -r
  echo ""

  ask_q \
    "After running 'dig @a.root-servers.net A example.com', what section gives the next step?" \
    "AUTHORITY SECTION — NS records pointing to .com TLD nameservers" \
    "ANSWER SECTION — the final IP address" \
    "QUESTION SECTION — it confirms what you asked" \
    "AUTHORITY SECTION — NS records pointing to .com TLD nameservers" \
    "ADDITIONAL SECTION — IPv6 addresses of the root server"

  ask_q \
    "Root server answered with NS records, NOT an A record. Why?" \
    "Root servers only know which nameserver handles each TLD, not the final IP" \
    "Root servers are broken and cannot return A records" \
    "example.com does not have an A record" \
    "Root servers only know which nameserver handles each TLD, not the final IP" \
    "The root server needs you to ask again with a different record type"

  # ── STEP 2: TLD nameserver ───────────────────────────────────────────────
  clear
  echo -e "${CYAN}${BOLD}  ZONE 7 — STEP 2: Ask the .com TLD nameserver${NC}"
  echo ""
  echo -e "  From Step 1, you saw NS records like:"
  echo -e "    ${DIM}com.   172800 IN NS a.gtld-servers.net.${NC}"
  echo ""
  echo -e "${BOLD}${YELLOW}  ▶  YOUR TASK:${NC}"
  echo -e "  Now ask the TLD nameserver for example.com:"
  echo ""
  echo -e "  ${CYAN}    dig @a.gtld-servers.net A example.com${NC}"
  echo ""
  echo -e "  Again, look at the ${BOLD}AUTHORITY SECTION${NC}."
  echo -e "  This time you will see NS records for example.com\'s own nameserver."
  echo ""
  printf "  ${YELLOW}When done, press Enter...${NC}"; read -r
  echo ""

  ask_q \
    "a.gtld-servers.net is the .com TLD nameserver. What did it return for 'dig @a.gtld-servers.net A example.com'?" \
    "NS records pointing to example.com\'s authoritative nameserver (a.iana-servers.net)" \
    "The final A record with example.com\'s IP address" \
    "An error — a.gtld-servers.net does not know about example.com" \
    "NS records pointing to example.com\'s authoritative nameserver (a.iana-servers.net)" \
    "A CNAME redirecting to www.example.com"

  ask_q \
    "The NS records point to a.iana-servers.net. Why is example.com\'s DNS at IANA?" \
    "example.com is managed by IANA for documentation examples" \
    "iana-servers.net is a root nameserver" \
    "iana-servers.net is the .com TLD registry" \
    "example.com is managed by IANA for documentation examples" \
    "a.iana-servers.net is Google\'s public DNS"
  # ── STEP 3: Authoritative answer ───────────────────────────────────────────
  clear
  echo -e "${CYAN}${BOLD}  ZONE 7 — STEP 3: Get the authoritative answer${NC}"
  echo ""
  echo -e "  From Step 2 you saw: ${DIM}example.com. 86400 IN NS a.iana-servers.net.${NC}"
  echo ""
  echo -e "${BOLD}${YELLOW}  ▶  YOUR TASK:${NC}"
  echo -e "  Ask the authoritative nameserver directly:"
  echo ""
  echo -e "  ${CYAN}    dig @a.iana-servers.net A example.com${NC}"
  echo ""
  echo -e "  This time the ${BOLD}ANSWER SECTION${NC} should contain the actual IP address."
  echo ""
  printf "  ${YELLOW}When done, press Enter...${NC}"; read -r
  echo ""

  ask_q \
    "What does the ANSWER SECTION contain when you ask the authoritative server a.iana-servers.net?" \
    "example.com. 86400 IN A 93.184.216.34 — the real, authoritative IP address" \
    "More NS records — it redirects to another server" \
    "An empty response — authoritative servers don't answer A queries" \
    "example.com. 86400 IN A 93.184.216.34 — the real, authoritative IP address" \
    "A CNAME record pointing to www.example.com"

  ask_q \
    "Why is this answer authoritative — unlike the nslookup answer from earlier?" \
    "a.iana-servers.net holds the ACTUAL records for example.com — it\'s the source of truth" \
    "The IP address is different from what nslookup returned" \
    "It uses TCP instead of UDP so it is more reliable" \
    "a.iana-servers.net holds the ACTUAL records for example.com — it\'s the source of truth" \
    "It has a higher TTL so it is more authoritative"

  # ── STEP 4: Additional practice ─────────────────────────────────────────
  clear
  echo -e "${CYAN}${BOLD}  ZONE 7 — STEP 4: Bonus dig commands${NC}"
  echo ""
  echo -e "  ${BOLD}Try these in your terminal:${NC}"
  echo ""
  echo -e "  ${CYAN}    dig gmail.com MX${NC}         ${DIM}# Which mail server handles email for gmail.com?${NC}"
  echo -e "  ${CYAN}    dig example.com NS${NC}       ${DIM}# Which nameservers serve example.com?${NC}"
  echo -e "  ${CYAN}    dig +trace example.com${NC}   ${DIM}# Full recursive walk in one command${NC}"
  echo -e "  ${CYAN}    nslookup example.com${NC}     ${DIM}# Simple lookup — note 'Non-authoritative answer'${NC}"
  echo ""
  printf "  ${YELLOW}When done exploring, press Enter...${NC}"; read -r

  ask_q \
    "What does 'dig +trace example.com' do?" \
    "Shows the full recursive resolution from root → TLD → authoritative in one command" \
    "Shows traceroute (network hops) to example.com\'s server" \
    "Queries all DNS record types simultaneously" \
    "Shows the full recursive resolution from root → TLD → authoritative in one command" \
    "Enables verbose DNSSEC validation output"

  echo ""
  echo -e "${G}${BOLD}  ✓ Zone 7 complete! You walked the DNS tree. 🎉${NC}"
  score_bar
  zone_complete 7
  press_enter
}

# Theory-only fallback when dig is not installed
zone7_theory_only() {
  echo ""
  echo -e "${BOLD}  DNS Resolution Flow (theory walk-through)${NC}"
  echo ""
  echo -e "  Step 1: dig @a.root-servers.net A example.com"
  echo -e "  ${DIM}  → AUTHORITY SECTION: com. 172800 IN NS a.gtld-servers.net. (and others)${NC}"
  echo -e "  ${DIM}  Root only knows which NS handles .com TLD${NC}"
  echo ""
  echo -e "  Step 2: dig @a.gtld-servers.net A example.com"
  echo -e "  ${DIM}  → AUTHORITY SECTION: example.com. 86400 IN NS a.iana-servers.net.${NC}"
  echo -e "  ${DIM}  TLD knows example.com\'s nameserver, but not the IP${NC}"
  echo ""
  echo -e "  Step 3: dig @a.iana-servers.net A example.com"
  echo -e "  ${DIM}  → ANSWER SECTION: example.com. 86400 IN A 93.184.216.34${NC}"
  echo -e "  ${DIM}  Authoritative server gives the real IP!${NC}"
  echo ""
  press_enter

  ask_q \
    "What does a root nameserver return when you ask for example.com\'s IP?" \
    "NS records pointing to the .com TLD nameservers — it doesn't know the IP itself" \
    "The final A record with example.com\'s IP" \
    "CNAME records redirecting to www.example.com" \
    "NS records pointing to the .com TLD nameservers — it doesn't know the IP itself" \
    "An error — root servers don't handle direct queries"

  ask_q \
    "After the root server, you ask a.gtld-servers.net. What does it return?" \
    "NS records pointing to example.com\'s own authoritative nameserver (a.iana-servers.net)" \
    "The final A record with example.com\'s IP" \
    "MX records for example.com\'s mail server" \
    "NS records pointing to example.com\'s own authoritative nameserver (a.iana-servers.net)" \
    "It redirects you back to the root server"

  ask_q \
    "Which server finally returns the actual A record for example.com?" \
    "a.iana-servers.net — the authoritative nameserver for example.com" \
    "a.gtld-servers.net — the .com TLD nameserver" \
    "a.root-servers.net — the root nameserver" \
    "a.iana-servers.net — the authoritative nameserver for example.com" \
    "8.8.8.8 — Google's recursive resolver"
}

# ─────────────────────────────────────────────────────────────────────────────

zone8_http() {
  header
  echo -e "${CYAN}${BOLD}  ┌─────────────────────────────────────────────┐"
  echo -e "  │  ZONE 8 — HTTP: Methods, Status Codes,       │"
  echo -e "  │            Headers & Sessions                │"
  echo -e "  └─────────────────────────────────────────────┘${NC}"
  echo ""
  echo -e "  ${BOLD}GET vs POST${NC}"
  echo -e "  ${CYAN}GET${NC}   = retrieve data. Params in URL. No body. Bookmarkable. Cached."
  echo -e "  ${CYAN}POST${NC}  = send/create data. Params in body (hidden). Not cached."
  echo ""
  echo -e "  ${BOLD}Status Codes${NC}"
  echo -e "  ${G}2xx${NC} Success       200 OK, 201 Created, 204 No Content"
  echo -e "  ${YELLOW}3xx${NC} Redirect      301 Moved Permanently, 302 Found (temp)"
  echo -e "  ${R}4xx${NC} Client Error  400 Bad Request, 401 Unauthorized,"
  echo -e "                       403 Forbidden, 404 Not Found"
  echo -e "  ${MAGENTA}5xx${NC} Server Error  500 Internal Server Error, 503 Unavailable"
  echo ""
  echo -e "  ${DIM}  If you remember only 3: 200, 404, 500${NC}"
  echo ""
  echo -e "  ${BOLD}Headers${NC}"
  echo -e "  ${CYAN}Accept${NC}        → Client tells server: 'I want this format'"
  echo -e "                    e.g. Accept: application/json"
  echo -e "  ${CYAN}Content-Type${NC}  → Describes the format of the BODY being sent"
  echo -e "                    e.g. Content-Type: application/json"
  echo ""
  echo -e "  ${BOLD}HTTP is stateless — how do you stay logged in?${NC}"
  echo -e "  → Server sends a ${CYAN}cookie${NC} via Set-Cookie header (e.g. JSESSIONID)"
  echo -e "  → Browser stores it and sends it with every request via Cookie header"
  echo -e "  → Server recognises you by the cookie value"
  echo ""
  press_enter

  ask_q \
    "When should you use POST instead of GET?" \
    "When sending data that changes server state, or sending sensitive data (e.g. passwords)" \
    "When you want the response to be cached by the browser" \
    "When you want parameters visible in the URL" \
    "When sending data that changes server state, or sending sensitive data (e.g. passwords)" \
    "POST and GET are interchangeable — use either"

  ask_q \
    "A user submits a form with their password. Which method should the form use, and why?" \
    "POST — because POST puts parameters in the body, not the URL (history/log safe)" \
    "GET — because it is faster and supports caching" \
    "POST — because it is encrypted, GET is not" \
    "POST — because POST puts parameters in the body, not the URL (history/log safe)" \
    "GET — because passwords are short enough to fit in the URL"

  ask_q \
    "A Spring Boot endpoint successfully creates a new resource. Which status code is correct REST?" \
    "201 Created" \
    "200 OK" \
    "201 Created" \
    "204 No Content" \
    "302 Found"

  ask_q \
    "What is the difference between 401 and 403?" \
    "401 = not authenticated (not logged in); 403 = authenticated but forbidden" \
    "401 = forbidden; 403 = not authenticated" \
    "Both mean the same — access denied" \
    "401 = not authenticated (not logged in); 403 = authenticated but forbidden" \
    "401 = server error; 403 = client error"

  ask_q \
    "HTTP is stateless. How does a website keep you logged in between requests?" \
    "Via cookies — the server sends a session cookie; browser resends it every request" \
    "The browser automatically re-sends your username and password each time" \
    "HTTP/2 added a persistent 'logged-in' flag to the protocol" \
    "Via cookies — the server sends a session cookie; browser resends it every request" \
    "The server stores your IP address and recognises it on future requests"

  ask_q \
    "What is the difference between the 'Accept' and 'Content-Type' headers?" \
    "Accept = what format the client wants; Content-Type = format of the body being sent" \
    "Content-Type = what format the client wants; Accept = format of the body being sent" \
    "They are the same — two names for the same concept" \
    "Accept = what format the client wants; Content-Type = format of the body being sent" \
    "Accept is only used in responses; Content-Type is only used in requests"

  echo ""
  echo -e "${G}${BOLD}  ✓ Zone 8 complete!${NC}"
  score_bar
  zone_complete 8
  press_enter
}

# ─────────────────────────────────────────────────────────────────────────────
# RESULTS SCREEN
# ─────────────────────────────────────────────────────────────────────────────

results_screen() {
  header
  read -r SC ST < "${SCORE_FILE}"
  local pct=0
  [[ ${ST} -gt 0 ]] && pct=$(( SC * 100 / ST ))

  echo -e "${BOLD}${WHITE}  ══════════════════════════════════════════${NC}"
  echo -e "${BOLD}${WHITE}     FINAL RESULTS FOR ${PLAYER_NAME}     ${NC}"
  echo -e "${BOLD}${WHITE}  ══════════════════════════════════════════${NC}"
  echo ""
  echo -e "  Questions answered: ${WHITE}${ST}${NC}"
  echo -e "  First-try correct:  ${G}${SC}${NC}"
  echo -e "  Score:              ${WHITE}${pct}%${NC}"
  echo ""
  echo -e "  Grade estimate:     $(grade_label)"
  echo ""

  if [[ ${pct} -ge 90 ]]; then
    echo -e "  ${G}${BOLD}  Outstanding. You are exam-ready for TCP/IP + DNS + HTTP.${NC}"
    echo -e "  ${G}  You can walk the DNS tree, explain every layer, and nail HTTP.${NC}"
  elif [[ ${pct} -ge 75 ]]; then
    echo -e "  ${CYAN}${BOLD}  Strong performance. A few concepts to polish.${NC}"
    echo -e "  ${CYAN}  Revisit any zones you found tricky before the exam.${NC}"
  elif [[ ${pct} -ge 60 ]]; then
    echo -e "  ${YELLOW}${BOLD}  Good base. More drilling needed on weak zones.${NC}"
    echo -e "  ${YELLOW}  Focus on the zones where you guessed. Use --zone N.${NC}"
  else
    echo -e "  ${R}${BOLD}  Keep going — more repetition needed.${NC}"
    echo -e "  ${R}  Run individual zones: bash netmaster.sh --zone 5${NC}"
  fi

  echo ""
  echo -e "  ${DIM}Zones completed:"
  for z in 1 2 3 4 5 6 7 8; do
    local name
    case $z in
      1) name="OSI/TCP-IP Model";;
      2) name="IP & MAC Addresses";;
      3) name="Router, Switch & Ports";;
      4) name="TCP Packet Fields";;
      5) name="DNS Basics & Records";;
      6) name="TTL & Nameserver Types";;
      7) name="dig Lab (root → TLD → Authoritative)";;
      8) name="HTTP Methods, Status Codes & Headers";;
    esac
    if zone_done $z; then
      echo -e "    ${G}✓${NC} ${DIM}Zone ${z}: ${name}${NC}"
    else
      echo -e "    ${R}○${NC} ${DIM}Zone ${z}: ${name}${NC}"
    fi
  done
  echo -e "${NC}"
  echo ""
  echo -e "${DIM}  ───────────────────────────────────────────────────────────────────${NC}"
  echo ""
  printf "  ${G}Thanks for playing netmaster, ${BOLD}%s${NC}${G}!${NC}\n" "${PLAYER_NAME}"
  printf "  ${DIM}Star the repo: https://github.com/bixson/netmaster${NC}\n"
  echo ""
  log "Session ended. Score: ${SC}/${ST} (${pct}%)"
  press_enter
}

# ─────────────────────────────────────────────────────────────────────────────
# ZONE MAP
# ─────────────────────────────────────────────────────────────────────────────

show_zone_map() {
  header
  echo -e "${BOLD}  ZONE MAP — TCP/IP + DNS + HTTP${NC}"
  echo ""
  echo -e "  ${DIM}  Zone  │ Topic                                    │ Status${NC}"
  echo -e "  ${DIM}  ──────┼──────────────────────────────────────────┼────────${NC}"
  local topics=("OSI/TCP-IP Model" "IP & MAC Addresses" "Router, Switch & Ports" "TCP Packet Fields (SRC/DST/ACK/TTL)" "DNS Basics & Record Types" "TTL in DNS & Nameserver Types" "dig Lab — Root → TLD → Authoritative" "HTTP Methods, Status Codes & Headers")
  for i in "${!topics[@]}"; do
    local z=$(( i + 1 ))
    if zone_done $z; then
      echo -e "    ${G}${z}${NC}     │ ${topics[$i]}  │ ${G}✓ Done${NC}"
    else
      echo -e "    ${YELLOW}${z}${NC}     │ ${topics[$i]}  │ ${DIM}○ Pending${NC}"
    fi
  done
  echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# TRAP + MAIN ENTRYPOINT
# ─────────────────────────────────────────────────────────────────────────────

on_exit() {
  echo
  echo ""
  read -r SC ST < "${SCORE_FILE}" 2>/dev/null || { SC=0; ST=0; }
  printf "  ${YELLOW}Interrupted. Score so far: %d/%d${NC}\n" "$SC" "$ST"
  log "Interrupted. Score: ${SC}/${ST}"
  exit 0
}
trap on_exit INT TERM

run_zone() {
  case "$1" in
    1) zone1_osi_model;;
    2) zone2_ip_mac;;
    3) zone3_router_switch_ports;;
    4) zone4_tcp_packet;;
    5) zone5_dns_basics;;
    6) zone6_ttl_nameservers;;
    7) zone7_dig_lab;;
    8) zone8_http;;
    *) echo -e "  ${R}Unknown zone: $1. Use 1-8.${NC}"; exit 1;;
  esac
}

main() {
  # parse args
  case "${1:-}" in
    --list)
      show_zone_map
      exit 0;;
    --reset)
      rm -f "${STATE_DIR}"/*.done "${SCORE_FILE}"
      echo "0 0" > "${SCORE_FILE}"
      echo -e "  ${G}✓ Progress reset.${NC}"
      exit 0;;
    --version)
      echo "netmaster 1.0.0"
      exit 0;;
    --help|-h)
      echo ""
      echo "  netmaster — Master TCP/IP + DNS + HTTP for a networking exam"
      echo ""
      echo "  Usage:"
      echo "    bash netmaster.sh               # full run, all 8 zones"
      echo "    bash netmaster.sh --zone N      # jump to a specific zone (1-8)"
      echo "    bash netmaster.sh --list        # show zone map"
      echo "    bash netmaster.sh --reset       # wipe saved progress"
      echo "    bash netmaster.sh --version     # version info"
      echo ""
      echo "  Zones:"
      echo "    1  OSI & TCP/IP Model"
      echo "    2  IP & MAC Addresses"
      echo "    3  Router, Switch & Ports"
      echo "    4  TCP Packet Fields (SRC, DST, ACK, TTL)"
      echo "    5  DNS Basics & Record Types"
      echo "    6  TTL in DNS & Nameserver Types"
      echo "    7  dig Lab — walk the DNS tree live (root → TLD → authoritative)"
      echo "    8  HTTP Methods, Status Codes, Headers & Sessions"
      echo ""
      echo "  Controls:"
      echo "    Ctrl+N  -- skip question and mark as correct"
      echo "    Ctrl+B  -- undo last question"
      echo ""
      exit 0;;
    --zone)
      shift
      [[ -z "${1:-}" ]] && echo "  ${R}Specify zone number: --zone N${NC}" && exit 1
      header
      score_bar
      echo ""
      run_zone "$1"
      results_screen
      exit 0;;
    "")
      # Full run
      ;;
    *)
      echo -e "  ${R}Unknown option: $1. Try --help.${NC}"
      exit 1;;
  esac

  # ── Full run ────────────────────────────────────────────────────────────
  intro

  show_zone_map
  score_bar
  echo ""
  printf "  ${YELLOW}Press Enter to begin, or Ctrl+C to exit...${NC}"; read -r

  for z in 1 2 3 4 5 6 7 8; do
    run_zone $z
  done

  results_screen
}

main "$@"
