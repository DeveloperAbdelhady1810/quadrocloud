<?php

return [
    'secret_key'      => env('PAYMOB_SECRET_KEY'),
    'public_key'      => env('PAYMOB_PUBLIC_KEY'),
    'hmac_secret'     => env('PAYMOB_HMAC_SECRET'),
    'payment_methods' => array_map('intval', explode(',', env('PAYMOB_PAYMENT_METHODS', '4599003,4568416,4568415'))),
    'base_url'        => 'https://accept.paymob.com',
    'expiration'      => 3600,
];
