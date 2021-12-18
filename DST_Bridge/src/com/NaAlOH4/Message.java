package com.NaAlOH4;

import org.jetbrains.annotations.Nullable;

public class Message {
    public User from;
    public Chat chat;
    public String text;
    public String caption;
    public @Nullable String getString(){
        if(text!=null)return text;
        if(caption!=null)return "[Media] "+caption;
        return null;
    }
}
