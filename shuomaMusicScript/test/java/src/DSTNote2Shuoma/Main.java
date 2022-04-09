package DSTNote2Shuoma;


import IO.ReadFile;
import IO.WriteFile;

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
        String map = ReadFile.readFile("/home/sodiumaluminate/cache/妖怪少女.smkq.ori");
        String bpm="200";
        StringBuilder stringBuilder = new StringBuilder();
        String[] strings = map.split("\n");
        for (int j = 0; j < strings.length; j++) {
            String s = strings[j];
            if (s.startsWith("#")) continue;
            if (s.startsWith("!")) {
                if (s.startsWith("!BPM=")) {
                    try {
                        String it = s.substring(5);
                        if (Double.parseDouble(it) > 0) bpm = it;
                    } catch (NumberFormatException ignored) {
                    }
                }
                if (s.startsWith("!SKIP=")) {
                    try {
                        int it = Integer.parseInt(s.substring(6));
                        if (it > 0) j = it;
                    }catch (NumberFormatException ignored){}
                }
                continue;
            }
            String[] split = s.split(" ");
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
        }

        WriteFile.writeFile("/home/sodiumaluminate/cache/妖怪少女.smkq", "BPM="+bpm+"\n\n\n\n" + stringBuilder);
    }
}
