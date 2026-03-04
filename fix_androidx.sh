#!/data/data/com.termux/files/usr/bin/bash

cd ~/plugin

echo "Enabling AndroidX..."

cat <<'PROP' > gradle.properties
android.useAndroidX=true
android.enableJetifier=true
PROP

git add .
git commit -m "enable AndroidX support" || true
git push

echo "Build restarted on GitHub Actions"

