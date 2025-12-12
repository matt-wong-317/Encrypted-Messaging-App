import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'ChatScreen.dart';
import 'package:timezone/timezone.dart' as tz;

final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();

// Handles the notifications
class Notifications {

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static int _id = 0;


  static Future<void> init() async {
    tz.initializeTimeZones();

    // Initializes logo and android settings for notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse){
        final payload = notificationResponse.payload;
        if (payload != null){
          final chat = int.tryParse(payload);
          if(chat != null){
            navigator.currentState?.push(
              MaterialPageRoute(builder: (_) => ChatScreenFromNoti(chatId: chat)),
            );
          }
        }
      }
    );
  }


  static Future<void> scheduleNotification(BuildContext context, {required int chat, required String sender, required String message}) async {

    // More details for android notifications. Sets the priority and importance of the notification to make it pop up on screen
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      channelDescription: 'channel_description',
      icon: 'app_icon',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    // Information of what the notification will display
    await flutterLocalNotificationsPlugin.show(
      _id++,
      sender,
      message,
      details,
      payload: chat.toString(),
    );
  }

  static Future<void> backgroundNotification(BuildContext context, {required int chat, required String sender, required String message}) async {

    // More details for android notifications. Sets the priority and importance of the notification to make it pop up on screen
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      channelDescription: 'channel_description',
      icon: 'app_icon',
      importance: Importance.low,
      priority: Priority.low,
    );

    const details = NotificationDetails(android: androidDetails);

    // Information of what the notification will display
    await flutterLocalNotificationsPlugin.show(
      _id++,
      sender,
      message,
      details,
      payload: chat.toString(),
    );
  }

  static Future<void> scheduleReminder(DateTime scheduledTime, int chatId, String contactName, String message) async {

    final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(scheduledTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'scheduled_reminder',
      'scheduled_messagenoti',
      channelDescription: 'schedules_messsagenotis',
      icon: 'app_icon',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    // Information of what the notification will display
    await flutterLocalNotificationsPlugin.zonedSchedule(
      chatId,
      'Scheduled Notification with $contactName',
      'Reminder!',
      scheduledTZ,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: chatId.toString(),
    );
  }


}
