package chat.metaphor.metaphor_beta;

import android.util.Log;

import com.google.firebase.messaging.FirebaseMessagingService;

public class FireBaseInstanceIDService extends FirebaseMessagingService {

    private static final String TAG = "MyFirebaseIIDService";

    @Override
    public void onNewToken(String s) {
        Log.e(TAG, "onNewToken: "+s );
        super.onNewToken(s);
    }

    /*@Override
    public void onTokenRefresh() {
//Getting registration token
        String refreshedToken = FirebaseInstanceId.getInstance().getToken();
//Displaying token on logcat
        Log.e(TAG, "Refreshed token: " + refreshedToken);
    }*/


}

