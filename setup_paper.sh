#!/bin/bash
set -e

# ------------------------------
# Install OpenJDK 21
# ------------------------------
JDK_URL="https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.4+7/OpenJDK21U-jdk_x64_linux_hotspot_21.0.4_7.tar.gz"
JDK_ARCHIVE="jdk21.tar.gz"
JAVA_DIR=~/java

if [ ! -d "$JAVA_DIR" ]; then
    echo "[*] Downloading OpenJDK 21..."
    wget -q "$JDK_URL" -O "$JDK_ARCHIVE"
    mkdir -p "$JAVA_DIR"
    tar -xvzf "$JDK_ARCHIVE" -C "$JAVA_DIR"
    rm "$JDK_ARCHIVE"
else
    echo "[*] Java already installed, skipping..."
fi

JAVA_HOME=$(find "$JAVA_DIR" -maxdepth 1 -type d -name "jdk-21.*" | head -n 1)
PATH="$JAVA_HOME/bin:$PATH"

"$JAVA_HOME/bin/java" -version

# ------------------------------
# Download Paper server
# ------------------------------
PAPER_JAR="paper.jar"
if [ ! -f "$PAPER_JAR" ]; then
    echo "[*] Downloading Paper server..."
    wget -q https://fill-data.papermc.io/v1/objects/ab9bb1afc3cea6978a0c03ce8448aa654fe8a9c4dddf341e7cbda1b0edaa73f5/paper-1.21-130.jar -O "$PAPER_JAR"
else
    echo "[*] Paper server already exists, skipping..."
fi

# Generate eula.txt if missing
if [ ! -f eula.txt ]; then
    echo "[*] Running Paper to generate eula.txt..."
    "$JAVA_HOME/bin/java" -Xmx2G -Xms1G -jar "$PAPER_JAR" nogui || true
fi

# Accept EULA
if grep -q "eula=false" eula.txt 2>/dev/null; then
    echo "[*] Accepting Minecraft EULA..."
    sed -i 's/eula=false/eula=true/' eula.txt
fi

# ------------------------------
# Install Plugins
# ------------------------------
mkdir -p plugins

download_plugin() {
    local url="$1"
    local file="$2"
    if [ ! -f "plugins/$file" ]; then
        echo "[*] Downloading $file..."
        wget -q "$url" -O "plugins/$file"
    else
        echo "[*] $file already exists, skipping..."
    fi
}

download_plugin "https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot" "Geyser-Spigot.jar"
download_plugin "https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot" "floodgate-spigot.jar"
download_plugin "https://github.com/ViaVersion/ViaVersion/releases/download/5.4.2/ViaVersion-5.4.2.jar" "ViaVersion-5.4.2.jar"
download_plugin "https://github.com/ViaVersion/ViaBackwards/releases/download/5.4.2/ViaBackwards-5.4.2.jar" "ViaBackwards-5.4.2.jar"

# ------------------------------
# Download Playit.gg agent
# ------------------------------
if [ ! -f playit ]; then
    echo "[*] Downloading Playit.gg agent..."
    wget -q https://github.com/playit-cloud/playit-agent/releases/download/v0.16.2/playit-linux-amd64 -O playit
    chmod +x playit
else
    echo "[*] Playit agent already exists, skipping..."
fi

# ------------------------------
# Run Playit and Paper server
# ------------------------------
echo "[*] Starting Playit.gg tunnel and PaperMC server..."

# Kill old playit process if running
if pgrep -x "playit" >/dev/null; then
    echo "[*] Stopping existing Playit process..."
    pkill -x playit
fi

# Start Playit in background
./playit &

# Start Paper server in foreground
"$JAVA_HOME/bin/java" -Xmx6G -Xms1G -jar "$PAPER_JAR" nogui
