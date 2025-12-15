# Instructions pour ajouter le banner par défaut Black Friday

## ⚠️ IMPORTANT : Cette image est OBLIGATOIRE

L'application affichera **TOUJOURS** l'image par défaut. Le gradient violet a été complètement supprimé.

## Étape 1 : Sauvegarder l'image Black Friday

1. Sauvegardez l'image Black Friday (l'image avec le fond jaune et la personne assise) dans le dossier suivant :
   ```
   c:\src\Tika\tika_app\lib\core\assets\
   ```

2. Renommez l'image en : `default_banner.jpg`

   Le chemin complet devrait être :
   ```
   c:\src\Tika\tika_app\lib\core\assets\default_banner.jpg
   ```

## Étape 2 : Vérifier la configuration

Le fichier `pubspec.yaml` est déjà configuré pour charger les assets depuis `lib/core/assets/`.

## Étape 3 : Tester

1. Lancez l'application Flutter
2. Ouvrez n'importe quelle boutique
3. Vous verrez :
   - L'image Black Friday comme fond de base
   - Le banner de la boutique par-dessus SI l'API le fournit

## Comment ça fonctionne maintenant

Le code utilise une **stratégie de double couche** :

1. **Couche de base (toujours présente)** : Image Black Friday par défaut
2. **Couche supérieure (si disponible)** : Banner depuis l'API qui s'affiche par-dessus

### Avantages de cette approche

- ✅ Pas de gradient violet, toujours une belle image
- ✅ L'image par défaut se charge instantanément (asset local)
- ✅ Le banner de l'API s'affiche par-dessus quand il est disponible
- ✅ Si le banner de l'API échoue, l'image par défaut reste visible

## Format de l'image recommandé

- **Format** : JPG (comme l'image Black Friday)
- **Dimensions recommandées** : 1920x600 pixels (ratio 16:5)
- **Poids** : < 500 KB pour de meilleures performances

## Fichiers modifiés

- `lib/features/boutique/home/widgets/home_header.dart` : Widget qui affiche le banner avec l'image par défaut en arrière-plan
