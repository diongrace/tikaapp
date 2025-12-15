import '../models/boutique_config.dart';
import '../models/boutique_type.dart';

/// Registre de toutes les boutiques disponibles dans l'application
/// Ce fichier peut être remplacé par un appel API plus tard
class BoutiqueRegistry {
  static final BoutiqueRegistry _instance = BoutiqueRegistry._internal();

  factory BoutiqueRegistry() {
    return _instance;
  }

  BoutiqueRegistry._internal();

  /// Liste de toutes les boutiques configurées
  final List<BoutiqueConfig> _boutiques = [];

  /// Initialise le registre (vide - utilise maintenant l'API)
  void initialize() {
    _boutiques.clear();
    // Les boutiques sont maintenant chargées depuis l'API
    // Ce registre peut être utilisé pour mettre en cache les boutiques si nécessaire
  }

  /// Récupère toutes les boutiques
  List<BoutiqueConfig> getAllBoutiques() {
    if (_boutiques.isEmpty) {
      initialize();
    }
    return List.unmodifiable(_boutiques);
  }

  /// Récupère une boutique par son ID
  BoutiqueConfig? getBoutiqueById(String id) {
    if (_boutiques.isEmpty) {
      initialize();
    }
    try {
      return _boutiques.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Récupère une boutique par son QR code
  BoutiqueConfig? getBoutiqueByQrCode(String qrCodeData) {
    if (_boutiques.isEmpty) {
      initialize();
    }
    try {
      return _boutiques.firstWhere((b) => b.qrCodeData == qrCodeData);
    } catch (e) {
      return null;
    }
  }

  /// Récupère une boutique par son lien direct
  BoutiqueConfig? getBoutiqueByLink(String link) {
    if (_boutiques.isEmpty) {
      initialize();
    }
    try {
      return _boutiques.firstWhere(
        (b) => b.directLink != null && link.contains(b.directLink!),
      );
    } catch (e) {
      return null;
    }
  }

  /// Récupère les boutiques par type
  List<BoutiqueConfig> getBoutiquesByType(BoutiqueType type) {
    if (_boutiques.isEmpty) {
      initialize();
    }
    return _boutiques.where((b) => b.type == type).toList();
  }

  /// Ajoute une nouvelle boutique au registre
  void addBoutique(BoutiqueConfig config) {
    _boutiques.add(config);
  }

  /// Met à jour une boutique existante
  void updateBoutique(String id, BoutiqueConfig config) {
    final index = _boutiques.indexWhere((b) => b.id == id);
    if (index != -1) {
      _boutiques[index] = config;
    }
  }

  /// Supprime une boutique du registre
  void removeBoutique(String id) {
    _boutiques.removeWhere((b) => b.id == id);
  }
}
