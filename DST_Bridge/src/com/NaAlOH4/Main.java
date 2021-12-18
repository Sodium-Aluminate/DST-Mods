package com.NaAlOH4;
import com.google.gson.Gson;
import com.sun.net.httpserver.HttpServer;
import okhttp3.*;


import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.LinkedList;
import java.util.Queue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;

public class Main {
    private static final BlockingQueue<Update> q = new LinkedBlockingQueue<>();
    private static final Gson gson = new Gson();
    private static final OkHttpClient client = new OkHttpClient.Builder().build();
    private static final String sendMessageUrl = "https://api.telegram.org/bot"+System.getenv("bottoken")+"/sendMessage";
    private static final String getUpdateUrl = "https://api.telegram.org/bot"+System.getenv("bottoken")+"/getUpdates";
    private static final String chat_id= System.getenv("chatid");
    private static int offset = 0;
    public static void main(String[] arg) throws Exception {

        String s = "{\"asStr\":\"balabala\"}";
        HttpServer server = HttpServer.create(new InetSocketAddress(5826), 0);
        server.createContext("/sendMessage", exchange -> {
            String requestMethod = exchange.getRequestMethod();
            if ("POST".equals(requestMethod)) {
                InputStream requestBody = exchange.getRequestBody();
                sendMessage(new String(requestBody.readAllBytes()));
            } else {
                System.err.println("/sendMessage got a wrong method: " + requestMethod);
            }
            exchange.sendResponseHeaders(200, 0); // 没错这里是写死的哈哈哈
            OutputStream os = exchange.getResponseBody();
            os.flush();
            os.close();
            exchange.close();
        });
        server.createContext("/getMessage", exchange -> {
            OutputStream os = exchange.getResponseBody();
            exchange.sendResponseHeaders(200, 0);
            Update update = q.poll();
            if (update!= null) {
                println(gson.toJson(update));
                os.write(gson.toJson(update)
                        .getBytes(StandardCharsets.UTF_8));
            }
            os.flush();
            os.close();
            exchange.close();
        });
        server.start();

        new Thread(() -> {
            OkHttpClient longPullClient = new OkHttpClient.Builder()
                    .readTimeout(120, TimeUnit.SECONDS)
                    .build();

            while (true) {
                try {
                    Response response = longPullClient.newCall(
                            new Request.Builder()
                                    .url(getUpdateUrl)
                                    .post(new FormBody.Builder()
                                            .add("offset", String.valueOf(offset))
                                            .add("timeout", "110")
                                            .build()
                                    )
                                    .build()
                    ).execute();
                    ResponseBody body = response.body();
                    if(body!=null) {
                        String updateReturnString = body.string();
                        UpdateReturn updateReturn = gson.fromJson(updateReturnString, UpdateReturn.class);
                        if(updateReturn.ok && updateReturn.result!=null){
                            for (Update update:updateReturn.result) {
                                if(checkAndParseUpdate(update)){
                                    q.add(update);
                                }
                            }
                        }
                    }
                    response.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }).start();
    }

    private static boolean checkAndParseUpdate(Update update) {
        assert offset < update.update_id+1;
        offset = update.update_id+1;
        if(update.message == null||
                update.message.from==null||
                update.message.from.first_name==null||
                update.message.chat==null||
                update.message.chat.getName()==null||
                update.message.getString() == null
        )return false;
        update.message.text = update.message.getString();
        update.message.chat.title = update.message.chat.getName();
        return true;
    }

    private static void sendMessage(String s) {
        try {
            client.newCall(
                    new Request.Builder()
                            .url(sendMessageUrl)
                            .post(new FormBody.Builder()
                                    .add("chat_id", chat_id)
                                    .add("text", s)
                                    .build()
                            )
                            .build()
            ).execute();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }


    public static void println(Object o) {
        System.out.println(o);
    }
}