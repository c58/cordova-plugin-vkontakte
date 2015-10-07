package com.studytime.vkontakte;

import android.app.Application;

import com.vk.sdk.VKSdk;


public class VkontakteInitApp extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        VKSdk.initialize(this);
    }
}
