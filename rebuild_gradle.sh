#!/data/data/com.termux/files/usr/bin/bash

set -e

cd ~/plugin

echo "Rewriting clean build.gradle..."

cat <<'GRADLE' > app/build.gradle
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.github.IrineSistiana.shadowsocks.plugin'
    compileSdk 34

    defaultConfig {
        applicationId "com.github.IrineSistiana.shadowsocks.plugin"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        debug {
            debuggable true
        }
        release {
            minifyEnabled false
        }
    }

    ndk {
        abiFilters 'arm64-v8a'
    }
}

dependencies {

    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'

    implementation 'com.github.shadowsocks:plugin:2.0.0'

}
GRADLE


echo "Cleaning gradle cache..."

rm -rf .gradle
rm -rf app/build


echo "Git commit..."

git add .

git commit -m "rewrite clean build.gradle" || true

echo "Git push..."

git push

echo ""
echo "Build started on GitHub Actions"
echo "https://github.com/onecreatorxx-arch/plugin/actions"

