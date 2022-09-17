package com.NaAlOH4;

import java.util.function.Consumer;

public abstract class MessageClient {
    /**
     * @param receivedMessageHandler 当这个端从远程（比如游戏）收到消息时，应执行这个函数。
     *                               这个函数不是堵塞的。
     */
    public abstract void setMessageHandler(Consumer<Message> receivedMessageHandler);

    /**
     * 不能堵塞。推出去单个消息（比如推给游戏）的方法。
     * 也就是继承的实现应该自行维护一个列表来应对网络问题。
     * 不过要注意这个列表要上锁来防止线程冲突。
     * @param messageToSend 要发送的消息
     */
    public abstract void sendMessage(Message messageToSend);


    /**
     * 用于被 gson 反射灌入数据后，自检数据是否正常。
     */
    public abstract void init();
}
