#!/data/data/com.termux/files/usr/bin/bash

cd ~/plugin

rm -rf app/src/main/java

mkdir -p app/src/main/java/com/example/simpletls

cat <<'JAVA' > app/src/main/java/com/example/simpletls/MainActivity.java
package com.example.simpletls;

import android.app.Activity;
import android.os.Bundle;

public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        finish();
    }
}
JAVA

cat <<'JAVA' > app/src/main/java/com/example/simpletls/PluginConfig.java
package com.example.simpletls;

import android.content.Context;

public class PluginConfig {

    public static String getBinary(Context context) {
        return context.getApplicationInfo().nativeLibraryDir + "/libsimple-tls.so";
    }
}
JAVA

git add .
git commit -m "rebuild plugin architecture" || true
git push

