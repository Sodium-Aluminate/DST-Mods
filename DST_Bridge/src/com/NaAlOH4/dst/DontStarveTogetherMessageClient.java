package com.NaAlOH4.dst;

import com.NaAlOH4.Message;
import com.NaAlOH4.MessageClient;
import org.jetbrains.annotations.Nullable;

import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.function.Consumer;

public class DontStarveTogetherMessageClient extends MessageClient {

    private long lastGetDate;

    private Consumer<Message> receivedMessageHandler;
    @Override
    public void setMessageHandler(Consumer<Message> receivedMessageHandler) {
        this.receivedMessageHandler = receivedMessageHandler;
    }


    private BlockingQueue<Message> messagesToSend = new LinkedBlockingQueue<>();
    @Override
    public void sendMessage(Message messageToSend) {
        messagesToSend.add(messageToSend);
    }

    /**
     * @return 给 DSTService 使用的，当游戏请求消息时，从这里获取。
     */
    public @Nullable Message pollMessageToSend(){
        lastGetDate = System.currentTimeMillis();
        return messagesToSend.poll();
    }

    public void pushMessageToSend(DSTMessage message){
        if(receivedMessageHandler != null)
            receivedMessageHandler.accept(message);
    }

    private String worldName;

    public String getWorldName() {
        return worldName;
    }

    public DontStarveTogetherMessageClient(String worldName){
        this.worldName=worldName;
    }


    @Override
    public void init() {
        lastGetDate = System.currentTimeMillis();
    }

    public boolean tooOld() {
        return (System.currentTimeMillis() - lastGetDate) > 10000L; //十秒没有更新视为掉线
    }

    @Override
    public String toString() {
        return worldName;
    }
}
