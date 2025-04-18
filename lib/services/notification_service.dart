import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// TODO: Import timezone package if scheduling notifications (flutter pub add timezone)
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> init() async {
    // Initialization settings for Android
    // TODO: Use a proper app icon name (e.g., @mipmap/ic_launcher)
    const AndroidInitializationSettings
    initializationSettingsAndroid = AndroidInitializationSettings(
      'app_icon',
    ); // Replace 'app_icon' with your actual icon file name without extension

    // Initialization settings for iOS
    // TODO: Request permissions for iOS if needed
    const DarwinInitializationSettings
    initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // onDidReceiveLocalNotification: onDidReceiveLocalNotification, // Optional callback
    );

    // Initialization settings for Linux
    // final LinuxInitializationSettings initializationSettingsLinux =
    //     LinuxInitializationSettings(defaultActionName: 'Open notification');

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          // linux: initializationSettingsLinux,
        );

    // Initialize the plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // onDidReceiveNotificationResponse: onDidReceiveNotificationResponse, // Optional callback for notification tap
    );

    // TODO: Create Android Notification Channels if targeting Android 8.0+
    // await _createAndroidNotificationChannels();

    // TODO: Request notification permissions on Android 13+
    // await _requestAndroidPermissions();

    // TODO: Initialize timezone database if scheduling notifications
    // tz.initializeTimeZones();

    print("NotificationService initialized.");
  }

  // --- Android Specific Setup ---

  // Future<void> _createAndroidNotificationChannels() async {
  //   const AndroidNotificationChannel channel = AndroidNotificationChannel(
  //     'fitstride_channel_id', // id
  //     'FitStride Notifications', // title
  //     description: 'Channel for FitStride workout reminders and achievements.', // description
  //     importance: Importance.max,
  //   );
  //   await _flutterLocalNotificationsPlugin
  //       .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
  //       ?.createNotificationChannel(channel);
  //   print("Android Notification Channel created.");
  // }

  // Future<void> _requestAndroidPermissions() async {
  //   final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
  //       _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
  //           AndroidFlutterLocalNotificationsPlugin>();
  //   final bool? granted = await androidImplementation?.requestNotificationsPermission();
  //   print("Android notification permission granted: $granted");
  // }

  // --- Basic Notification Methods ---

  Future<void> showSimpleNotification({
    required int id,
    required String title,
    required String body,
    String? payload, // Optional data to pass when notification is tapped
  }) async {
    // TODO: Use the created Android channel ID
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'fitstride_channel_id', // Channel ID
          'FitStride Notifications', // Channel name
          channelDescription:
              'Channel for FitStride workout reminders and achievements.',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker', // Optional ticker text
        );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    // const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      // linux: linuxDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
    print("Shown notification id: $id, title: $title");
  }

  // TODO: Implement scheduled notifications (Task 9.4.5)
  // Future<void> scheduleNotification({
  //   required int id,
  //   required String title,
  //   required String body,
  //   required DateTime scheduledDateTime,
  //   String? payload,
  // }) async {
  //   await _flutterLocalNotificationsPlugin.zonedSchedule(
  //     id,
  //     title,
  //     body,
  //     tz.TZDateTime.from(scheduledDateTime, tz.local),
  //     const NotificationDetails(
  //       android: AndroidNotificationDetails(
  //         'fitstride_channel_id',
  //         'FitStride Notifications',
  //         channelDescription: 'Scheduled notifications channel.',
  //         importance: Importance.max,
  //         priority: Priority.high,
  //       ),
  //       // iOS details...
  //     ),
  //     androidAllowWhileIdle: true, // Deprecated, use scheduleMode instead
  //     // androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  //     uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
  //     matchDateTimeComponents: DateTimeComponents.time, // Example: match time daily
  //     payload: payload,
  //   );
  //   print("Scheduled notification id: $id for $scheduledDateTime");
  // }

  // TODO: Implement periodic notifications if needed

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    print("Cancelled notification id: $id");
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    print("Cancelled all notifications.");
  }

  // --- Callbacks (Optional) ---
  // static void onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async {
  //   // Handle foreground notification reception on older iOS versions
  //   print('Foreground notification received on iOS: id $id, title $title');
  // }

  // static void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
  //   // Handle notification tap
  //   final String? payload = notificationResponse.payload;
  //   if (payload != null) {
  //     print('Notification tapped with payload: $payload');
  //     // Navigate to specific screen based on payload
  //   }
  //   // Example: selectNotificationSubject.add(payload);
  // }
}

// Optional: Stream for notification taps
// final BehaviorSubject<String?> selectNotificationSubject = BehaviorSubject<String?>();
