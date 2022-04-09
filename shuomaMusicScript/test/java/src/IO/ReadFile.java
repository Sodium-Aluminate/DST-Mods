package IO;

import okio.BufferedSource;
import okio.Okio;
import okio.Source;

import java.io.File;
import java.io.IOException;

public class ReadFile {
    public static String readFile(String filePath){

        File file = new File(filePath);
        try (Source source = Okio.source(file);
             BufferedSource buffer = Okio.buffer(source)){
            StringBuilder stringBuilder = new StringBuilder();
            while (true){
                String s = buffer.readUtf8Line();
                if(s==null) break;
                stringBuilder.append(s);
                stringBuilder.append("\n");
            }
            return stringBuilder.toString();
        } catch (IOException e) {
            e.printStackTrace();
            return "";
        }
    }
}
