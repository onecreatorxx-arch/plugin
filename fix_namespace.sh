#!/data/data/com.termux/files/usr/bin/bash

cd ~/plugin

sed -i 's/package="com.github.shadowsocks.plugin.minimal"//' app/src/main/AndroidManifest.xml

sed -i '/android {/a\    namespace "com.github.shadowsocks.plugin.minimal"' app/build.gradle

git add .
git commit -m "fix namespace for AGP 8"
git push

echo "Arreglo aplicado. GitHub compilará de nuevo."
