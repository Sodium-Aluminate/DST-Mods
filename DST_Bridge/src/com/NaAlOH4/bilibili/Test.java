package com.NaAlOH4.bilibili;

import com.google.gson.Gson;

public class Test {
    public static void main(String[] args) {

        BilibiliDanmakuMessageClient bilibiliDanmakuMessageClient = new Gson().fromJson("{\"id\": \"24162718\", \"name\": \"料理的直播间\"}", BilibiliDanmakuMessageClient.class);

        bilibiliDanmakuMessageClient.setMessageHandler(m -> {
            System.out.println(m);
        });

        bilibiliDanmakuMessageClient.init();
    }
}
