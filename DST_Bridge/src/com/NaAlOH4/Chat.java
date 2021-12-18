package com.NaAlOH4;

import org.jetbrains.annotations.Nullable;

public class Chat {
    public String title;
    public String first_name;
    public String last_name;
    public @Nullable String getName(){
        if(title!=null)return title;
        if(first_name!=null)return first_name+last_name==null?"":(" "+last_name);
        return null;
    }
}
