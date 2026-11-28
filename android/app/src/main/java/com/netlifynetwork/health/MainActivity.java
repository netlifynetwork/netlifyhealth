package com.netlifynetwork.health;
import android.app.Activity;
import android.app.DownloadManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.Settings;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

public class MainActivity extends Activity {
 private WebView web;
 private DownloadManager downloadManager;
 private long downloadId=-1;
 private Uri pendingInstallUri;
 private BroadcastReceiver completedReceiver;
 private static final int INSTALL_PERMISSION_REQUEST=7021;
 public class AndroidUpdater {
  @JavascriptInterface public void downloadAndInstall(String url){
   runOnUiThread(()->{
    if(url==null||!url.startsWith("https://github.com/netlifynetwork/netlifyhealth/releases/download/")){
     Toast.makeText(MainActivity.this,"Update link is not trusted.",Toast.LENGTH_LONG).show();return;
    }
    try{
     DownloadManager.Request request=new DownloadManager.Request(Uri.parse(url));
     request.setTitle("Netlify Health update");
     request.setDescription("Downloading the latest Netlify Health APK");
     request.setMimeType("application/vnd.android.package-archive");
     request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
     request.setDestinationInExternalFilesDir(MainActivity.this,Environment.DIRECTORY_DOWNLOADS,"Netlify-Health-update.apk");
     downloadId=downloadManager.enqueue(request);
     Toast.makeText(MainActivity.this,"Downloading update. You can continue using the app.",Toast.LENGTH_LONG).show();
    }catch(Exception e){Toast.makeText(MainActivity.this,"Could not start update download: "+e.getMessage(),Toast.LENGTH_LONG).show();}
   });
  }
 }
 @Override public void onCreate(Bundle state){
  super.onCreate(state);
  downloadManager=(DownloadManager)getSystemService(DOWNLOAD_SERVICE);
  completedReceiver=new BroadcastReceiver(){@Override public void onReceive(Context c,Intent i){
   long id=i.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID,-1);
   if(id!=downloadId)return;
   Uri uri=downloadManager.getUriForDownloadedFile(id);
   if(uri==null){Toast.makeText(MainActivity.this,"Update download failed. Please try again.",Toast.LENGTH_LONG).show();return;}
   pendingInstallUri=uri;
   requestInstallPermissionAndOpen();
  }};
  IntentFilter filter=new IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE);
  if(Build.VERSION.SDK_INT>=33)registerReceiver(completedReceiver,filter,Context.RECEIVER_NOT_EXPORTED);else registerReceiver(completedReceiver,filter);
  web=new WebView(this);
  WebSettings settings=web.getSettings();settings.setJavaScriptEnabled(true);settings.setDomStorageEnabled(true);settings.setAllowFileAccess(true);
  web.addJavascriptInterface(new AndroidUpdater(),"AndroidUpdater");
  web.setWebViewClient(new WebViewClient());setContentView(web);web.loadUrl("file:///android_asset/index.html");
 }
 private void requestInstallPermissionAndOpen(){
  if(Build.VERSION.SDK_INT>=26&&!getPackageManager().canRequestPackageInstalls()){
   Intent settings=new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,Uri.parse("package:"+getPackageName()));
   startActivityForResult(settings,INSTALL_PERMISSION_REQUEST);return;
  }
  openInstaller();
 }
 private void openInstaller(){
  if(pendingInstallUri==null)return;
  try{Intent intent=new Intent(Intent.ACTION_VIEW);intent.setDataAndType(pendingInstallUri,"application/vnd.android.package-archive");intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION|Intent.FLAG_ACTIVITY_NEW_TASK);startActivity(intent);}
  catch(Exception e){Toast.makeText(this,"Open the downloaded update from your Downloads notification.",Toast.LENGTH_LONG).show();}
 }
 @Override protected void onActivityResult(int requestCode,int resultCode,Intent data){super.onActivityResult(requestCode,resultCode,data);if(requestCode==INSTALL_PERMISSION_REQUEST){if(Build.VERSION.SDK_INT<26||getPackageManager().canRequestPackageInstalls())openInstaller();else Toast.makeText(this,"Allow install unknown apps to install the update.",Toast.LENGTH_LONG).show();}}
 @Override protected void onDestroy(){if(completedReceiver!=null)try{unregisterReceiver(completedReceiver);}catch(Exception ignored){}if(web!=null)web.removeJavascriptInterface("AndroidUpdater");super.onDestroy();}
 @Override public void onBackPressed(){if(web!=null&&web.canGoBack())web.goBack();else super.onBackPressed();}
}
