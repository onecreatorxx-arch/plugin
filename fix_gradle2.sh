#!/data/data/com.termux/files/usr/bin/bash
set -e

cd ~/plugin

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

        ndk {
            abiFilters 'arm64-v8a'
        }
    }

    buildTypes {
        debug {
            debuggable true
        }

        release {
            minifyEnabled false
        }
    }
}

dependencies {

    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'

    implementation 'com.github.shadowsocks:plugin:2.0.0'

}
GRADLE

git add .
git commit -m "fix ndk position for gradle 8" || true
git push

echo "Build restarted on GitHub Actions"

