package DSTNote2Shuoma;


import IO.ReadFile;
import IO.WriteFile;

import java.util.HashMap;

public class Main {
    static final String[] keyList = new String[]{"BC1",
            "C1", "CN1", "C2", "CN2", "C3", "C4", "CN4", "C7", "CN7", "C8", "CN8", "C9",
            "1", "N1", "2", "N2", "3", "4", "N4", "7", "N7", "8", "N8", "9", "0",
            "VN1", "V2", "VN2", "V3", "V4", "VN4", "V7", "VN7", "V8", "VN8", "V9", "V0",
            "VN0"};
    static final String[] keyListAddtional = new String[]{"BC1",
            "C1", "CB2", "C2", "CB3", "CB4", "CN3", "CB7", "C7", "CB8", "C8", "CB9", "CB0",
            "C0", "B2", "2", "B3", "B4", "N3", "B7", "7", "B8", "8", "B9", "B0", "V1",
            "VB2", "V2", "VB3", "VB4", "VN3", "VB7", "V7", "VB8", "V8", "VB9", "VB0", "VN9",
            "VN0"};

    public static void main(String[] args) {
        // todo: vardef 嵌套，def 前置，def override 特性 def，override delta 特性
        String map = ReadFile.readFile("/home/sodiumaluminate/DST-Mods/shuomaMusicScript/test/墨染樱花.smkq.ori");

        HashMap<String, String> varMap = new HashMap<>();

        StringBuilder mainStringBuilder = new StringBuilder();
        String[] lines = map.split("\n");
        for (int j = 0; j < lines.length; j++) {
            String s = lines[j];
            if (s.startsWith("#")) continue;
            if (s.startsWith("!")) {
                if (s.startsWith("!BPM=")) {
                    try {
                        String it = s.substring(5);
                        if (Double.parseDouble(it) > 0) mainStringBuilder.append("BPM=").append(it).append("\n");
                    } catch (NumberFormatException ignored) {
                    }
                } else if (s.startsWith("!SKIP=")) {
                    try {
                        int it = Integer.parseInt(s.substring(6));
                        if (it > 0 && it > j) j = it;
                    } catch (NumberFormatException ignored) {
                    }
                } else if (s.startsWith("!VARDEF:")) {

                    String key = s.substring(8);
                    j++;
                    StringBuilder value = new StringBuilder();
                    for (; j < lines.length; j++) {
                        if (lines[j].startsWith("#")) continue;
                        if (lines[j].startsWith("!VARDEF")) {
                            varMap.put(key, value.toString());
                            break;
                        }
                        value.append(translate(lines[j]));
                    }
                } else if (s.startsWith("!VAR:")) {
                    String key = s.substring(5);
                    String value = varMap.get(key);
                    if (value != null) mainStringBuilder.append(value);
                }
                continue;
            }
            mainStringBuilder.append(translate(s));
        }

        WriteFile.writeFile("/home/sodiumaluminate/DST-Mods/shuomaMusicScript/test/墨染樱花.smkq", mainStringBuilder.toString());
    }

    private static String translate(String raw){
        StringBuilder stringBuilder = new StringBuilder();
        String[] split = raw.split(" ");
        for (int i = 0; i < split.length; i++) {
            String s_ = split[i];
            if (s_.equals("")) {
                stringBuilder.append("\n");
                continue;
            }
            if(s_.startsWith("_")){
                s_=s_.substring(1);
                stringBuilder.append(keyListAddtional[Integer.parseInt(s_)].toLowerCase());
            }else {
                stringBuilder.append(keyList[Integer.parseInt(s_)].toLowerCase());
            }
            if (i != split.length - 1)
                stringBuilder.append(" ");
            else
                stringBuilder.append("\n");
        }
        return stringBuilder.toString();
    }
}
