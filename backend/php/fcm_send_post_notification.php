<?php

declare(strict_types=1);

function sendNewPostNotification(array $post): array
{
    $configPath = __DIR__ . '/fcm_config.php';
    if (!is_file($configPath)) {
        throw new RuntimeException('Missing fcm_config.php. Copy fcm_config.example.php first.');
    }

    $config = require $configPath;
    $accessToken = createFirebaseAccessToken($config['service_account_path']);
    $message = buildNewPostMessage($post, $config);

    $response = fcmHttpPost(
        sprintf(
            'https://fcm.googleapis.com/v1/projects/%s/messages:send',
            $config['project_id']
        ),
        ['message' => $message],
        $accessToken
    );

    return [
        'success' => $response['status_code'] >= 200 && $response['status_code'] < 300,
        'status_code' => $response['status_code'],
        'response' => $response['body'],
    ];
}

function buildNewPostMessage(array $post, array $config): array
{
    $postId = trim((string) ($post['id'] ?? ''));
    $title = trim((string) ($post['title'] ?? ''));
    $description = trim((string) ($post['description'] ?? ''));
    $image = trim((string) ($post['image'] ?? ''));
    $link = trim((string) ($post['link'] ?? ''));

    if ($title === '') {
        $title = 'New post';
    }

    if ($description === '') {
        $description = 'A new post was published.';
    }

    if ($link === '') {
        $baseLink = rtrim((string) ($config['default_post_link'] ?? ''), '/');
        $link = $postId !== '' ? $baseLink . '/?id=' . rawurlencode($postId) : $baseLink;
    }

    $message = [
        'topic' => (string) ($config['topic'] ?? 'new_posts'),
        'notification' => [
            'title' => $title,
            'body' => $description,
        ],
        'data' => [
            'type' => 'new_post',
            'post_id' => $postId,
            'title' => $title,
            'description' => $description,
            'image' => $image,
            'link' => $link,
        ],
        'android' => [
            'priority' => 'high',
            'notification' => [
                'channel_id' => 'scrptaty_notifications',
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ],
        ],
        'apns' => [
            'headers' => [
                'apns-priority' => '10',
            ],
            'payload' => [
                'aps' => [
                    'sound' => 'default',
                    'mutable-content' => 1,
                ],
            ],
        ],
        'webpush' => [
            'fcm_options' => [
                'link' => $link,
            ],
        ],
    ];

    if ($image !== '') {
        $message['notification']['image'] = $image;
        $message['android']['notification']['image'] = $image;
        $message['apns']['fcm_options']['image'] = $image;
    }

    return $message;
}

function createFirebaseAccessToken(string $serviceAccountPath): string
{
    if (!is_file($serviceAccountPath)) {
        throw new RuntimeException('Firebase service account JSON file was not found.');
    }

    $credentials = json_decode((string) file_get_contents($serviceAccountPath), true, 512, JSON_THROW_ON_ERROR);

    $tokenUri = (string) ($credentials['token_uri'] ?? 'https://oauth2.googleapis.com/token');
    $now = time();
    $header = [
        'alg' => 'RS256',
        'typ' => 'JWT',
    ];
    $claims = [
        'iss' => $credentials['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => $tokenUri,
        'iat' => $now,
        'exp' => $now + 3600,
    ];

    $segments = [
        base64UrlEncode(json_encode($header, JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR)),
        base64UrlEncode(json_encode($claims, JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR)),
    ];
    $signingInput = implode('.', $segments);

    $privateKey = openssl_pkey_get_private($credentials['private_key']);
    if ($privateKey === false) {
        throw new RuntimeException('Unable to load the private key from service account JSON.');
    }

    $signature = '';
    $signed = openssl_sign($signingInput, $signature, $privateKey, OPENSSL_ALGO_SHA256);
    openssl_pkey_free($privateKey);

    if (!$signed) {
        throw new RuntimeException('Unable to sign the Firebase access token JWT.');
    }

    $jwt = $signingInput . '.' . base64UrlEncode($signature);

    $response = fcmHttpPost(
        $tokenUri,
        [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt,
        ],
        null,
        true
    );

    if ($response['status_code'] < 200 || $response['status_code'] >= 300) {
        throw new RuntimeException(
            'Unable to create Firebase access token. HTTP ' .
            $response['status_code'] .
            ' Response: ' .
            json_encode($response['body'], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE)
        );
    }

    if (empty($response['body']['access_token'])) {
        throw new RuntimeException('Firebase access token is missing from the OAuth response.');
    }

    return (string) $response['body']['access_token'];
}

function fcmHttpPost(
    string $url,
    array $payload,
    ?string $accessToken,
    bool $asFormData = false
): array {
    $ch = curl_init($url);
    if ($ch === false) {
        throw new RuntimeException('Failed to initialize cURL.');
    }

    $headers = [];
    if ($accessToken !== null) {
        $headers[] = 'Authorization: Bearer ' . $accessToken;
    }

    if ($asFormData) {
        $body = http_build_query($payload);
        $headers[] = 'Content-Type: application/x-www-form-urlencoded';
    } else {
        $body = json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
        $headers[] = 'Content-Type: application/json';
    }

    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_POSTFIELDS => $body,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 30,
    ]);

    $rawResponse = curl_exec($ch);
    if ($rawResponse === false) {
        $error = curl_error($ch);
        curl_close($ch);
        throw new RuntimeException('cURL request failed: ' . $error);
    }

    $statusCode = (int) curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
    curl_close($ch);

    $decoded = json_decode($rawResponse, true);
    $bodyResponse = is_array($decoded) ? $decoded : ['raw' => $rawResponse];

    return [
        'status_code' => $statusCode,
        'body' => $bodyResponse,
    ];
}

function base64UrlEncode(string $data): string
{
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}
