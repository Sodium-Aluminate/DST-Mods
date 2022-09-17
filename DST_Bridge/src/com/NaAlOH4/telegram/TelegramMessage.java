package com.NaAlOH4.telegram;


import com.NaAlOH4.Message;
import com.NaAlOH4.MessageClient;
import org.jetbrains.annotations.Nullable;

public class TelegramMessage extends Message {
    public User from;
    public Chat chat;
    public String text;
    public String caption;
    public String getString(){
        if(text!=null)return text;
        if(caption!=null)return "[Media] "+caption;
        return null;
    }


    private TelegramMessageClient client;
    @Override
    public String getSenderName() {
        if(from == null) return "？";
        return from.toString();
    }

    @Override
    public String getText() {
        return getString();
    }

    @Nullable
    @Override
    public String getAdditionalPrefix() {
        if(client == null) return null;
        return client.getName();
    }

    @Override
    public MessageClient getClientFrom() {
        return client;
    }

    public void setClient(TelegramMessageClient client) {
        this.client = client;
    }
}
