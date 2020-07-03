package chat.metaphor.metaphor_beta;

import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
  public static MethodChannel methodChannel;
  private String CHANNEL = "com.metaphor.flutterchatapp/platform_channel";
  Intent intent;
  private String TAG = MainActivity.class.getSimpleName();

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
    methodChannel = new MethodChannel(getFlutterView(),CHANNEL);

    intent = getIntent();
    new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
            (call, result) -> {
              if (call.method.equals("getIntent")) {
                if (intent != null) {
                  if (intent.hasExtra("type")) {
                    if (intent.getStringExtra("type").equalsIgnoreCase("100")) {

                      JSONObject userDetails = new JSONObject();

                      try {
                        userDetails.put("user_id", intent.getStringExtra("user_id"));
                        userDetails.put("user_name", intent.getStringExtra("user_name"));
                        userDetails.put("user_token", intent.getStringExtra("user_token"));
                        userDetails.put("user_pic", intent.getStringExtra("user_pic"));
                        userDetails.put("user_type", intent.getStringExtra("user_type"));

                      } catch (JSONException e) {
                        e.printStackTrace();
                      }
                      //intent = null;
                      result.success(userDetails.toString());
                    } else {
                      //intent = null;
                      android.util.Log.e(TAG, "onCreate: type not 100" );
                      result.success("false");
                    }
                  } else {
                    //intent = null;
                    android.util.Log.e(TAG, "onCreate: type not found" );
                    result.success("false");
                  }
                }  else {
                  //intent = null;
                  android.util.Log.e(TAG, "onCreate: No Intent" );
                  result.success("false");
                }
              } else {
                //intent = null;
                result.notImplemented();
              }
            });

  }


  @Override
  public void onNewIntent(Intent intent) {
    super.onNewIntent(intent);
    Log.e("MainActivity", "onNewIntent: "+intent.hasExtra("type"));

    if (intent != null) {
      if (intent.hasExtra("type")) {
        if (intent.getStringExtra("type").equalsIgnoreCase("100")) {

          JSONObject userDetails = new JSONObject();

          try {
            userDetails.put("user_id", intent.getStringExtra("user_id"));
            userDetails.put("user_name", intent.getStringExtra("user_name"));
            userDetails.put("user_token", intent.getStringExtra("user_token"));
            userDetails.put("user_pic", intent.getStringExtra("user_pic"));
            userDetails.put("user_type", intent.getStringExtra("user_type"));


            new Handler(Looper.getMainLooper()).post(new Runnable() {
              @Override
              public void run() {
                MainActivity.methodChannel.invokeMethod("notification", userDetails.toString());
              }
            });

          } catch (JSONException e) {
            e.printStackTrace();
          }
        }
      }
    }



  }


}

