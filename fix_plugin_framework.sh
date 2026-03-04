#!/data/data/com.termux/files/usr/bin/bash

cd ~/plugin

echo "Configurando estructura del plugin..."

mkdir -p app/src/main/java/com/github/shadowsocks/plugin/minimal

cat <<'JAVA' > app/src/main/java/com/github/shadowsocks/plugin/minimal/BinaryProvider.java
package com.github.shadowsocks.plugin.minimal;

import android.net.Uri;
import android.os.ParcelFileDescriptor;

import com.github.shadowsocks.plugin.NativePluginProvider;
import com.github.shadowsocks.plugin.PathProvider;

import java.io.File;
import java.io.FileNotFoundException;

public class BinaryProvider extends NativePluginProvider {

    @Override
    public void populateFiles(PathProvider provider) {
        provider.addPath("minimal", 0b111101101);
    }

    @Override
    public ParcelFileDescriptor openFile(Uri uri) throws FileNotFoundException {
        File file = new File(getContext().getApplicationInfo().nativeLibraryDir + "/libsimple-tls.so");
        return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY);
    }
}
JAVA

echo "Creando AndroidManifest correcto..."

cat <<'XML' > app/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.github.shadowsocks.plugin.minimal">

    <application
        android:label="Minimal Plugin"
        android:extractNativeLibs="true">

        <provider
            android:name=".BinaryProvider"
            android:authorities="com.github.shadowsocks.plugin.minimal"
            android:exported="true"
            android:directBootAware="true">

            <intent-filter>
                <action android:name="com.github.shadowsocks.plugin.ACTION_NATIVE_PLUGIN"/>
            </intent-filter>

            <intent-filter>
                <action android:name="com.github.shadowsocks.plugin.ACTION_NATIVE_PLUGIN"/>
                <data
                    android:scheme="plugin"
                    android:host="com.github.shadowsocks"
                    android:path="/minimal"/>
            </intent-filter>

            <meta-data
                android:name="com.github.shadowsocks.plugin.id"
                android:value="minimal"/>

            <meta-data
                android:name="com.github.shadowsocks.plugin.executable_path"
                android:value="libsimple-tls.so"/>

        </provider>

    </application>

</manifest>
XML

echo "Subiendo cambios..."

git add .
git commit -m "implement native shadowsocks plugin provider" || true
git push

echo ""
echo "Listo."
echo "GitHub Actions empezará a compilar el nuevo APK automáticamente."
