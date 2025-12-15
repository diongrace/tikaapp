# Corrections pour le problème d'affichage des images Banner - TIKA App

## 📋 Résumé du problème

Certaines boutiques avec des valeurs `bannerUrl` ne pouvaient pas afficher leurs images de couverture (banner). Les images des produits et logos avaient également le même problème.

---

## 🔍 Problèmes identifiés

### 1. **Permission Internet manquante** ❌
**Fichier**: `android/app/src/main/AndroidManifest.xml`

**Problème**: L'application n'avait pas la permission INTERNET dans le manifest Android, ce qui empêchait le chargement de toutes les images depuis l'API.

**Solution**: Ajout de la permission INTERNET
```xml
<!-- Permission pour accéder à Internet (requis pour charger les images depuis l'API) -->
<uses-permission android:name="android.permission.INTERNET"/>
```

### 2. **URLs relatives non gérées** ❌
**Fichiers concernés**:
- `lib/features/boutique/home/widgets/home_header.dart`
- `lib/features/boutique/home/widgets/product_card.dart`
- `lib/features/boutique/home/widgets/boutique_info_card.dart`

**Problème**: L'API peut retourner des URLs relatives (ex: `/storage/banners/image.jpg`) au lieu d'URLs complètes (ex: `https://tika-ci.com/storage/banners/image.jpg`). Le widget `Image.network()` ne peut pas charger des URLs relatives.

**Solution**: Ajout d'une méthode helper `_getFullImageUrl()` dans chaque widget pour:
1. Détecter si l'URL est déjà complète (commence par `http://` ou `https://`)
2. Si non, construire l'URL complète en ajoutant le domaine de base `https://tika-ci.com/`

---

## ✅ Corrections appliquées

### 1. AndroidManifest.xml

**Ligne 7-8** (nouvelle)
```xml
<!-- Permission pour accéder à Internet (requis pour charger les images depuis l'API) -->
<uses-permission android:name="android.permission.INTERNET"/>
```

### 2. home_header.dart (Image de couverture/banner)

**Ajout de la méthode `_getFullImageUrl()`** (lignes 19-32)
```dart
// Construire l'URL complète de l'image
String? _getFullImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;

  // Si l'URL commence déjà par http, la retourner telle quelle
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }

  // Sinon, construire l'URL complète avec le domaine de base
  // Nettoyer l'URL (enlever le slash de début si présent)
  final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
  return 'https://tika-ci.com/$cleanUrl';
}
```

**Utilisation dans le build()** (lignes 36-37, 51, 60, 85)
```dart
@override
Widget build(BuildContext context) {
  // Obtenir l'URL complète
  final fullBannerUrl = _getFullImageUrl(bannerUrl);

  // Debug: Afficher l'URL du banner
  if (bannerUrl != null) {
    print('🖼️ Banner URL original: $bannerUrl');
    print('🖼️ Banner URL complet: $fullBannerUrl');
  }

  return Stack(
    children: [
      // Image de fond - Utiliser fullBannerUrl au lieu de bannerUrl
      if (fullBannerUrl != null && fullBannerUrl.isNotEmpty)
        Padding(
          child: ClipRRect(
            child: Container(
              child: Image.network(
                fullBannerUrl,  // ✅ Utilise l'URL complète
                ...
              ),
            ),
          ),
        ),
      ...
    ],
  );
}
```

### 3. product_card.dart (Images des produits)

**Ajout de la méthode `_getFullImageUrl()`** (lignes 15-27)
```dart
// Construire l'URL complète de l'image
String? _getFullImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;

  // Si l'URL commence déjà par http, la retourner telle quelle
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }

  // Sinon, construire l'URL complète avec le domaine de base
  final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
  return 'https://tika-ci.com/$cleanUrl';
}
```

**Utilisation dans le build()** (ligne 32, 56-58)
```dart
@override
Widget build(BuildContext context) {
  final bool isOutOfStock = product['stock'] == 0;
  final String? fullImageUrl = _getFullImageUrl(product['image']?.toString());

  return GestureDetector(
    child: Container(
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                child: fullImageUrl != null
                  ? Image.network(
                      fullImageUrl,  // ✅ Utilise l'URL complète
                      ...
                    )
                  : Container(/* placeholder */),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
```

### 4. boutique_info_card.dart (Logo de la boutique)

**Ajout de la méthode `_getFullImageUrl()`** (lignes 25-37)
```dart
// Construire l'URL complète de l'image
String? _getFullImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;

  // Si l'URL commence déjà par http, la retourner telle quelle
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }

  // Sinon, construire l'URL complète avec le domaine de base
  final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
  return 'https://tika-ci.com/$cleanUrl';
}
```

**Utilisation dans le build()** (ligne 41, 70-72)
```dart
@override
Widget build(BuildContext context) {
  final String? fullLogoUrl = _getFullImageUrl(boutiqueLogoPath);

  return Container(
    child: Column(
      children: [
        Row(
          children: [
            Container(
              child: ClipRRect(
                child: fullLogoUrl != null
                  ? Image.network(
                      fullLogoUrl,  // ✅ Utilise l'URL complète
                      ...
                    )
                  : Container(/* placeholder icon */),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
```

---

## 🎯 Résultat attendu

### Avant ❌
- Images de banner ne s'affichaient pas pour certaines boutiques
- Images de produits pouvaient ne pas s'afficher
- Logos de boutiques pouvaient ne pas s'afficher
- Pas de permission Internet dans le manifest

### Après ✅
- **Permission INTERNET ajoutée** → Permet le chargement de toutes les images réseau
- **URLs relatives gérées** → Toutes les URLs sont converties en URLs complètes
- **Images banner affichées correctement** pour toutes les boutiques
- **Images produits affichées correctement** depuis l'API
- **Logos boutiques affichés correctement** depuis l'API

---

## 📊 Types d'URLs gérées

### URLs déjà complètes (passent directement)
```
https://tika-ci.com/storage/shops/banners/image.jpg ✅
http://example.com/image.png ✅
```

### URLs relatives (converties automatiquement)
```
/storage/shops/banners/image.jpg
  → https://tika-ci.com/storage/shops/banners/image.jpg ✅

storage/shops/banners/image.jpg
  → https://tika-ci.com/storage/shops/banners/image.jpg ✅
```

---

## 🔧 Pour tester les corrections

1. **Arrêter l'application Flutter actuelle**
   ```bash
   q  # dans le terminal Flutter
   ```

2. **Reconstruire et relancer l'application** (requis pour AndroidManifest.xml)
   ```bash
   flutter run
   ```

3. **Tester avec différentes boutiques**
   - Boutiques avec bannerUrl complets (URLs HTTPS)
   - Boutiques avec bannerUrl relatifs (URLs commençant par `/`)
   - Boutiques sans bannerUrl (ne doit rien afficher)

4. **Vérifier les logs de debug**
   - Chercher les logs avec emoji 🖼️
   - Vérifier que les URLs originales et complètes sont affichées
   - Vérifier les messages de succès ✅ ou d'erreur ❌

---

## 📝 Notes importantes

1. **AndroidManifest.xml doit être rebuild** - Un simple hot reload ne suffit pas pour les changements de manifest
2. **Les URLs relatives sont automatiquement converties** - Pas besoin de modification côté API
3. **Compatibilité totale** - Les URLs complètes fonctionnent toujours comme avant
4. **Debug logs conservés** - Pour identifier rapidement les problèmes futurs

---

## 🆘 Dépannage

### Si les images ne s'affichent toujours pas:

1. **Vérifier les logs de debug**
   ```
   🖼️ Banner URL original: /storage/...
   🖼️ Banner URL complet: https://tika-ci.com/storage/...
   ```

2. **Vérifier la permission Internet**
   ```bash
   # Chercher dans AndroidManifest.xml
   grep "INTERNET" android/app/src/main/AndroidManifest.xml
   ```

3. **Vérifier l'URL construite**
   - L'URL doit commencer par `https://tika-ci.com/`
   - Pas de double slashes (`//`) dans le chemin

4. **Tester l'URL directement dans un navigateur**
   - Copier l'URL complète depuis les logs
   - Ouvrir dans un navigateur pour vérifier qu'elle fonctionne

---

## ✅ Corrections supplémentaires (selon besoins spécifiques)

### PAS de fallback banner → logo
**Important**: Le logo n'est PAS une page de couverture. L'API gère cela séparément.

**Application dans home_online_screen.dart:305**
```dart
HomeHeader(
  bannerUrl: _currentShop?.bannerUrl,  // PAS de fallback sur logo
  ...
)
```

**Comportement**:
- Si la boutique a un `banner_url` → affiche le banner
- Si pas de `banner_url` → **n'affiche RIEN** (pas de fallback sur le logo)
- Le logo reste affiché dans la carte d'informations boutique uniquement

### Fix: Images produits vides
**Problème**: `'image': p.primaryImageUrl ?? ''` créait des strings vides qui causaient des erreurs AssetImage

**Solution (home_online_screen.dart:283)**:
```dart
'image': p.primaryImageUrl,  // Laisse null au lieu de ''
```

Le ProductCard gère correctement les valeurs null avec son helper `_getFullImageUrl()`.

---

**Date de mise à jour**: 19 novembre 2025
**Version**: 1.3
**Statut**: ✅ Corrections appliquées selon documentation API
