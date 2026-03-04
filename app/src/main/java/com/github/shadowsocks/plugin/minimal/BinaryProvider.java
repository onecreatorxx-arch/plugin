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
