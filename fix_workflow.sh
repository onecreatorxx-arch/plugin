#!/data/data/com.termux/files/usr/bin/bash

cd ~/plugin

mkdir -p .github/workflows

cat <<'YAML' > .github/workflows/android.yml
name: build

on:
  push:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v3
        with:
          distribution: temurin
          java-version: 17

      - uses: android-actions/setup-android@v3

      - name: Install Gradle
        run: sudo apt-get update && sudo apt-get install -y gradle

      - name: Build APK
        run: gradle assembleDebug
YAML

git add .
git commit -m "fix github workflow build"
git push

echo "Workflow corregido y enviado a GitHub"
