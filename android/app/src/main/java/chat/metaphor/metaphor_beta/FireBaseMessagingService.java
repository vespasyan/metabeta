package chat.metaphor.metaphor_beta;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.Rect;
import android.graphics.RectF;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.core.app.NotificationCompat;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Map;

public class FireBaseMessagingService extends FirebaseMessagingService {

    private static final String TAG = "MyFirebaseMsgService";
    private static int count = 0;
    String CHANNEL_ID = "Metaphor Notification";


    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {


        Log.e(TAG, "onMessageReceived: " + remoteMessage.getData());

        //Displaying data in log
        //It is optional
        /*Log.d(TAG, "Notification Message TITLE: " + remoteMessage.getNotification().getTitle());
        Log.d(TAG, "Notification Message BODY: " + remoteMessage.getNotification().getBody());
        Log.d(TAG, "Notification Message DATA: " + remoteMessage.getData().toString());
        Log.d(TAG, "Tag1"+remoteMessage.getData().get("tag1").toString());
        Log.d(TAG, "Tag2"+remoteMessage.getData().get("tag2").toString());*/
        //Calling method to generate notification


        if (MainActivity.methodChannel != null) {
            JSONObject userDetails = new JSONObject();

            try {
                userDetails.put("noti", "arrived");
                userDetails.put("user_id", remoteMessage.getData().get("user_id"));
                userDetails.put("user_name", remoteMessage.getData().get("user_name"));
                userDetails.put("user_token", remoteMessage.getData().get("user_token"));
                userDetails.put("user_pic", remoteMessage.getData().get("user_pic"));
                userDetails.put("user_type", remoteMessage.getData().get("user_type"));

            } catch (JSONException e) {
                e.printStackTrace();
            }
            //MainActivity.methodChannel.invokeMethod("notification", "arrived");


           /* new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    MainActivity.methodChannel.invokeMethod("notification", userDetails.toString());
                }
            });
*/
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            int importance = NotificationManager.IMPORTANCE_HIGH;

            Uri defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
            NotificationChannel mChannel = new NotificationChannel(CHANNEL_ID, "NOTFICATION CHANNEL", importance);

            mChannel.enableLights(true);
            mChannel.enableVibration(true);
           /* mChannel.setLightColor(ContextCompat.getColor(getApplicationContext(),R.color
                    .colorPrimary));*/
            mChannel.setLockscreenVisibility(Notification.VISIBILITY_PUBLIC);


            NotificationManager notificationManager =
                    (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
            notificationManager.createNotificationChannel(mChannel);

            PendingIntent contentIntent =
                    PendingIntent.getActivity(this, 0,
                            new Intent(this, MainActivity.class)
                                    .putExtra("type", remoteMessage.getData().get("type"))
                                    .putExtra("user_id", remoteMessage.getData().get("user_id"))
                                    .putExtra("user_name", remoteMessage.getData().get("user_name"))
                                    .putExtra("user_token", remoteMessage.getData().get("user_token"))
                                    .putExtra("user_pic", remoteMessage.getData().get("user_pic"))
                                    .putExtra("user_type", remoteMessage.getData().get("user_device_type"))
                            , PendingIntent.FLAG_ONE_SHOT);

            //PendingIntent contentIntent = null;

            NotificationCompat.Builder notificationBuilder = new NotificationCompat.Builder(this)
                    .setLargeIcon(getCircleBitmap(getBitmapFromURL(remoteMessage.getData().get("user_pic"))))
                    .setSmallIcon(R.mipmap.ic_launcher)
                    .setContentTitle(remoteMessage.getData().get("user_name"))
                    .setContentText(remoteMessage.getData().get("msg"))
                    .setPriority(NotificationCompat.PRIORITY_HIGH)
                    .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                    .setAutoCancel(true)
                    .setChannelId(CHANNEL_ID)
                    .setSound(defaultSoundUri)
                    .setContentIntent(contentIntent);
            notificationManager.notify(count, notificationBuilder.build());
            count++;
        } else {

            sendNotification(remoteMessage.getData().get("user_id"), remoteMessage.getData().get("user_name"),
                    remoteMessage.getData().get("msg"), remoteMessage.getData().get("user_pic"), remoteMessage.getData().get("type"), remoteMessage.getData().get("user_device_type"), remoteMessage.getData().get("user_token"), remoteMessage.getData());

        }
    }

    //This method is only generating push notification
    private void sendNotification(String userId, String messageTitle, String messageBody, String profileImg, String type, String deviceToken, String userType, Map<String, String> row) {
        NotificationManager notificationManager;
        //PendingIntent contentIntent = null;

        PendingIntent contentIntent =
                PendingIntent.getActivity(this, 0,
                        new Intent(this, MainActivity.class)
                                .putExtra("type", type)
                                .putExtra("user_id", userId)
                                .putExtra("user_name", messageTitle)
                                .putExtra("user_token", deviceToken)
                                .putExtra("user_pic", profileImg)
                                .putExtra("user_type", userType)

                        , PendingIntent.FLAG_ONE_SHOT);

        //PendingIntent contentIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_ONE_SHOT);
        Uri defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
        NotificationCompat.Builder notificationBuilder = new NotificationCompat.Builder(this)
                .setLargeIcon(getCircleBitmap(getBitmapFromURL(profileImg)))
                //.setLargeIcon(BitmapFactory.decodeResource(getResources(), R.mipmap.ic_launcher))
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(messageTitle)
                .setContentText(messageBody)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setAutoCancel(true)
                .setSound(defaultSoundUri)
                .setContentIntent(contentIntent);


        notificationManager =
                (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        notificationManager.notify(count, notificationBuilder.build());
        count++;


    }


    public Bitmap getBitmapFromURL(String strURL) {

        if (strURL != null ) {

            try {
                URL url = new URL(strURL);
                HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                connection.setDoInput(true);
                connection.connect();
                InputStream input = connection.getInputStream();
                Bitmap myBitmap = BitmapFactory.decodeStream(input);
                return myBitmap;
            } catch (IOException e) {
                e.printStackTrace();
                return null;
            }
        } else {
            return  null;
        }

    }


    private Bitmap getCircleBitmap(Bitmap bitmap) {

        if (bitmap != null) {

            final Bitmap output = Bitmap.createBitmap(bitmap.getWidth(),
                    bitmap.getWidth(), Bitmap.Config.ARGB_8888);
            final Canvas canvas = new Canvas(output);

            final int color = Color.RED;
            final Paint paint = new Paint();
            final Rect rect = new Rect(0, 0, bitmap.getWidth(), bitmap.getWidth());
            final RectF rectF = new RectF(rect);

            paint.setAntiAlias(true);
            canvas.drawARGB(0, 0, 0, 0);
            paint.setColor(color);
            canvas.drawOval(rectF, paint);

            paint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.SRC_IN));
            canvas.drawBitmap(bitmap, rect, rect, paint);

            bitmap.recycle();

            return output;
        }else {
            return  null;
        }
    }

}

