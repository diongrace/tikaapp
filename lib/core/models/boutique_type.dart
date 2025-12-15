/// Types de boutiques disponibles dans l'application Tika
enum BoutiqueType {
  /// Boutique en ligne - Vente de produits physiques
  boutiqueEnLigne,

  /// Restaurant - Plats et boissons avec temps de préparation
  restaurant,

  /// Salon de beauté - Services de beauté et soins esthétiques
  salonBeaute,

  /// Salon de coiffure - Coupes, coiffures et soins capillaires
  salonCoiffure,

  /// Midi express - Repas rapides et commandes express
  midiExpress,
}

/// Extension pour obtenir des informations sur chaque type de boutique
extension BoutiqueTypeExtension on BoutiqueType {
  /// Nom d'affichage du type de boutique
  String get displayName {
    switch (this) {
      case BoutiqueType.boutiqueEnLigne:
        return 'Boutique en ligne';
      case BoutiqueType.restaurant:
        return 'Restaurant';
      case BoutiqueType.salonBeaute:
        return 'Salon de beauté';
      case BoutiqueType.salonCoiffure:
        return 'Salon de coiffure';
      case BoutiqueType.midiExpress:
        return 'Midi Express';
    }
  }

  /// Identifiant unique du type de boutique
  String get id {
    switch (this) {
      case BoutiqueType.boutiqueEnLigne:
        return 'boutique_en_ligne';
      case BoutiqueType.restaurant:
        return 'restaurant';
      case BoutiqueType.salonBeaute:
        return 'salon_beaute';
      case BoutiqueType.salonCoiffure:
        return 'salon_coiffure';
      case BoutiqueType.midiExpress:
        return 'midi_express';
    }
  }

  /// Icône associée au type de boutique
  String get icon {
    switch (this) {
      case BoutiqueType.boutiqueEnLigne:
        return '🛍️';
      case BoutiqueType.restaurant:
        return '🍽️';
      case BoutiqueType.salonBeaute:
        return '💅';
      case BoutiqueType.salonCoiffure:
        return '✂️';
      case BoutiqueType.midiExpress:
        return '⚡';
    }
  }

  /// Détermine si ce type de boutique nécessite des rendez-vous
  bool get requiresAppointment {
    switch (this) {
      case BoutiqueType.salonBeaute:
      case BoutiqueType.salonCoiffure:
        return true;
      case BoutiqueType.boutiqueEnLigne:
      case BoutiqueType.restaurant:
      case BoutiqueType.midiExpress:
        return false;
    }
  }

  /// Détermine si ce type de boutique a un temps de préparation
  bool get hasPreparationTime {
    switch (this) {
      case BoutiqueType.restaurant:
      case BoutiqueType.midiExpress:
        return true;
      case BoutiqueType.boutiqueEnLigne:
      case BoutiqueType.salonBeaute:
      case BoutiqueType.salonCoiffure:
        return false;
    }
  }

  /// Détermine si ce type de boutique a des préférences personnalisables
  bool get hasCustomPreferences {
    switch (this) {
      case BoutiqueType.restaurant:
      case BoutiqueType.midiExpress:
        return true; // Épicé, non épicé, allergies, etc.
      case BoutiqueType.boutiqueEnLigne:
      case BoutiqueType.salonBeaute:
      case BoutiqueType.salonCoiffure:
        return false;
    }
  }

  /// Label pour les articles/produits (produit, plat, service)
  String get itemLabel {
    switch (this) {
      case BoutiqueType.boutiqueEnLigne:
        return 'Produit';
      case BoutiqueType.restaurant:
      case BoutiqueType.midiExpress:
        return 'Plat';
      case BoutiqueType.salonBeaute:
      case BoutiqueType.salonCoiffure:
        return 'Service';
    }
  }

  /// Label pluriel pour les articles/produits
  String get itemsLabel {
    switch (this) {
      case BoutiqueType.boutiqueEnLigne:
        return 'Produits';
      case BoutiqueType.restaurant:
      case BoutiqueType.midiExpress:
        return 'Plats';
      case BoutiqueType.salonBeaute:
      case BoutiqueType.salonCoiffure:
        return 'Services';
    }
  }

  /// Label pour le panier (Panier, Commande)
  String get cartLabel {
    switch (this) {
      case BoutiqueType.boutiqueEnLigne:
        return 'Panier';
      case BoutiqueType.restaurant:
      case BoutiqueType.midiExpress:
        return 'Ma commande';
      case BoutiqueType.salonBeaute:
      case BoutiqueType.salonCoiffure:
        return 'Mes rendez-vous';
    }
  }

  /// Label pour le bouton d'ajout
  String get addButtonLabel {
    switch (this) {
      case BoutiqueType.boutiqueEnLigne:
        return 'Ajouter au panier';
      case BoutiqueType.restaurant:
      case BoutiqueType.midiExpress:
        return 'Ajouter au panier';
      case BoutiqueType.salonBeaute:
      case BoutiqueType.salonCoiffure:
        return 'Réserver';
    }
  }
}
