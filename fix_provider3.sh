#!/data/data/com.termux/files/usr/bin/bash

cd ~/plugin

cat <<'JAVA' > app/src/main/java/com/github/IrineSistiana/shadowsocks/plugin/simple_tls/BinaryProvider.java
package com.github.IrineSistiana.shadowsocks.plugin.simple_tls;

import android.net.Uri;
import android.os.ParcelFileDescriptor;

import com.github.shadowsocks.plugin.NativePluginProvider;

import java.io.File;

public class BinaryProvider extends NativePluginProvider {

    @Override
    public ParcelFileDescriptor openFile(Uri uri) {

        File file = new File(getContext().getApplicationInfo().nativeLibraryDir, "libsimple-tls.so");

        return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY);
    }

}
JAVA

git add .
git commit -m "fix correct openFile signature" || true
git push

echo "Rebuild triggered"

