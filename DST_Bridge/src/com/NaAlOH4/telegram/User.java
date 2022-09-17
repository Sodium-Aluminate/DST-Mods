package com.NaAlOH4.telegram;


public class User {
    public String first_name;
    public String last_name;

    @Override
    public String toString() {
        if(last_name==null)return first_name;
        return first_name+" "+last_name;
    }
}
