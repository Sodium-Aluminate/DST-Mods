package com.NaAlOH4.dst;

import com.NaAlOH4.Tools;
import com.google.gson.Gson;

public class Test {
    public static void main(String[] args) {
        DSTService dstService = new Gson().fromJson(" { \"port\": 7890, \"password\": \"YLpLCgIVbpcBMyR1Mfoo\" }", DSTService.class);
        dstService.setOnNewClient(c->{});
        dstService.setOnClientRevoke(c->{});
        dstService.init();
        Tools.sleep(114514+1919810);
    }
}
