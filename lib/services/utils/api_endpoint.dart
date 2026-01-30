class Endpoints {
  static const String baseUrl = 'https://prepro.tika-ci.com/api';

  // URL de base pour les fichiers de stockage (images, banners, etc.)
  static const String storageBaseUrl = 'https://prepro.tika-ci.com/storage';

  // Shops
  static const String shops = '$baseUrl/client/shops';
  static String shopDetails(int id) => '$baseUrl/client/shops/$id';
  static String shopProducts(int id) => '$baseUrl/client/shops/$id/products';
  static String shopCategories(int id) => '$baseUrl/client/shops/$id/categories';
  static const String shopsFeatured = '$baseUrl/client/shops/featured';

  // Products
  static const String products = '$baseUrl/client/products';
  static String productDetails(int id) => '$baseUrl/client/products/$id';
  static const String productsFeatured = '$baseUrl/client/products/featured';
  static const String productsSearch = '$baseUrl/client/products/search';

  // Orders
  static const String orders = '$baseUrl/client/orders';
  static const String orderTrack = '$baseUrl/client/orders/track';
  static String orderDetails(int id) => '$baseUrl/client/orders/$id';
  static String orderCancel(int id) => '$baseUrl/client/orders/$id/cancel';
  static String orderByNumber(String orderNumber) => '$baseUrl/client/orders/number/$orderNumber';
  static const String ordersByDevice = '$baseUrl/client/orders/by-device';

  // Receipts (Reçus de commande)
  static String orderReceiptDownload(String orderNumber) => '$baseUrl/client/orders/$orderNumber/receipt/download';
  static String orderReceiptView(String orderNumber) => '$baseUrl/client/orders/$orderNumber/receipt';

  // Categories
  static const String categories = '$baseUrl/client/categories';

  // Coupons
  static const String couponsValidate = '$baseUrl/client/coupons/validate';
  static String shopCoupons(int shopId) => '$baseUrl/client/shops/$shopId/coupons';

  // Loyalty
  static const String loyaltyCreateCard = '$baseUrl/client/loyalty/create-card';
  static String loyaltyCardByPhone(int shopId) => '$baseUrl/client/loyalty/shops/$shopId';
  static const String loyaltyCalculateDiscount = '$baseUrl/client/loyalty/calculate-discount';
  static const String loyaltyValidatePIN = '$baseUrl/client/loyalty/validate-pin';

  // Delivery Zones
  static String deliveryZones(int shopId) => '$baseUrl/client/shops/$shopId/delivery-zones';
  static const String deliveryZoneCalculateFee = '$baseUrl/client/delivery-zones/calculate-fee';

  // Favorites
  static const String favorites = '$baseUrl/client/favorites';
  static String removeFavorite(int shopId) => '$baseUrl/client/favorites/$shopId';

  // Restaurant (Menus du jour)
  static String restaurantDailyMenus(int restaurantId) => '$baseUrl/client/restaurants/$restaurantId/daily-menus';
  static String restaurantSupplements(int restaurantId) => '$baseUrl/client/restaurants/$restaurantId/supplements';
  static String restaurantBoissons(int restaurantId) => '$baseUrl/client/restaurants/$restaurantId/boissons';

  // Payment methods
  static String shopPaymentMethods(int shopId) => '$baseUrl/client/shops/$shopId/payment-methods';

  // Wave Payment (Mode Screenshot)
  static const String waveCreateWithProof = '$baseUrl/mobile/orders/create-with-wave-proof';
  static String waveSubmitProof(int orderId) => '$baseUrl/mobile/orders/$orderId/wave-proof';
  static String wavePaymentStatus(int orderId) => '$baseUrl/mobile/orders/$orderId/payment-status';

  // Authentification Client
  static const String clientRegister = '$baseUrl/client/register';
  static const String clientLogin = '$baseUrl/client/login';
  static const String clientSendOtp = '$baseUrl/client/send-otp';
  static const String clientVerifyOtp = '$baseUrl/client/verify-otp';
  static const String clientProfile = '$baseUrl/client/profile';
  static const String clientLogout = '$baseUrl/client/logout';
  static const String clientForgotPassword = '$baseUrl/client/forgot-password';
  static const String clientResetPassword = '$baseUrl/client/reset-password';

  // Notifications Client (nécessite authentification Bearer Token)
  static const String notifications = '$baseUrl/client/notifications';
  static String notificationDetails(int id) => '$baseUrl/client/notifications/$id';
  static const String notificationsUnreadCount = '$baseUrl/client/notifications/unread-count';
  static const String notificationsRecent = '$baseUrl/client/notifications/recent';
  static String notificationMarkRead(int id) => '$baseUrl/client/notifications/$id/read';
  static const String notificationsMarkMultipleRead = '$baseUrl/client/notifications/read';
  static const String notificationsMarkAllRead = '$baseUrl/client/notifications/read-all';
  static const String notificationsClearRead = '$baseUrl/client/notifications/clear-read';
  static const String notificationsSettings = '$baseUrl/client/notifications/settings';
  static const String notificationsRegisterDevice = '$baseUrl/client/notifications/register-device';

}
