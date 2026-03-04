#!/data/data/com.termux/files/usr/bin/bash

mkdir -p .github/workflows

cat <<'YAML' > .github/workflows/android.yml
name: Android Build

on:
  push:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: temurin
          java-version: 17

      - name: Build APK
        run: ./gradlew assembleDebug

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: plugin-apk
          path: app/build/outputs/apk/debug/app-debug.apk
YAML

git add .
git commit -m "add apk artifact upload" || true
git push

