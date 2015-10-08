package com.studytime.vkontakte;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import com.vk.sdk.VKAccessToken;
import com.vk.sdk.VKCallback;
import com.vk.sdk.VKSdk;
import com.vk.sdk.api.VKError;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class Vkontakte extends CordovaPlugin {
    private static final String TAG = "Vkontakte";
    private static final String ACTION_INIT = "initWithApp";
    private static final String ACTION_LOGIN = "login";
    private CallbackContext _callbackContext;

    private String savedUrl = null;
    private String savedComment = null;
    private String savedImageUrl = null;
    final String sTokenKey = "VK_ACCESS_TOKEN";

    /**
     * Gets the application context from cordova's main activity.
     *
     * @return the application context
     */
    private Context getApplicationContext() {
        return this.getActivity().getApplicationContext();
    }

    private Activity getActivity() {
        return (Activity) this.webView.getContext();
    }

    @Override
    public boolean execute(String action, CordovaArgs args, final CallbackContext callbackContext) throws JSONException {
        this._callbackContext = callbackContext;
        if (ACTION_INIT.equals(action)) {
            return init(args.getString(0));
        } else if (ACTION_LOGIN.equals(action)) {
            JSONArray permissions = args.getJSONArray(0);
            String[] perms = new String[permissions.length()];
            for (int i = 0; i < permissions.length(); i++) {
                perms[i] = permissions.getString(i);
            }
            return login(perms);
        } else {
            Log.e(TAG, "Unknown action: " + action);
            _callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "Unimplemented method: " + action));
            _callbackContext.error("Unimplemented method: " + action);
            return true;
        }
    }

    private boolean init(String appId) {
        this.cordova.setActivityResultCallback(this);
        Log.i(TAG, "VK initialize");
        VKSdk.initialize(getApplicationContext());

        _callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK));
        _callbackContext.success();
        return true;
    }

    private boolean login(String[] permissions) {
        if (VKSdk.isLoggedIn()) {
            VKAccessToken token = VKAccessToken.currentToken();
            returnTokenToCallback(token);
        }   else {
            VKSdk.login(getActivity(), permissions);
        }
        return true;
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        Log.i(TAG, "onActivityResult(" + requestCode + "," + resultCode + "," + data);
        if (!VKSdk.onActivityResult(requestCode, resultCode, data, new VKCallback<VKAccessToken>() {
            @Override
            public void onResult(VKAccessToken res) {
                returnTokenToCallback(res);
            }

            @Override
            public void onError(VKError error) {
                returnErrorToCallback(error.errorMessage);
            }
        })) {
            super.onActivityResult(requestCode, resultCode, data);
        }
    }

    private void returnTokenToCallback(VKAccessToken res) {
        try {
            final String token = res.accessToken;
            Log.i(TAG, "VK token: " + token);

            JSONObject loginDetails = new JSONObject();
            loginDetails.put("accessToken", token);
            loginDetails.put("expiresIn", res.expiresIn);

            res.saveTokenToSharedPreferences(getApplicationContext(), sTokenKey);
            _callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, loginDetails));
            _callbackContext.success();
        } catch (JSONException exception) {
            Log.e(TAG, "JSON error:", exception);
            returnErrorToCallback(exception.getMessage());
        }
    }

    private void returnErrorToCallback(String error) {
        Log.e(TAG, "VK error! " + error);
        _callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, error));
        _callbackContext.error(error);
    }
}
