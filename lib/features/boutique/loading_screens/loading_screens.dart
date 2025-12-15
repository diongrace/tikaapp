/// Écrans de chargement réutilisables pour l'application TIKA
///
/// Ce fichier exporte tous les écrans de chargement disponibles.
///
/// Usage:
/// ```dart
/// import 'package:tika_app/features/boutique/loading_screens/loading_screens.dart';
///
/// // Utiliser un écran de chargement
/// return const ShopLoadingScreen();
/// return const FavoritesLoadingScreen();
/// return OrderLoadingScreen(message: 'Création de la commande...');
/// return SimpleLoadingScreen(
///   title: 'Chargement...',
///   subtitle: 'Veuillez patienter',
///   icon: Icons.cloud_download,
/// );
/// ```

export 'shop_loading_screen.dart';
export 'order_loading_screen.dart';
export 'simple_loading_screen.dart';
export 'favorites_loading_screen.dart';
export 'orders_history_loading_screen.dart';
