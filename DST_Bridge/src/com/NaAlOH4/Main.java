package com.NaAlOH4;

import com.NaAlOH4.bilibili.BilibiliDanmakuMessageClient;
import com.NaAlOH4.dst.DSTService;
import com.NaAlOH4.telegram.TelegramMessageClient;
import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;

import java.util.Collections;
import java.util.LinkedList;
import java.util.List;

public class Main {
    public static final String HELP_STR = """
            需要指定一个配置文件来启动。
            配置文件应为一个  json，其格式应如 example.json 所示。
            配置文件中的 "comment" 不是必要内容。""";

    private static final List<MessageClient> clients = Collections.synchronizedList(new LinkedList<>()) ;

    public static void main(String[] args) {
        boolean printHelp = false;
        if (args.length == 0) {
            printHelp = true;
        }

        for (String arg : args) {
            if (arg.equals("--help") || arg.equals("-h")) {
                printHelp = true;
            }
            break;
        }
        if (printHelp) {
            System.out.println(HELP_STR);
        }

        if (args.length > 1) {
            System.err.println("too many args.");
        }

        String configStr = Tools.readFile(args[0]);

        Gson gson = new Gson();
        JsonObject configJson = gson.fromJson(configStr, JsonObject.class);


        // MessageManager
        if (configJson.has("telegram")) {
            JsonArray telegramConfigs = configJson.getAsJsonArray("telegram");
            for (JsonElement telegramConfig : telegramConfigs) {
                clients.add(gson.fromJson(telegramConfig, TelegramMessageClient.class));
                System.out.println("tg service created");
            }
        }
        if (configJson.has("dst")) {
            JsonObject dstConfigs = configJson.getAsJsonObject("dst");
            DSTService dstService = gson.fromJson(dstConfigs, DSTService.class);
            dstService.setOnNewClient(e -> {
                clients.add(e);
                e.setMessageHandler(message -> sendMessageToOtherClient(message, e));
                System.out.println("new world joined: "+e);
            });
            dstService.setOnClientRevoke(e -> {
                clients.remove(e);
                System.out.println("world revoked: "+e);
            });
            dstService.init();
            System.out.println("dst service created");
        }
        if (configJson.has("bilibili")) {
            JsonArray bilibiliConfigs = configJson.getAsJsonArray("bilibili");
            for (JsonElement bilibiliConfig : bilibiliConfigs) {
                clients.add(gson.fromJson(bilibiliConfig, BilibiliDanmakuMessageClient.class));
                System.out.println("bilibili service created");
            }
        }

        for (MessageClient client : clients) {
            client.init();
            client.setMessageHandler(message -> sendMessageToOtherClient(message, client));
        }
    }

    private static void sendMessageToOtherClient(Message message, MessageClient client) {
        for (int i = 0; i < clients.size(); i++) {
            MessageClient currentClient = clients.get(i);
            if (currentClient != client) {
                currentClient.sendMessage(message);
            }
        }
    }
}
