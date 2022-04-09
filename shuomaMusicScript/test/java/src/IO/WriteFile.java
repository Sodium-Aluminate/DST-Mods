package IO;

import okio.*;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.function.Function;

public class WriteFile {

    public static void main(String[] args) throws IOException {
        writeFile("/tmp/test", "lalala");
    }

    public static <T> void writeFile(String path, List<T> list, Function<T, String> translator){
        StringBuilder stringBuilder = new StringBuilder();
        for (T t:list) {
            stringBuilder.append(translator.apply(t)).append("\n");
        }
        writeFile(path, stringBuilder.toString());
    }
    public static void writeFile(String path, String text) {
        File file = new File(path);
        file.getParentFile().mkdirs();

        if(!file.exists()){
            boolean ifCreated = false;
            try {
                ifCreated = file.createNewFile();
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
            System.out.println("file created: "+ifCreated);
        }
        System.out.println("Writing: "+file.getAbsolutePath());
        // System.out.println(text);


        try(Sink sink = Okio.sink(file);
            BufferedSink bufferedSink = Okio.buffer(sink)) {
            bufferedSink.writeUtf8(text);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
}
