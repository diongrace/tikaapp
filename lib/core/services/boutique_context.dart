import 'package:flutter/foundation.dart';
import '../models/boutique_config.dart';
import '../models/boutique_type.dart';

/// Service de gestion du contexte de la boutique active
/// Permet de savoir quelle boutique l'utilisateur consulte actuellement
class BoutiqueContext extends ChangeNotifier {
  static final BoutiqueContext _instance = BoutiqueContext._internal();

  factory BoutiqueContext() {
    return _instance;
  }

  BoutiqueContext._internal();

  /// Configuration de la boutique actuellement active
  BoutiqueConfig? _currentBoutique;

  /// Obtient la configuration de la boutique active
  BoutiqueConfig? get currentBoutique => _currentBoutique;

  /// Obtient le type de la boutique active
  BoutiqueType? get currentType => _currentBoutique?.type;

  /// Vérifie si une boutique est active
  bool get hasBoutique => _currentBoutique != null;

  /// Définit la boutique active
  /// Appelé après scan QR code ou clic sur un lien
  void setBoutique(BoutiqueConfig config) {
    _currentBoutique = config;
    notifyListeners();
  }

  /// Réinitialise le contexte (déconnexion de la boutique)
  void clearBoutique() {
    _currentBoutique = null;
    notifyListeners();
  }

  /// Vérifie si le type actuel correspond au type donné
  bool isType(BoutiqueType type) {
    return _currentBoutique?.type == type;
  }

  /// Obtient le label pour les articles selon le type de boutique
  String get itemLabel {
    return _currentBoutique?.type.itemLabel ?? 'Article';
  }

  /// Obtient le label pluriel pour les articles
  String get itemsLabel {
    return _currentBoutique?.type.itemsLabel ?? 'Articles';
  }

  /// Obtient le label du panier selon le type de boutique
  String get cartLabel {
    return _currentBoutique?.type.cartLabel ?? 'Panier';
  }

  /// Obtient le label du bouton d'ajout
  String get addButtonLabel {
    return _currentBoutique?.type.addButtonLabel ?? 'Ajouter';
  }

  /// Vérifie si le type actuel nécessite des rendez-vous
  bool get requiresAppointment {
    return _currentBoutique?.type.requiresAppointment ?? false;
  }

  /// Vérifie si le type actuel a un temps de préparation
  bool get hasPreparationTime {
    return _currentBoutique?.type.hasPreparationTime ?? false;
  }

  /// Vérifie si le type actuel a des préférences personnalisables
  bool get hasCustomPreferences {
    return _currentBoutique?.type.hasCustomPreferences ?? false;
  }
}
