import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'bible_verse_service.dart';

class NotificationService {
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      'resource://mipmap/launcher_icon.png', // Using default app icon
      [
        NotificationChannel(
          channelGroupKey: 'bible_verse_group',
          channelKey: 'bible_verse',
          channelName: 'Bible Verses',
          channelDescription: 'Daily Bible verse notifications',
          defaultColor: Colors.blueGrey,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        )
      ],
    );

    // Request notification permissions
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  static Future<void> scheduleDailyVerse() async {
    final verse = await BibleVerseService.getTodayVerse();
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'bible_verse',
        title: 'آية اليوم 📖',
        body: verse,
        icon: 'resource://mipmap/launcher_icon',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: 21, // 8 PM
        minute: 0,
        second: 0,
        repeats: true, // Repeat daily
      ),
    );
  }

  static Future<void> cancelScheduledNotifications() async {
    await AwesomeNotifications().cancelAllSchedules();
  }
}