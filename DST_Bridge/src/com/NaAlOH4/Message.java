package com.NaAlOH4;

import org.jetbrains.annotations.Nullable;

public abstract class Message {
    public abstract String getSenderName();
    public abstract String getText();
    @Nullable
    public abstract String getAdditionalPrefix();
    public abstract MessageClient getClientFrom();

    @Override
    public String toString() {
        String s = getAdditionalPrefix();
        if (s != null) {
            s = "(" + s + ")";
        } else {
            s = "";
        }
        return s + getSenderName() + "@" + getClientFrom() + ": " + getText();
    }


}
