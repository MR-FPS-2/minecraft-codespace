# 🎮 Minecraft Forge Server on GitHub Codespaces

> Free **modded** Minecraft Java server (Forge) with a real IP:PORT — no VPS, no credit card.  
> World and mods are version-controlled in this repo, so you can blow away the Codespace anytime and pick up where you left off.

---

## ✨ What This Does

- Installs a **Forge** modded server — Minecraft **26.1.2** by default
- Exposes it to the internet via **playit.gg** (real IP:PORT for friends to connect)
- **Saves your world + mods to this GitHub repo** (manually with `save.sh`, or automatically every 30 min)
- **Restores everything** on a brand-new Codespace with `import.sh`
- One script runs the whole server: `bash start.sh`

---

## 📋 Requirements

- A GitHub account *(secondary account recommended)*
- A free [playit.gg](https://playit.gg) account *(created during first run)*

---

## 🚀 First-Time Setup

### Step 1 — Fork this repository

Click **Fork** at the top of this page.
> ⚠️ Use a secondary GitHub account if possible.

### Step 2 — Create a Codespace

1. Green **`< > Code`** button → **Codespaces** tab → **Create codespace on master**
2. Wait 2–3 minutes — Java 25 and jq install automatically

### Step 3 — Add mods *(optional, before first start)*

Drop any `.jar` mod files into the `mods/` folder. You can also add them later and just restart the server.

### Step 4 — Run the server

```bash
bash start.sh
```

This automatically:
- Resolves and downloads the latest Forge build for Minecraft 26.1.2
- Installs the Forge server (~150–300MB of libraries, first run only)
- Loads any mods from `mods/`
- Downloads `playit-cli` + `playitd`
- Starts the server and waits for it to fully load
- Starts the playit tunnel
- Enables auto-save to GitHub every 30 minutes

### Step 5 — Claim your playit.gg account *(first time only)*

A claim URL will appear:

```
visit https://playit.gg/account/sign-up?code=XXXXXX
```

1. Open it in your browser
2. Sign up for a **free** playit.gg account → **Accept**
3. **Tunnels** → **Add Tunnel** → Type: **Minecraft Java** → Port: **25565** → **Add**

### Step 6 — Get your IP:PORT

```
[INFO] Tunnel active!
abc123.mc.playit.gg:12345   ← share this with friends
```

### Step 7 — Connect in Minecraft

**Multiplayer** → **Add Server** → paste the address → **Join Server**

> ⚠️ Friends need the **same mods installed** in their Minecraft launcher (matching Forge + mod versions) to join a modded server.

---

## 💾 Saving Your World + Mods

### Manual save — run anytime:

```bash
bash save.sh
```

This archives `world/` into `world.tar.gz` (keeps the repo fast — a Minecraft world has thousands of tiny files, so it's compressed into one) and commits + pushes:
- `world.tar.gz`
- `mods/`
- `server.properties`, `eula.txt`
- `ops.json`, `whitelist.json`, `banned-players.json`, `banned-ips.json`

### Auto-save

`start.sh` runs `save.sh` automatically every 30 minutes in the background. No action needed.

### First-time git setup

Before your first save, tell git who you are:

```bash
git config user.email "you@example.com"
git config user.name "Your Name"
```

---

## 📥 Restoring on a New Codespace

If you delete your Codespace and create a fresh one, the repo (with your saved `world.tar.gz` and `mods/`) is cloned automatically. To unpack everything and check what's there:

```bash
bash import.sh
```

Then start the server normally:

```bash
bash start.sh
```

> `import.sh` won't overwrite an existing local `world/` folder that already has data — it only restores when starting fresh, so it's safe to run anytime.

---

## 🧹 Wiping the World Completely (No Trace Left in the Repo)

If you want to start completely clean with **nothing** left in repo history:

### Option A — Simplest (recommended): delete and re-fork

1. On GitHub, go to your forked repo → **Settings** → scroll to **Danger Zone** → **Delete this repository**
2. Fork the original repo again — you get a 100% clean copy with zero history

This is the only way to guarantee old map data isn't recoverable from git history.

### Option B — Keep the repo, reset history with an orphan branch

This keeps your repo URL but wipes all commit history:

```bash
git checkout --orphan clean-slate
git rm -rf world.tar.gz world mods 2>/dev/null
git add .
git commit -m "Fresh start"
git branch -D master
git branch -m master
git push -f origin master
```

> ⚠️ Option B rewrites history — anyone else with a clone of the repo will need to re-clone.

---

## ⚙️ Server Settings

Edit `server.properties`:

| Setting | Default | Description |
|---|---|---|
| `max-players` | 10 | Max players |
| `difficulty` | normal | peaceful / easy / normal / hard |
| `gamemode` | survival | survival / creative / adventure |
| `online-mode` | false | `true` = premium accounts only |
| `pvp` | true | Player vs player combat |
| `level-seed` | *(empty)* | World generation seed |

Restart with `bash start.sh` after editing.

---

## 🔧 Changing the Minecraft/Forge Version

Open `start.sh` and edit the line near the top:

```bash
MC_VERSION="26.1.2"   # ← change this
```

Set it to any version listed at [files.minecraftforge.net](https://files.minecraftforge.net/), e.g. `MC_VERSION="1.21.11"`. The script automatically resolves and installs the latest Forge build for whichever version you set. Delete `run.sh` and `libraries/` first if you're switching from an already-installed version:

```bash
rm -rf run.sh libraries
bash start.sh
```

---

## 🧩 Adding / Removing Mods

1. Drop `.jar` mod files into `mods/` (or delete ones you don't want)
2. Restart: `bash start.sh`
3. Save the change: `bash save.sh`

> Make sure mods match your Forge **Minecraft version** (26.1.2 by default) — mixing versions will crash the server. Check each mod's page (CurseForge/Modrinth) for the supported version before downloading.

---

## ⚠️ Limits

| Item | Details |
|---|---|
| ⏱️ Free hours | 60 hrs/month per GitHub account |
| 🔄 IP stability | Stable while the Codespace is running |
| 💾 Data | Saved to GitHub via `save.sh` / auto-save |
| 🔁 Restart | `bash import.sh` then `bash start.sh` |

> **Stop the Codespace when not playing** to save your free hours:  
> GitHub → Codespaces → **Stop codespace**

---

## 📁 File Structure

```
minecraft-codespace/
├── .devcontainer/
│   └── devcontainer.json   ← Java 25 + jq environment
├── start.sh                ← Installs Forge, starts server + tunnel + auto-save
├── save.sh                 ← Archives & pushes world + mods to GitHub
├── import.sh                ← Restores world + mods on a fresh Codespace
├── .gitignore               ← Keeps regenerable files out of git
└── README.md                ← This file
```

*Committed to the repo (your data):*
```
├── world.tar.gz             ← Compressed world save
├── mods/                    ← Your mod .jar files
├── server.properties
├── eula.txt
```

*Auto-generated locally, not committed (regenerated by start.sh):*
```
├── forge-installer.jar
├── libraries/                ← Forge + Minecraft libraries
├── run.sh / user_jvm_args.txt
├── playit-cli / playitd
└── world/                    ← Live world (archived into world.tar.gz by save.sh)
```

---

## 🆘 Troubleshooting

**Java version error?**  
Rebuild the container: `Ctrl+Shift+P` → `Rebuild Container`

**World locked / session.lock error?**
```bash
kill "$(cat mc.pid)" 2>/dev/null; rm -f world/session.lock; bash start.sh
```

**playit tunnel not connecting?**
```bash
pkill -f playit
export XDG_RUNTIME_DIR=/tmp/playit-run; mkdir -p "$XDG_RUNTIME_DIR"
./playitd --socket-path=./playit.sock --secret-path=~/.config/playit_gg/playit.toml &
sleep 3
./playit-cli --socket-path=./playit.sock
```

**Push failing (file too large)?**  
GitHub rejects files over 100MB. If `world.tar.gz` grows past that, consider [Git LFS](https://git-lfs.com/) for it.

**Server crashes right after a mod is added?**  
Check `logs/latest.log` — usually a mod version mismatch with `MC_VERSION` in `start.sh`.

---

> Free forever · Powered by GitHub Codespaces + Forge + playit.gg
