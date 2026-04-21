package com.alarmbroadcastreceiver;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.app.*;
import android.os.*;

import java.util.*;
import java.text.*;

import android.media.Ringtone;
import android.media.RingtoneManager;
import android.net.Uri;

import java.io.File;
import java.io.IOException;
import java.io.BufferedWriter;
import java.io.FileWriter;

public class alarmreceiver extends BroadcastReceiver{

    // FIX: переносим WakeLock на уровень класса
    private static PowerManager.WakeLock wakeLock = null;

//    private static PowerManager.WakeLock wakeLock       = null;

    // Для записи в файл на устройстве нужны соответствующие permissions
    // Иначе приложеие просто падает
    private void SaveText(Context context, String fileName, String textInfo) {
        File fileOutput = new File(context.getExternalFilesDir(null), fileName);
        try {
            // открываем поток для записи
            BufferedWriter bw = new BufferedWriter(new FileWriter(fileOutput, true));
            // пишем данные
            bw.write(textInfo);
            bw.newLine();
            // закрываем поток
            bw.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onReceive(Context context, Intent intent){	    

        // FIX: локальную переменную НЕ используем (иначе всегда null)
        // PowerManager.WakeLock wakeLock = null;

	String    		activityName   	= "com.embarcadero.firemonkey.FMXNativeActivity";	
        Date                	dateTimeAlarm   = null;
        String              	stringDateTime;
        String              	stringDateTimeNow;

        SimpleDateFormat    	dateTimeFormat  = new SimpleDateFormat ("dd.MM.yyyy HH:mm:ss", Locale.US);

        Intent              	intentLaunching = new Intent(context, alarmreceiver.class);
		android.util.Log.d("ALARM_DEBUG", "onReceive Entered");
		if (Build.VERSION.SDK_INT > 23) {		                                //huawei
			//SaveText(context, "launchintent.txt", "SDK_INT > 23 ");

            // FIX: проверяем состояние WakeLock
			if (wakeLock == null || !wakeLock.isHeld()) {
				PowerManager pm 	= (PowerManager) context.getSystemService(Context.POWER_SERVICE);
	//			wakeLock 		= pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "AlarmBroadcastReceiver:Alarm");
				wakeLock 		= pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK | PowerManager.ON_AFTER_RELEASE, "alarmbroadcastreceiver:alarm");

				wakeLock.acquire(2 * 60 * 1000);
			};                   
				
			//SaveText(context, "launchintent.txt", "after wake lock acquired");

			stringDateTimeNow = dateTimeFormat.format(new Date());
			//SaveText(context, "launchintent.txt", stringDateTimeNow);

			Uri notification  = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
			Ringtone ringtone = RingtoneManager.getRingtone(context.getApplicationContext(), notification);
			ringtone.play();
			//SaveText(context, "launchintent.txt", "after ringtone.play");

			intentLaunching.setClassName(context, activityName);
//			intentLaunching.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_MULTIPLE_TASK);
			intentLaunching.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
			intentLaunching.putExtra("StartedFromAlarmReceiver", true);
			android.util.Log.d("ALARM_DEBUG", "TRY START ACTIVITY");
			context.startActivity(intentLaunching);
			android.util.Log.d("ALARM_DEBUG", "AFTER START ACTIVITY CALL");			
			//SaveText(context, "launchintent.txt", "after intentLaunching");

//			SystemClock.sleep(1000);
//			SaveText(context, "launchintent.txt", "after sleep");

//			wakeLock.release();  							//отключаем освобождение вэйклока 201022

            // FIX: НЕ обнуляем wakeLock — иначе теряется ссылка
			// wakeLock = null;

			//SaveText(context, "launchintent.txt", "after wake lock released");
		}
		else if (Build.VERSION.SDK_INT <= 23) {						//samsung		
			//SaveText(context, "launchintent.txt", "SDK_INT <= 23 ");

            // FIX: проверяем состояние WakeLock
			if (wakeLock == null || !wakeLock.isHeld()) {
				PowerManager pm 	= (PowerManager) context.getSystemService(Context.POWER_SERVICE);
//				wakeLock 		= pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK | PowerManager.ON_AFTER_RELEASE, "AlarmBroadcastReceiver:Alarm");
				wakeLock 		= pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK | PowerManager.ON_AFTER_RELEASE, "alarmbroadcastreceiver:alarm");

				wakeLock.acquire(2 * 60 * 1000);
			}                   
				
			//SaveText(context, "launchintent.txt", "after wake lock acquired");

			stringDateTimeNow = dateTimeFormat.format(new Date());
			//SaveText(context, "launchintent.txt", stringDateTimeNow);

			Uri notification  = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
			Ringtone ringtone = RingtoneManager.getRingtone(context.getApplicationContext(), notification);
			ringtone.play();
			//SaveText(context, "launchintent.txt", "after ringtone.play");

			intentLaunching.setClassName(context, activityName);
//			intentLaunching.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_MULTIPLE_TASK);
			intentLaunching.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_NEW_TASK);
			intentLaunching.putExtra("StartedFromAlarmReceiver", true);
			context.startActivity(intentLaunching);
			//SaveText(context, "launchintent.txt", "after intentLaunching");

//			SystemClock.sleep(1000);						//отключаем таймер 201022
//			SaveText(context, "launchintent.txt", "after sleep");

//			wakeLock.release();                                                     //не снимать вэйклок

            // FIX: НЕ обнуляем wakeLock
			// wakeLock = null;                                                        
												//он должен сниматься сам через wakeLock.acquire(2 * 60 * 1000); 
												//в скобках указываем время задержки перед снятием
			//SaveText(context, "launchintent.txt", "after wake lock released");
		};
	}
}