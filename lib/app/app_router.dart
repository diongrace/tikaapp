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
// Auth screens
import '../features/auth/auth_choice_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/forgot_password_screen.dart';

/// Noms des routes de l'application
class RouteNames {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String onboarding1 = '/onboarding-1';
  static const String onboarding2 = '/onboarding-2';
  static const String onboarding3 = '/onboarding-3';
  static const String onboarding4 = '/onboarding-4';
  static const String accessBoutique = '/access-boutique';
  static const String qrScanner = '/qr-scanner';
  static const String home = '/home';
  static const String loadingSuccess = '/loading-success';
  static const String favorites = '/favorites';
  static const String history = '/history';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String personalInfo = '/personal-info';
  static const String addresses = '/addresses';
  static const String paymentMethods = '/payment-methods';
  static const String profileNotifications = '/profile-notifications';
  static const String security = '/security';
  static const String helpSupport = '/help-support';
  // Routes d'authentification
  static const String authChoice = '/auth';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
}

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
  
  // Routes des favoris et historique
  '/favorites': (context) => const FavoritesBoutiquesScreen(),
  '/history': (context) => const GlobalHistoryScreen(),

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
  // Routes d'authentification
  '/auth': (context) => const AuthChoiceScreen(),
  '/auth/login': (context) => const LoginScreen(),
  '/auth/register': (context) => const RegisterScreen(),
  '/auth/forgot-password': (context) => const ForgotPasswordScreen(),
};

/// Fonction de génération de routes
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  final builder = appRoutes[settings.name];
  if (builder != null) {
    return MaterialPageRoute(
      builder: builder,
      settings: settings,
    );
  }
  return null;
}
