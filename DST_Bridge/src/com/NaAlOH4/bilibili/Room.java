package com.NaAlOH4.bilibili;

import com.NaAlOH4.Danmaku;
import com.NaAlOH4.MessageClient;
import org.jetbrains.annotations.Nullable;

public class Room extends Danmaku {
    private String text;
    private String nickname;
    private String timeline;

    private BilibiliDanmakuMessageClient client;

    @Override
    public String getSenderName() {
        return nickname;
    }

    @Override
    public String getText() {
        return text;
    }

    @Nullable
    @Override
    public String getAdditionalPrefix() {
        return null;
    }

    @Override
    public MessageClient getClientFrom() {
        return client;
    }

    public void setClient(BilibiliDanmakuMessageClient client) {
        this.client = client;
    }

    @Override
    public boolean equals(Object obj) {
        if ((!(obj instanceof Room o))) return false;
        return nickname.equals(o.nickname) && text.equals(o.text) && timeline.equals(o.timeline);
    }
}