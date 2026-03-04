package com.github.shadowsocks.plugin.minimal;

import android.net.Uri;
import android.os.ParcelFileDescriptor;

import com.github.shadowsocks.plugin.NativePluginProvider;
import com.github.shadowsocks.plugin.PathProvider;

import java.io.File;
import java.io.FileNotFoundException;

public class BinaryProvider extends NativePluginProvider {

    private static final String EXECUTABLE_NAME = "libsimple-tls.so";

    @Override
    public void populateFiles(PathProvider provider) {
        provider.addPath(EXECUTABLE_NAME, 0b111101101);
    }

    @Override
    public ParcelFileDescriptor openFile(Uri uri) throws FileNotFoundException {
        File file = new File(getContext().getApplicationInfo().nativeLibraryDir, EXECUTABLE_NAME);
        return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY);
    }
}
