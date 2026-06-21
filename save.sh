#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}💾 Saving world + mods to GitHub...${NC}"

# ===== Ensure .gitignore is set up =====
if [ ! -f .gitignore ] || ! grep -q "^fabric-server.jar" .gitignore 2>/dev/null; then
    cat > .gitignore << 'EOF'
# Regenerable server binaries
fabric-server.jar
*-installer.jar
*-installer.jar.log

# Forge / NeoForge generated server files
libraries/
run.sh
run.bat
user_jvm_args.txt

# Fabric loader cache
.fabric/

# Logs & crash reports
logs/
crash-reports/
*.log

# playit.gg
playit-cli
playitd
playit.sock

# Runtime (world is committed as world.tar.gz instead)
mc.pid
world/
EOF
    echo -e "${GREEN}[✓] .gitignore set up${NC}"
fi

# ===== Archive the world (avoids committing thousands of tiny chunk files) =====
if [ -d world ]; then
    echo -e "${YELLOW}[+] Archiving world/...${NC}"
    tar --exclude='session.lock' -czf world.tar.gz world/
    echo -e "${GREEN}[✓] world.tar.gz created ($(du -sh world.tar.gz | cut -f1))${NC}"
else
    echo -e "${YELLOW}[i] No world/ folder yet — server hasn't generated one.${NC}"
fi

# ===== Stage everything important =====
# .loader is committed so a fresh Codespace remembers your chosen mod loader.
git add world.tar.gz \
        .loader \
        mods/ \
        server.properties \
        eula.txt \
        ops.json \
        whitelist.json \
        banned-players.json \
        banned-ips.json \
        .gitignore \
        2>/dev/null

if git diff --cached --quiet; then
    echo -e "${YELLOW}[i] Nothing new to save.${NC}"
    exit 0
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
git commit -m "💾 Save — ${TIMESTAMP}"

if git push; then
    echo -e "${GREEN}[✓] Saved to GitHub at ${TIMESTAMP}${NC}"
else
    echo -e "${RED}[✗] Push failed. Check 'git remote -v' and that you have write access.${NC}"
    exit 1
fi
