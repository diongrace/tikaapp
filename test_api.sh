#!/bin/bash

# Test 1 : Créer une commande avec device_fingerprint
echo "=== TEST 1 : Création de commande avec device_fingerprint ==="
curl -X POST https://tika-ci.com/api/orders-simple \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "shop_id": 1,
    "customer_name": "Test Device Fingerprint",
    "customer_phone": "+22500000000",
    "service_type": "À emporter",
    "payment_method": "especes",
    "device_fingerprint": "TEST_DEVICE_123456",
    "items": [
      {
        "product_id": 1,
        "quantity": 1,
        "price": 1000
      }
    ]
  }' | jq .

echo ""
echo "=== TEST 2 : Récupération par device_fingerprint ==="
sleep 2
curl -X POST "https://tika-ci.com/api/mobile/orders/by-device?page=1" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "device_fingerprint": "TEST_DEVICE_123456"
  }' | jq .
