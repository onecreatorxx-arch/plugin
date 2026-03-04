package com.example.simpletls;

import android.content.Context;

public class PluginConfig {

    public static String getBinary(Context context) {
        return context.getApplicationInfo().nativeLibraryDir + "/libsimple-tls.so";
    }
}
