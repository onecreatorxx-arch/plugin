#!/data/data/com.termux/files/usr/bin/bash

cd ~/plugin

echo "Fixing AndroidManifest namespace issue..."

sed -i 's/package="com.github.IrineSistiana.shadowsocks.plugin"//g' app/src/main/AndroidManifest.xml

git add .
git commit -m "fix manifest namespace for gradle 8" || true
git push

echo "Build restarted"

