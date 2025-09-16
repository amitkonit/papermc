#!/bin/bash
set -e

# ------------------------------
# Install OpenJDK 21
# ------------------------------
echo "[*] Downloading OpenJDK 21..."
wget -q https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.4+7/OpenJDK21U-jdk_x64_linux_hotspot_21.0.4_7.tar.gz -O jdk21.tar.gz

echo "[*] Extracting JDK..."
mkdir -p ~/java
tar -xvzf jdk21.tar.gz -C ~/java
rm jdk21.tar.gz

# Set JAVA_HOME and PATH
JAVA_HOME=$(find ~/java -maxdepth 1 -type d -name "jdk-21.*" | head -n 1)
PATH="$JAVA_HOME/bin:$PATH"

echo "[*] Java installed at $JAVA_HOME"
"$JAVA_HOME/bin/java" -version

# ------------------------------
# Download Paper server
# ------------------------------
echo "[*] Downloading Paper server..."
wget -q https://fill-data.papermc.io/v1/objects/ab9bb1afc3cea6978a0c03ce8448aa654fe8a9c4dddf341e7cbda1b0edaa73f5/paper-1.21-130.jar -O paper.jar

# Run once to generate eula.txt
echo "[*] Running Paper to generate eula.txt..."
"$JAVA_HOME/bin/java" -Xmx2G -Xms1G -jar paper.jar nogui || true

# Accept EULA
echo "[*] Accepting Minecraft EULA..."
sed -i 's/eula=false/eula=true/' eula.txt

# ------------------------------
# Install Plugins
# ------------------------------
mkdir -p plugins
echo "[*] Downloading plugins..."
wget -q https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot -O plugins/Geyser-Spigot.jar
wget -q https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot -O plugins/floodgate-spigot.jar
wget -q https://github.com/ViaVersion/ViaVersion/releases/download/5.4.2/ViaVersion-5.4.2.jar -O plugins/ViaVersion-5.4.2.jar
wget -q https://github.com/ViaVersion/ViaBackwards/releases/download/5.4.2/ViaBackwards-5.4.2.jar -O plugins/ViaBackwards-5.4.2.jar

# ------------------------------
# Download Playit.gg agent
# ------------------------------
echo "[*] Downloading Playit.gg agent..."
wget -q https://github.com/playit-cloud/playit-agent/releases/download/v0.16.2/playit-linux-amd64 -O playit
chmod +x playit

# ------------------------------
# Run Playit and Paper server together
# ------------------------------
echo "[*] Starting Playit.gg tunnel and PaperMC server..."
./playit &   # run Playit in background
"$JAVA_HOME/bin/java" -Xmx2G -Xms1G -jar paper.jar nogui
