#!/data/data/com.termux/files/usr/bin/bash

cd ~/plugin

cat <<'YAML' > .github/workflows/android.yml
name: build

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
          cache: gradle

      - name: Setup Android
        uses: android-actions/setup-android@v3

      - name: Cache Gradle
        uses: actions/cache@v3
        with:
          path: |
            ~/.gradle
            ~/.android
          key: gradle-${{ runner.os }}-${{ hashFiles('**/*.gradle*') }}
          restore-keys: gradle-${{ runner.os }}

      - name: Install Gradle
        run: sudo apt-get update && sudo apt-get install -y gradle

      - name: Build APK
        run: gradle assembleDebug
YAML

git add .
git commit -m "add gradle cache for faster builds"
git push

echo "Workflow optimizado"
