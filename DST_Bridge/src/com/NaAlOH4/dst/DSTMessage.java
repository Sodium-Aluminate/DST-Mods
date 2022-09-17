package com.NaAlOH4.dst;

import com.NaAlOH4.Message;
import com.NaAlOH4.MessageClient;
import org.jetbrains.annotations.Nullable;

import java.text.MessageFormat;

public class DSTMessage extends Message {
    private String worldName;
    private String text;
    private String name;
    private String additionalPrefix;

    private DontStarveTogetherMessageClient client;
    @Override
    public String getSenderName() {
        return name;
    }

    @Override
    public String getText() {
        return text;
    }

    @Nullable
    @Override
    public String getAdditionalPrefix() {
        return additionalPrefix;
    }

    @Override
    public MessageClient getClientFrom() {
        return client;
    }

    public void setClient(DontStarveTogetherMessageClient client) {
        this.client = client;
    }

    public boolean isEmpty() {
        return this.name == null || this.worldName == null || this.text == null;
    }

    public String getWorldName() {
        return worldName;
    }

    public static DSTMessage shadow(Message message){


        DSTMessage shadow = new DSTMessage();
        shadow.name = message.getSenderName();
        shadow.text = message.getText();
        shadow.additionalPrefix = message.getAdditionalPrefix();


        if(message instanceof DSTMessage dstMessage){
            shadow.worldName = dstMessage.worldName;
        }else {
            shadow.worldName = String.valueOf(message.getClientFrom());
        }
        return shadow;
    }
}
