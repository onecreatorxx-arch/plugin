#!/data/data/com.termux/files/usr/bin/bash
set -e

cd ~/plugin

echo "Fixing root build.gradle..."

cat <<'GRADLE' > build.gradle
plugins {
    id 'com.android.application' version '8.2.0' apply false
}
GRADLE


echo "Fixing settings.gradle..."

cat <<'GRADLE' > settings.gradle
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}

rootProject.name = "plugin"
include ':app'
GRADLE


echo "Fixing app build.gradle..."

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


echo "Cleaning caches..."

rm -rf .gradle
rm -rf app/build


echo "Git push..."

git add .
git commit -m "rewrite full gradle config" || true
git push

echo ""
echo "Build restarted on GitHub Actions"

