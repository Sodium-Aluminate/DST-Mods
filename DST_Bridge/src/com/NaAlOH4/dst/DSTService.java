package com.NaAlOH4.dst;

import com.NaAlOH4.Message;
import com.NaAlOH4.MessageClient;
import com.google.gson.Gson;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.Map;
import java.util.function.Consumer;

public class DSTService {

    private Map<String, DontStarveTogetherMessageClient> clients = new HashMap<>();

    private int port;
    private String password;
    private boolean noPasswd;

    private Consumer<MessageClient> onNewClient;
    private Consumer<MessageClient> onClientRevoke;

    public void init() {
        Gson gson = new Gson();
        if (port < 0 || port > 65536) throw new IllegalArgumentException("port not valid");
        try {
            MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
            sha256.update(password.getBytes(StandardCharsets.UTF_8));
            byte[] digest = sha256.digest();
            StringBuilder stringBuilder = new StringBuilder();
            for (byte b : digest) {
                String hex = Integer.toHexString(0b11111111 & b);
                if(hex.length() != 2)
                    stringBuilder.append("0".repeat(2-hex.length()));
                stringBuilder.append(hex);
            }
            String passwordSHA256 = stringBuilder.toString();
            noPasswd = (passwordSHA256.equals("d977c17127ec9d2e0764be61b1d1b8a7c54ad30717fbc347212b642c0ba27d21"));// 聪明的小伙伴可能想暴力破解一下这个 sha256，不过其实直接改掉这里可能更方便点...
            if (noPasswd) System.out.println("running as no password mode!");
        } catch (Exception ignored) {}
        if (password.length() < 16 && (!noPasswd))
            throw new IllegalArgumentException("密码太短了！");
        try {
            HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);
            server.createContext("/sendMessage", exchange -> {
                try (exchange) {
                    if (!"POST".equals(exchange.getRequestMethod())) {
                        System.err.println("发现错误的请求：sendMessage 接口需要使用 post");

                        responseExchange(exchange, 400, "sendMessage 接口需要使用 post。", "text/plain; charset=utf-8");
                        return;
                    }
                    String inputPassword = null;
                    String worldName = null;
                    String query = exchange.getRequestURI().getQuery();
                    if (query != null) {
                        for (String queryStr : query.split("&")) {
                            String[] s = queryStr.split("=", 2);
                            if (s.length == 2) {
                                if ("serverPasswd".equals(s[0])) {
                                    inputPassword = s[1];
                                }
                                if ("worldName".equals(s[0])) {
                                    worldName = s[1];
                                }
                            }
                        }
                    }
                    if ((!noPasswd) && !password.equals(inputPassword)) {
                        System.out.println("found a wrong password request: ");
                        responseExchange(exchange, 401, "密码错误。", "text/plain; charset=utf-8");
                        return;
                    }

                    InputStream requestBody = exchange.getRequestBody();
                    String s = new String(requestBody.readAllBytes());
                    DSTMessage message = gson.fromJson(s, DSTMessage.class);
                    if (message.isEmpty()) {
                        System.err.println("收到一个不完整的请求: ");
                        System.out.println(s);
                        responseExchange(exchange, 400, "消息内容不完整。", "text/plain; charset=utf-8");
                        return;
                    }
                    if (!message.getWorldName().equals(worldName)) {
                        System.err.println("消息的世界名称与请求参数中不一致");
                        responseExchange(exchange, 400, "消息的世界名称与请求参数中不一致。", "text/plain; charset=utf-8");
                        return;
                    }
                    DontStarveTogetherMessageClient client = getMessageClient(message.getWorldName());
                    message.setClient(client);

                    client.pushMessageToSend(message);


                    responseExchange(exchange, 200, "消息发送成功: " + message, "text/plain; charset=utf-8");

                    clearOldMessageClient();
                } catch (RuntimeException e) {
                    e.printStackTrace();
                }
            });

            server.createContext("/getMessage", exchange -> {
                try (exchange) {
                    if (!"GET".equals(exchange.getRequestMethod())) {
                        System.err.println("发现错误的请求：getMessage 接口需要使用 GET");
                        responseExchange(exchange, 400, "getMessage 接口需要使用 GET。", "text/plain; charset=utf-8");
                        return;
                    }
                    String inputPassword = null;
                    String worldName = null;
                    String query = exchange.getRequestURI().getQuery();
                    if (query != null) {
                        for (String queryStr : query.split("&")) {
                            String[] s = queryStr.split("=", 2);
                            if (s.length == 2) {
                                if ("serverPasswd".equals(s[0])) {
                                    inputPassword = s[1];
                                }
                                if ("worldName".equals(s[0])) {
                                    worldName = s[1];
                                }
                            }
                        }
                    }
                    if ((!noPasswd) && !password.equals(inputPassword)) {
                        System.out.println("found a wrong password request.");
                        responseExchange(exchange, 401, "密码错误。", "text/plain; charset=utf-8");
                        return;
                    }
                    if (worldName == null || worldName.length() == 0) {
                        responseExchange(exchange, 400, "世界名称不能为空", "text/plain; charset=utf-8");
                        return;
                    }

                    DontStarveTogetherMessageClient client = getMessageClient(worldName);

                    LinkedList<DSTMessage> messagesToSend = new LinkedList<>();
                    while (true) {
                        Message message = client.pollMessageToSend();
                        if (message == null) break;
                        messagesToSend.addLast(DSTMessage.shadow(message));
                    }
                    String messageJson = gson.toJson(messagesToSend.toArray(new DSTMessage[0]));

                    responseExchange(exchange, 200, messageJson, "application/json; charset=utf-8");

                    clearOldMessageClient();
                } catch (RuntimeException e) {
                    e.printStackTrace();
                }
            });

            server.start();
        } catch (IOException e) {
            System.err.println("dst service error");
            e.printStackTrace(System.err);
        }

    }

    public void setOnNewClient(Consumer<MessageClient> onNewClient) {
        this.onNewClient = onNewClient;
    }

    public void setOnClientRevoke(Consumer<MessageClient> onClientRevoke) {
        this.onClientRevoke = onClientRevoke;
    }

    private DontStarveTogetherMessageClient getMessageClient(String worldName) {
        if (clients.containsKey(worldName)) return clients.get(worldName);
        DontStarveTogetherMessageClient client = new DontStarveTogetherMessageClient(worldName);
        client.init();
        clients.put(worldName, client);
        onNewClient.accept(client);
        return client;
    }

    private void clearOldMessageClient() {
        for (var set : clients.entrySet()) {
            DontStarveTogetherMessageClient client = set.getValue();
            if (client.tooOld()) {
                clients.remove(set.getKey());
                onClientRevoke.accept(client);
            }
        }
    }

    private void responseExchange(HttpExchange exchange, int code, String str, String contentType) throws IOException {
        exchange.getResponseHeaders().set("Content-Type", contentType);
        exchange.sendResponseHeaders(code, 0);
        OutputStream os = exchange.getResponseBody();
        os.write(str.getBytes(StandardCharsets.UTF_8));
        os.flush();
        os.close();
    }
}
