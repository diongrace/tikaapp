import 'package:flutter/material.dart';
import '../features/splash/SplashScreen.dart';
import '../features/welcome/WelcomeScreen.dart';
import '../features/onboarding/OnboardingScreen_1.dart';
import '../features/onboarding/OnboardingScreen_2.dart';
import '../features/onboarding/OnboardingScreen_3.dart';
import '../features/onboarding/OnboardingScreen_4.dart';
import '../features/access_boutique/access_boutique_screen.dart';
import '../features/qr_scanner/qr_scanner_screen.dart';
import '../features/boutique/panier/panier_screen.dart';
import '../features/boutique/commande/loading_success_page.dart';
import '../features/boutique/favorites/favorites_boutiques_screen.dart';
import '../features/boutique/history/global_history_screen.dart';
import '../features/boutique/notifications/notifications_list_screen.dart';
import '../features/boutique/profile/profile_screen.dart';
import '../features/boutique/profile/personal_info_screen.dart';
import '../features/boutique/profile/addresses_screen.dart';
import '../features/boutique/profile/payment_methods_screen.dart';
import '../features/boutique/profile/notifications_screen.dart';
import '../features/boutique/profile/security_screen.dart';
import '../features/boutique/profile/help_support_screen.dart';
import '../features/boutique/home/home_online_screen.dart';

/// Configuration des routes de l'application
/// Définit les chemins de navigation entre les différents écrans
final Map<String, WidgetBuilder> appRoutes = {
  // Route initiale - Écran de démarrage avec animation TIKA
  '/': (context) => const SplashScreen(),

  // Route de bienvenue - Affichée après le splash
  '/welcome': (context) => const WelcomeScreen(),

  // Routes d'onboarding - 4 pages de présentation
  '/onboarding-1': (context) => const OnboardingScreen1(),
  '/onboarding-2': (context) => const OnboardingScreen2(),
  '/onboarding-3': (context) => const OnboardingScreen3(),
  '/onboarding-4': (context) => const OnboardingScreen4(),

  // Route principale - Accès à la boutique
  '/access-boutique': (context) => const AccessBoutiqueScreen(),

  // Route du scanner QR code
  '/qr-scanner': (context) => const QrScannerScreen(),

  // Routes de la boutique (home, produits, panier)
  '/home': (context) => const HomeScreen(),
  // Note: PanierScreen nécessite shopId, utilisez Navigator.push avec MaterialPageRoute

  // Routes des commandes
  // Note: CommandeScreen nécessite shopId, utilisez Navigator.push
  '/loading-success': (context) => const LoadingSuccessPage(),
  // Note: payment-confirmation, order-tracking, et orders-list nécessitent des paramètres
  // Utilisez Navigator.push avec MaterialPageRoute pour ces écrans

  // Routes des favoris et historique
  '/favorites': (context) => const FavoritesBoutiquesScreen(),
  '/history': (context) => const GlobalHistoryScreen(),

  // Routes de fidélité
  // Note: create-loyalty-card et loyalty-card nécessitent des paramètres
  // Utilisez Navigator.push avec MaterialPageRoute pour ces écrans

  // Route des notifications
  '/notifications': (context) => const NotificationsListScreen(),

  // Routes du profil
  '/profile': (context) => const ProfileScreen(),
  '/personal-info': (context) => const PersonalInfoScreen(),
  '/addresses': (context) => const AddressesScreen(),
  '/payment-methods': (context) => const PaymentMethodsScreen(),
  '/profile-notifications': (context) => const NotificationsScreen(),
  '/security': (context) => const SecurityScreen(),
  '/help-support': (context) => const HelpSupportScreen(),
};
