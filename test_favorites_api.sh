#!/bin/bash

# Script de test pour l'API des favoris

echo "🔍 Test de l'API Favoris TIKA"
echo "=============================="
echo ""

# Configuration
BASE_URL="https://prepro.tika-ci.com/api"
DEVICE_FP="test_device_123"

echo "📡 Base URL: $BASE_URL"
echo "🔑 Device Fingerprint: $DEVICE_FP"
echo ""

# Test 1: Récupérer les favoris
echo "📥 Test 1: GET /client/favorites"
echo "------------------------------------"
curl -X GET "$BASE_URL/client/favorites?device_fingerprint=$DEVICE_FP" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -w "\n\n📊 HTTP Status: %{http_code}\n" \
  -s | jq '.'

echo ""
echo ""

# Test 2: Ajouter un favori (shop_id=10)
echo "📤 Test 2: POST /client/favorites (Ajouter boutique 10)"
echo "------------------------------------"
curl -X POST "$BASE_URL/client/favorites" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"shop_id\": 10, \"device_fingerprint\": \"$DEVICE_FP\"}" \
  -w "\n\n📊 HTTP Status: %{http_code}\n" \
  -s | jq '.'

echo ""
echo ""

# Test 3: Récupérer à nouveau les favoris
echo "📥 Test 3: GET /client/favorites (après ajout)"
echo "------------------------------------"
curl -X GET "$BASE_URL/client/favorites?device_fingerprint=$DEVICE_FP" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -w "\n\n📊 HTTP Status: %{http_code}\n" \
  -s | jq '.'

echo ""
echo ""

# Test 4: Retirer le favori
echo "🗑️ Test 4: DELETE /client/favorites/10"
echo "------------------------------------"
curl -X DELETE "$BASE_URL/client/favorites/10?device_fingerprint=$DEVICE_FP" \
  -H "Accept: application/json" \
  -w "\n\n📊 HTTP Status: %{http_code}\n" \
  -s | jq '.'

echo ""
echo "✅ Tests terminés"
