#!/bin/bash

# ===== Configuration =====
MC_VERSION="26.1.2"   # ← Minecraft version. Change this to switch versions.
# ==========================

# ===== Colors =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════╗"
echo "║  🎮  Minecraft Fabric Server - Codespaces    ║"
echo "║      Minecraft ${MC_VERSION} (Fabric)             ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# ===== Install jq if missing =====
if ! command -v jq &>/dev/null; then
    echo -e "${YELLOW}[+] Installing jq...${NC}"
    sudo apt-get update -qq && sudo apt-get install -y jq -qq
    echo -e "${GREEN}[✓] jq installed${NC}"
fi

# ===== Helper: valid binary = file exists and is bigger than threshold =====
is_valid_binary() {
    local f="$1"
    local min_size="${2:-1000000}"
    local size
    size=$(stat -c%s "$f" 2>/dev/null || echo 0)
    [ -f "$f" ] && [ "$size" -gt "$min_size" ]
}

# ===== Install Fabric server (only if not already installed) =====
if is_valid_binary "fabric-server.jar" 500000; then
    echo -e "${GREEN}[✓] Fabric server already installed${NC}"
else
    echo -e "${YELLOW}[+] Resolving latest Fabric loader for Minecraft ${MC_VERSION}...${NC}"

    LOADER_VERSION=$(curl -sf "https://meta.fabricmc.net/v2/versions/loader/${MC_VERSION}" \
        | jq -r '.[0].loader.version // empty')

    if [ -z "$LOADER_VERSION" ]; then
        echo -e "${RED}[✗] No Fabric loader found for MC ${MC_VERSION}.${NC}"
        echo -e "${YELLOW}    Check supported versions at https://fabricmc.net/${NC}"
        exit 1
    fi
    echo -e "${GREEN}[✓] Fabric loader ${LOADER_VERSION}${NC}"

    INSTALLER_VERSION=$(curl -sf "https://meta.fabricmc.net/v2/versions/installer" \
        | jq -r '.[0].version // empty')

    if [ -z "$INSTALLER_VERSION" ]; then
        echo -e "${RED}[✗] Could not resolve Fabric installer version.${NC}"
        exit 1
    fi
    echo -e "${GREEN}[✓] Fabric installer ${INSTALLER_VERSION}${NC}"

    SERVER_JAR_URL="https://meta.fabricmc.net/v2/versions/loader/${MC_VERSION}/${LOADER_VERSION}/${INSTALLER_VERSION}/server/jar"
    echo -e "${YELLOW}[+] Downloading Fabric server jar...${NC}"
    curl -L "$SERVER_JAR_URL" -o fabric-server.jar --progress-bar

    if ! is_valid_binary "fabric-server.jar" 500000; then
        echo -e "${RED}[✗] Fabric server download failed!${NC}"
        exit 1
    fi
    echo -e "${GREEN}[✓] Fabric server installed ($(du -sh fabric-server.jar | cut -f1))${NC}"
fi

# ===== Accept EULA =====
echo "eula=true" > eula.txt
echo -e "${GREEN}[✓] EULA accepted${NC}"

# ===== Create server.properties if missing =====
if [ ! -f "server.properties" ]; then
    cat > server.properties << 'EOF'
server-port=25565
max-players=10
online-mode=false
difficulty=normal
gamemode=survival
level-seed=
level-name=world
motd=\u00A7a\u00A7lMy Codespace Fabric Server
pvp=true
allow-flight=true
spawn-protection=16
view-distance=10
simulation-distance=10
spawn-monsters=true
spawn-animals=true
enable-command-block=true
EOF
    echo -e "${GREEN}[✓] server.properties created${NC}"
else
    echo -e "${GREEN}[✓] server.properties already exists${NC}"
fi

# ===== Mods folder =====
mkdir -p mods
MOD_COUNT=$(find mods -maxdepth 1 -name "*.jar" 2>/dev/null | wc -l)
if [ "$MOD_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}[i] No mods in mods/ — drop .jar files there and restart to load them.${NC}"
    echo -e "${YELLOW}    Most mods also need Fabric API — grab it from modrinth.com/mod/fabric-api${NC}"
else
    echo -e "${GREEN}[✓] ${MOD_COUNT} mod(s) loaded from mods/${NC}"
fi

# ===== Download playit.gg (CLI + daemon) =====
if is_valid_binary "./playit-cli" && is_valid_binary "./playitd"; then
    echo -e "${GREEN}[✓] playit already installed${NC}"
else
    echo -e "${YELLOW}[+] Downloading playit.gg...${NC}"

    curl -L "https://github.com/playit-cloud/playit-agent/releases/download/v1.0.10/playit-cli-linux-amd64" \
        -o playit-cli --progress-bar
    chmod +x playit-cli

    curl -L "https://github.com/playit-cloud/playit-agent/releases/download/v1.0.10/playit-linux-amd64" \
        -o playitd --progress-bar
    chmod +x playitd

    if ! is_valid_binary "./playit-cli" || ! is_valid_binary "./playitd"; then
        echo -e "${RED}[✗] playit download failed!${NC}"
        exit 1
    fi
    echo -e "${GREEN}[✓] playit installed${NC}"
fi

# ===== Start Minecraft Server =====
echo ""
# Kill any existing server instance (tracked via PID file)
if [ -f mc.pid ] && kill -0 "$(cat mc.pid)" 2>/dev/null; then
    echo -e "${YELLOW}[!] Stopping existing server instance...${NC}"
    kill "$(cat mc.pid)"
    sleep 5
fi
rm -f world/session.lock

echo -e "${YELLOW}[+] Starting Fabric server...${NC}"
java -Xmx2G -Xms1G -jar fabric-server.jar nogui &
MC_PID=$!
echo "$MC_PID" > mc.pid

echo -e "${YELLOW}[⏳] Waiting for server to fully start...${NC}"
TIMEOUT=180
ELAPSED=0
STARTED=false
while [ $ELAPSED -lt $TIMEOUT ]; do
    if [ -f logs/latest.log ] && grep -q "Done (" logs/latest.log 2>/dev/null; then
        STARTED=true
        break
    fi
    if ! kill -0 "$MC_PID" 2>/dev/null; then
        echo ""
        echo -e "${RED}[✗] Server crashed during startup! Check logs/latest.log${NC}"
        exit 1
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
    echo -ne "${CYAN}.${NC}"
done
echo ""

if [ "$STARTED" = true ]; then
    echo -e "${GREEN}[✓] Minecraft server is running on port 25565!${NC}"
else
    echo -e "${YELLOW}[!] Still starting after ${TIMEOUT}s — continuing anyway, check logs/latest.log${NC}"
fi
echo ""

# ===== Auto-save every 30 minutes =====
(
    while true; do
        sleep 1800
        echo -e "${YELLOW}[⟳] Auto-saving world + mods to GitHub...${NC}"
        bash save.sh && echo -e "${GREEN}[✓] Auto-save complete${NC}" || echo -e "${RED}[✗] Auto-save failed${NC}"
    done
) &
echo -e "${GREEN}[✓] Auto-save enabled (every 30 min) — run 'bash save.sh' anytime to save manually${NC}"
echo ""

# ===== Start playit.gg tunnel =====
echo -e "${CYAN}══════════════════════════════════════${NC}"
echo -e "${BLUE}[+] Starting playit.gg tunnel...${NC}"
echo -e "${CYAN}══════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}  First time? Here's what to do:${NC}"
echo -e "  1. A claim URL will appear below"
echo -e "  2. Open it in your browser"
echo -e "  3. Sign up / log in to playit.gg"
echo -e "  4. Add a Minecraft Java tunnel on port 25565"
echo -e "  5. Your IP:PORT will be shown here ✅"
echo ""
echo -e "${CYAN}══════════════════════════════════════${NC}"
echo ""

export XDG_RUNTIME_DIR=/tmp/playit-run
mkdir -p "$XDG_RUNTIME_DIR"
mkdir -p ~/.config/playit_gg

./playitd --socket-path=./playit.sock --secret-path=~/.config/playit_gg/playit.toml &
sleep 3
./playit-cli --socket-path=./playit.sock
