#!/data/data/com.termux/files/usr/bin/bash

cd ~/plugin

cat <<'JAVA' > app/src/main/java/com/github/IrineSistiana/shadowsocks/plugin/simple_tls/BinaryProvider.java
package com.github.IrineSistiana.shadowsocks.plugin.simple_tls;

import com.github.shadowsocks.plugin.NativePluginProvider;
import com.github.shadowsocks.plugin.PathProvider;

public class BinaryProvider extends NativePluginProvider {

    @Override
    protected void populateFiles(PathProvider provider) {
        provider.addPath("simple-tls", "libsimple-tls.so");
    }

}
JAVA

git add .
git commit -m "fix plugin provider implementation" || true
git push

echo "Build triggered"

