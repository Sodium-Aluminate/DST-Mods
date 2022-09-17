package com.NaAlOH4.telegram;

import com.NaAlOH4.Message;
import com.NaAlOH4.MessageClient;
import com.google.gson.Gson;
import okhttp3.*;

import java.io.IOException;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

public class TelegramMessageClient extends MessageClient {

    private String name;
    private String key;
    private String target_group_id;
    private boolean allow_other_source;

    private static OkHttpClient httpClient = new OkHttpClient.Builder().build();
    private static OkHttpClient longPullClient = new OkHttpClient.Builder().readTimeout(120, TimeUnit.SECONDS).build();


    private Consumer<Message> receivedMessageHandler;

    @Override
    public void setMessageHandler(Consumer<Message> receivedMessageHandler) {
        this.receivedMessageHandler = receivedMessageHandler;
    }

    @Override
    public void sendMessage(Message messageToSend) {
        try  {
            Response response = httpClient.newCall(
                new Request.Builder()
                        .url(getSendUrl())
                        .post(new FormBody.Builder()
                                .add("chat_id", target_group_id)
                                .add("text", messageToSend.toString())
                                .build()
                        )
                        .build()
        ).execute();
            var a = response.body().string();
            response.close();
        } catch (IOException ignored) {

        }
    }

    private String sendUrl = null;

    private String getSendUrl() {
        if (sendUrl == null) {
            sendUrl = "https://api.telegram.org/bot" + key + "/sendMessage";
        }
        return sendUrl;
    }

    private String updateUrl = null;

    private String getUpdateUrl() {
        if (updateUrl == null) {
            updateUrl = "https://api.telegram.org/bot" + key + "/getUpdates";
        }
        return updateUrl;
    }

    private int offset = 0;

    private static Gson gson = new Gson();

    @Override
    public void init() {
        sendUrl = null;
        updateUrl = null;
        offset = 0;

        new Thread(() -> {
            while (true) {
                try (
                        Response response = longPullClient.newCall(
                                new Request.Builder()
                                        .url(getUpdateUrl())
                                        .post(new FormBody.Builder()
                                                .add("offset", String.valueOf(offset))
                                                .add("timeout", "110")
                                                .build()
                                        )
                                        .build()
                        ).execute();
                        ResponseBody body = response.body();
                ) {
                    if (body != null) {
                        String updateReturnString = body.string();
                        UpdateReturn updateReturn = gson.fromJson(updateReturnString, UpdateReturn.class);
                        if (Boolean.TRUE.equals(updateReturn.ok)
                                && updateReturn.result != null) {
                            for (Update update : updateReturn.result) {
                                offset = Math.max(offset, update.update_id+1);
                                if(!allow_other_source && target_group_id.equals(update.message.chat.getId()))
                                    return;
                                update.message.setClient(this);
                                receivedMessageHandler.accept(update.message);
                            }
                        }
                    }

                } catch (IOException | RuntimeException ignored) {
                }
            }
        }).start();
    }

    public String getName() {
        if (name == null || name.length() == 0) return "tg";
        return name;
    }

    @Override
    public String toString() {
        return getName();
    }
}
