# FCM PHP setup

These files prepare the PHP side for sending a push notification when a new post is created.

## Files

- `fcm_config.example.php`: copy this file to `fcm_config.php`
- `fcm_send_post_notification.php`: reusable helper that sends a new-post notification to a Firebase topic
- `example_publish_post.php`: example endpoint showing how to call the helper after saving a post

## 1. Configure Firebase

1. Create a Firebase project.
2. Enable Cloud Messaging.
3. Generate a service account JSON from:
   Firebase Console -> Project settings -> Service accounts
4. Save that JSON file as:
   `backend/php/firebase-service-account.json`
5. Copy:
   `backend/php/fcm_config.example.php`
   to:
   `backend/php/fcm_config.php`
6. Update `project_id` inside `fcm_config.php`.

## 2. Send to a topic

This PHP setup sends notifications to topic:

`new_posts`

Your Flutter app must subscribe users to the same topic.

## 3. Call after insert

After you insert a new post into the database, call:

```php
require __DIR__ . '/fcm_send_post_notification.php';

sendNewPostNotification([
    'id' => $postId,
    'title' => $title,
    'description' => $description,
    'image' => $imageUrl,
    'link' => 'https://scrptaty.com/posts/?id=' . urlencode((string) $postId),
]);
```

## 4. Post data expected by PHP

The helper expects:

- `id`
- `title`
- `description`
- `image`
- `link` (optional, but recommended)

## 5. Flutter side still required

This repository is not yet configured for Firebase Messaging. I did not add Firebase packages because the project is missing:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

You still need to configure the Flutter app with Firebase, then:

1. initialize Firebase
2. add `firebase_messaging`
3. request notification permission
4. subscribe the user to topic `new_posts`
5. handle foreground/background notifications

## 6. iOS image notifications

If you want notification images on iPhone, you also need an iOS Notification Service Extension.

## 7. Notes

- The image URL must be public and reachable by Firebase.
- Keep the service account JSON outside the public web root in production.
- Call the notification helper only after the database insert succeeds.
