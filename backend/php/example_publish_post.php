<?php

declare(strict_types=1);

require __DIR__ . '/fcm_send_post_notification.php';

/*
Replace this sample with your real insert-post logic.
Call sendNewPostNotification() only after the post is successfully saved.
*/

$newPost = [
    'id' => '25',
    'title' => 'Example new post',
    'description' => 'This post was created from the backend.',
    'image' => 'https://scrptaty.com/posts/upload/example.png',
    'link' => 'https://scrptaty.com/posts/?id=25',
];

try {
    $result = sendNewPostNotification($newPost);

    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(
        [
            'ok' => $result['success'],
            'status_code' => $result['status_code'],
            'fcm_response' => $result['response'],
        ],
        JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE
    );
} catch (Throwable $e) {
    http_response_code(500);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(
        [
            'ok' => false,
            'error' => $e->getMessage(),
        ],
        JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE
    );
}
