package com.NaAlOH4.bilibili;

import com.NaAlOH4.Message;
import com.NaAlOH4.MessageClient;
import com.NaAlOH4.Tools;
import com.google.gson.Gson;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

import java.io.IOException;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.function.Consumer;

//curl "https://api.live.bilibili.com/xlive/web-room/v1/dM/gethistory?roomid=24162718"
public class BilibiliDanmakuMessageClient extends MessageClient {

    private boolean messageLoaded = false;

    private static long pull_delay_ms = Long.parseLong(System.getenv().getOrDefault("BILIBILI_PULL_DELAY", "1000"));
    private static final String urlPrefix = "https://api.live.bilibili.com/xlive/web-room/v1/dM/gethistory?roomid=";
    private String id;
    private String name;

    private Consumer<Message> receivedMessageHandler = null;
    @Override
    public void setMessageHandler(Consumer<Message> receivedMessageHandler) {
        this.receivedMessageHandler = receivedMessageHandler;
    }

    @Override
    public void sendMessage(Message messageToSend) {} // 弹幕同步只需要收消息

    @Override
    public void init() {
        //asserts
        Integer.parseInt(id);
        if(pull_delay_ms<1)throw new IllegalArgumentException("BILIBILI_PULL_DELAY must be positive");

        new Thread(()->{
            String url = urlPrefix+id;
            OkHttpClient httpClient = new OkHttpClient.Builder().build();
            Gson gson = new Gson();
            ArrayList<Room> oldMessages = new ArrayList<>();
            while (true){
                if(receivedMessageHandler != null){

                    try(Response response = httpClient.newCall(new Request.Builder()
                            .url(url)
                            .get()
                            .build()).execute();) {
                        if(response.code()==200){
                            ArrayList<Room> messages = new ArrayList<>();
                            String s = response.body().string();
                            Result result = gson.fromJson(s, Result.class);
                            for (Room room:result.data.room) {
                                room.setClient(this);
                                messages.add(room);
                                if (!oldMessages.contains(room) && (messageLoaded)) receivedMessageHandler.accept(room);
                            }
                            if(!messages.isEmpty()) oldMessages = messages;
                            messageLoaded=true;
                        }

                    } catch (IOException|NullPointerException ignored) {
                    }
                }
                Tools.sleep(pull_delay_ms);
            }
        }).start();
    }

    @Override
    public String toString() {
        return this.name!=null?this.name:"bilibili 直播间";
    }
}
