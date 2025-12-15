import 'package:flutter/material.dart';
import '../../services/models/shop_model.dart';

/// Provider de thème dynamique pour la boutique
/// Utilise InheritedWidget pour propager les couleurs de la boutique
/// dans tout l'arbre de widgets
class BoutiqueThemeProvider extends InheritedWidget {
  final Shop? shop;
  final ShopTheme theme;

  BoutiqueThemeProvider({
    super.key,
    required this.shop,
    required super.child,
  }) : theme = shop?.theme ?? ShopTheme.defaultTheme();

  /// Obtient le thème de la boutique depuis le contexte
  /// Retourne le thème par défaut si non trouvé
  static ShopTheme of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<BoutiqueThemeProvider>();
    return provider?.theme ?? ShopTheme.defaultTheme();
  }

  /// Obtient le shop complet depuis le contexte (peut être null)
  static Shop? shopOf(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<BoutiqueThemeProvider>();
    return provider?.shop;
  }

  /// Vérifie si la boutique a une page de couverture
  static bool hasCoverPage(BuildContext context) {
    final shop = shopOf(context);
    return shop?.bannerUrl != null && shop!.bannerUrl!.isNotEmpty;
  }

  /// Obtient l'URL de la page de couverture (null si pas de couverture)
  static String? getCoverPageUrl(BuildContext context) {
    final shop = shopOf(context);
    return shop?.bannerUrl;
  }

  @override
  bool updateShouldNotify(BoutiqueThemeProvider oldWidget) {
    return shop?.id != oldWidget.shop?.id ||
        shop?.theme?.primaryColor != oldWidget.shop?.theme?.primaryColor;
  }
}

/// Extension pour accéder facilement au thème depuis BuildContext
extension BoutiqueThemeContext on BuildContext {
  /// Accès rapide au thème de la boutique
  ShopTheme get boutiqueTheme => BoutiqueThemeProvider.of(this);

  /// Accès rapide à la boutique
  Shop? get currentShop => BoutiqueThemeProvider.shopOf(this);

  /// Vérifie si une page de couverture existe
  bool get hasCoverPage => BoutiqueThemeProvider.hasCoverPage(this);

  /// URL de la page de couverture
  String? get coverPageUrl => BoutiqueThemeProvider.getCoverPageUrl(this);
}
