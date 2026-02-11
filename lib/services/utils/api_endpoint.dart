class Endpoints {
  static const String baseUrl = 'https://prepro.tika-ci.com/api';

  // URL de base pour les fichiers de stockage (images, banners, etc.)
  static const String storageBaseUrl = 'https://prepro.tika-ci.com/storage';

  // Shops (sous /api/client/shops/)
  static const String shops = '$baseUrl/client/shops';
  static String shopDetails(int id) => '$baseUrl/client/shops/$id';
  static String shopProducts(int id) => '$baseUrl/client/shops/$id/products';
  static String shopCategories(int id) => '$baseUrl/client/shops/$id/categories';
  static const String shopsFeatured = '$baseUrl/client/shops/featured';
  static String shopBySlug(String slug) => '$baseUrl/client/shops/slug/$slug';

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
  static const String loyaltyCards = '$baseUrl/client/loyalty';
  static const String loyaltyStats = '$baseUrl/client/loyalty/stats';
  static const String loyaltyCreateCard = '$baseUrl/client/loyalty/cards';
  static String loyaltyCardDetail(int id) => '$baseUrl/client/loyalty/cards/$id';
  static String loyaltyCardHistory(int id) => '$baseUrl/client/loyalty/cards/$id/history';
  static String loyaltyCardRewards(int id) => '$baseUrl/client/loyalty/cards/$id/rewards';
  static String loyaltyCardQrCode(int id) => '$baseUrl/client/loyalty/cards/$id/qr-code';
  static String loyaltyCardVerifyPin(int id) => '$baseUrl/client/loyalty/cards/$id/verify-pin';
  static String loyaltyCardByShop(int shopId) => '$baseUrl/client/loyalty/shops/$shopId';
  static const String loyaltyCalculateDiscount = '$baseUrl/client/loyalty/calculate-discount';

  // Delivery Zones & Options
  static String deliveryZones(int shopId) => '$baseUrl/client/shops/$shopId/delivery-zones';
  static String deliveryOptions(int shopId) => '$baseUrl/client/shops/$shopId/delivery-options';
  static const String deliveryZoneCalculateFee = '$baseUrl/client/delivery-zones/calculate-fee';

  // Favorites
  static const String favorites = '$baseUrl/client/favorites';
  static const String favoritesStats = '$baseUrl/client/favorites/stats';
  static const String favoritesSuggestions = '$baseUrl/client/favorites/suggestions';
  static const String favoritesToggle = '$baseUrl/client/favorites/toggle';
  static String favoriteDetail(int id) => '$baseUrl/client/favorites/$id';
  static String favoriteCheck(int id) => '$baseUrl/client/favorites/$id/check';
  static String removeFavorite(int id) => '$baseUrl/client/favorites/$id';

  // Restaurant (Menus du jour)
  static String restaurantDailyMenus(int restaurantId) => '$baseUrl/client/restaurants/$restaurantId/daily-menus';
  static String restaurantSupplements(int restaurantId) => '$baseUrl/client/restaurants/$restaurantId/supplements';
  static String restaurantBoissons(int restaurantId) => '$baseUrl/client/restaurants/$restaurantId/boissons';

  // Payment methods
  static String shopPaymentMethods(int shopId) => '$baseUrl/client/shops/$shopId/payment-methods';
  static String vendorPaymentMethods(int shopId) => '$baseUrl/vendor/shops/$shopId/payment-methods';

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

  // Profil Client (necessite authentification Bearer Token)
  static const String clientProfileStats = '$baseUrl/client/profile/stats';
  static const String clientProfilePassword = '$baseUrl/client/profile/password';
  static const String clientProfileAddresses = '$baseUrl/client/profile/addresses';
  static String clientProfileAddress(int id) => '$baseUrl/client/profile/addresses/$id';
  static String clientProfileAddressDefault(int id) => '$baseUrl/client/profile/addresses/$id/default';

  // Dashboard Client (nécessite authentification Bearer Token)
  static const String dashboard = '$baseUrl/client/dashboard';
  static const String dashboardOrders = '$baseUrl/client/dashboard/orders';
  static String dashboardOrderDetails(int id) => '$baseUrl/client/dashboard/orders/$id';
  static const String dashboardLoyalty = '$baseUrl/client/dashboard/loyalty';
  static const String dashboardFavorites = '$baseUrl/client/dashboard/favorites';
  static const String dashboardStats = '$baseUrl/client/dashboard/stats';
  static const String dashboardNotifications = '$baseUrl/client/dashboard/notifications';
  static const String dashboardNotificationsRead = '$baseUrl/client/dashboard/notifications/read';

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

  // Support Tickets (nécessite authentification Bearer Token)
  static const String support = '$baseUrl/client/support';
  static const String supportOptions = '$baseUrl/client/support/options';
  static String supportDetail(int id) => '$baseUrl/client/support/$id';
  static String supportStatus(int id) => '$baseUrl/client/support/$id/status';

}
