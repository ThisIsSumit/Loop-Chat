import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Top-level handler for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background handling if needed
  await Firebase.initializeApp();
  debugPrint('Background message received: ${message.messageId}');
  debugPrint('Background message title: ${message.notification?.title}');
  debugPrint('Background message body: ${message.notification?.body}');
}

class FirebaseApi {
  // Singleton pattern
  static final FirebaseApi _instance = FirebaseApi._internal();
  factory FirebaseApi() => _instance;
  FirebaseApi._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Define channel with max importance for visibility
  final AndroidNotificationChannel _androidChannel =
      const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications',
    importance: Importance.max,
    enableVibration: true,
    playSound: true,
    showBadge: true,
  );

  bool _isInitialized = false;

  // Initialize notifications system
  Future<void> initNotifications() async {
    if (_isInitialized) return;

    try {
      debugPrint('Starting Firebase notification initialization');

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Request notification permissions with detailed logging
      debugPrint('Requesting notification permissions');
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
          'Notification permission status: ${settings.authorizationStatus}');

      // Initialize local notifications plugin
      debugPrint('Initializing local notifications plugin');
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final success = await _localNotifications.initialize(
        const InitializationSettings(
            android: androidSettings, iOS: iosSettings),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped: ${response.payload}');
          // Handle notification tap
        },
      );

      debugPrint('Local notifications initialized: $success');

      // Create notification channel for Android
      debugPrint('Creating Android notification channel');
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_androidChannel);
        debugPrint('Android notification channel created successfully');
      } else {
        debugPrint('Failed to get Android notification plugin');
      }

      // Set foreground notification presentation options
      debugPrint('Setting foreground notification options');
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('Foreground message received: ${message.messageId}');
        _handleForegroundMessage(message);
      });

      // Get FCM token for verification
      final token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');

      _isInitialized = true;
      debugPrint('Firebase notifications initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Error initializing notifications: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // Handle incoming foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      debugPrint('Processing foreground notification:');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');

      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null) {
        await _localNotifications.show(
          notification.hashCode,
          notification.title ?? 'New Notification',
          notification.body ?? 'You have a new notification',
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'New notification',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
        debugPrint('Local notification displayed');
      } else {
        debugPrint('No notification content to display');
      }
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  // New method to show chat notifications
  Future<void> showChatNotification({
    required String senderName,
    required String message,
    required String chatRoomId,
  }) async {
    try {
      await _localNotifications.show(
        chatRoomId.hashCode,
        'New message from $senderName',
        message,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'New message',
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: chatRoomId,
      );
      debugPrint('Chat notification displayed for room: $chatRoomId');
    } catch (e) {
      debugPrint('Error showing chat notification: $e');
    }
  }

  // Show a test notification (for debugging)
  Future<void> showTestNotification() async {
    try {
      debugPrint('Showing test notification');
      await _localNotifications.show(
        99,
        'Test Notification',
        'This is a test notification. If you can see this, local notifications are working properly.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'Test notification',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
      debugPrint('Test notification sent successfully');
    } catch (e) {
      debugPrint('Error showing test notification: $e');
    }
  }
}

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({Key? key}) : super(key: key);

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final FirebaseApi _firebaseApi = FirebaseApi();
  String _statusMessage = 'Ready to test notifications';
  bool _isInitializing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isInitializing
                    ? null
                    : () async {
                        setState(() {
                          _isInitializing = true;
                          _statusMessage = 'Initializing notifications...';
                        });

                        try {
                          await _firebaseApi.initNotifications();
                          setState(() {
                            _statusMessage = 'Notifications initialized';
                            _isInitializing = false;
                          });
                        } catch (e) {
                          setState(() {
                            _statusMessage = 'Error: $e';
                            _isInitializing = false;
                          });
                        }
                      },
                child: const Text('Initialize Notifications'),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _statusMessage = 'Sending test notification...';
                  });

                  try {
                    await _firebaseApi.showTestNotification();
                    setState(() {
                      _statusMessage =
                          'Test notification sent! Check your notification shade.';
                    });
                  } catch (e) {
                    setState(() {
                      _statusMessage = 'Error sending notification: $e';
                    });
                  }
                },
                child: const Text('Send Test Notification'),
              ),
              const SizedBox(height: 30),
              const Text(
                'Troubleshooting Tips:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                '• Check if notifications are blocked in system settings\n'
                '• Verify the app is not in battery optimization\n'
                '• Restart the app after granting permissions\n'
                '• Check logcat for detailed error messages',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
