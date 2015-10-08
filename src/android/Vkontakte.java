package com.studytime.vkontakte;

import org.json.JSONException;
import org.json.JSONArray;
import org.json.JSONObject;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.content.Context;
import android.content.Intent;
import android.widget.Toast;
import android.util.Log;
import android.os.AsyncTask;
import android.app.AlertDialog;
import android.app.Activity;
import android.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.HttpURLConnection;

import com.vk.sdk.VKAccessToken;
import com.vk.sdk.VKSdk;
import com.vk.sdk.VKUIHelper;
import com.vk.sdk.VKCallback;
import com.vk.sdk.VKScope;
import com.vk.sdk.api.VKApi;
import com.vk.sdk.api.VKError;
import com.vk.sdk.api.VKRequest;
import com.vk.sdk.api.VKRequest.VKRequestListener;
import com.vk.sdk.api.VKParameters;
import com.vk.sdk.api.VKResponse;
import com.vk.sdk.dialogs.VKCaptchaDialog;
import com.vk.sdk.dialogs.VKShareDialog;
import com.vk.sdk.api.photo.VKUploadImage;
import com.vk.sdk.api.photo.VKImageParameters;
import com.vk.sdk.util.VKJsonHelper;

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
   * @return the application context
   */
  private Context getApplicationContext() {
    return this.getActivity().getApplicationContext();
  }

  private Activity getActivity() {
    return (Activity)this.webView.getContext();
  }

  @Override
  public boolean execute(String action, CordovaArgs args, final CallbackContext callbackContext) throws JSONException {
    this._callbackContext = callbackContext;
    if(ACTION_INIT.equals(action)) {
      return init(args.getString(0));
    } else if (ACTION_LOGIN.equals(action)) {
      JSONArray permissions = args.getJSONArray(0);
      String[] perms = new String[permissions.length()];
      for(int i=0; i<permissions.length(); i++) {
        perms[i] = permissions.getString(i);
      }
      return login(perms);
    } else {
      Log.e(TAG, "Unknown action: "+action);
      _callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "Unimplemented method: " + action));
      _callbackContext.error("Unimplemented method: "+action);
      return true;
    }
  }

  private boolean init(String appId)
  {
    this.cordova.setActivityResultCallback(this);
    Log.i(TAG, "VK initialize");
    VKSdk.initialize(getApplicationContext());

    _callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK));
    _callbackContext.success();
    return true;
  }

  private boolean login(String[] permissions)
  {
    VKSdk.login(getActivity(), permissions);
    return true;
  }

  @Override public void onActivityResult(int requestCode, int resultCode, Intent data)
  {
    Log.i(TAG, "onActivityResult(" + requestCode + "," + resultCode + "," + data);
    if(!VKSdk.onActivityResult(requestCode, resultCode, data, new VKCallback<VKAccessToken>() {
        @Override
        public void onResult(VKAccessToken res) {
          // User passed Authorization
          try {
            final String token = res.accessToken;
            Log.i(TAG, "VK new token: "+token);

            JSONObject loginDetails = new JSONObject();
            loginDetails.put("accessToken", token);
            loginDetails.put("expiresIn", res.expiresIn);

            res.saveTokenToSharedPreferences(getApplicationContext(), sTokenKey);
            _callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, loginDetails));
            _callbackContext.success();
          } catch (JSONException exception) {
              Log.e(TAG, "JSON error:", exception);
          }
        }

        @Override
        public void onError(VKError error) {
          // User didn't pass Authorization
          String err = error.toString();
          Log.e(TAG, "VK Authorization error! "+err);
          _callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, err));
          _callbackContext.error(error.errorMessage);
        }
      })) {
      super.onActivityResult(requestCode, resultCode, data);
    }
  }
}
