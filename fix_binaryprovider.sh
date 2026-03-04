#!/data/data/com.termux/files/usr/bin/bash

cd ~/plugin

cat <<'JAVA' > app/src/main/java/com/github/shadowsocks/plugin/minimal/BinaryProvider.java
package com.github.shadowsocks.plugin.minimal;

import android.net.Uri;
import android.os.ParcelFileDescriptor;

import com.github.shadowsocks.plugin.NativePluginProvider;
import com.github.shadowsocks.plugin.PathProvider;

import java.io.File;

public class BinaryProvider extends NativePluginProvider {

    @Override
    public void populateFiles(PathProvider provider) {
        provider.addPath("minimal", 0b111101101);
    }

    @Override
    public ParcelFileDescriptor openFile(Uri uri) {
        try {
            File file = new File(getContext().getApplicationInfo().nativeLibraryDir + "/libsimple-tls.so");
            return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
JAVA

git add .
git commit -m "fix BinaryProvider openFile signature"
git push

echo "BinaryProvider corregido. GitHub compilará nuevamente."
