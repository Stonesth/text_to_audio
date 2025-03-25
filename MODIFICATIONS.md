# Modifications apportées à Simple_TTS_GUI

Ce document détaille les modifications récentes apportées à l'application Simple_TTS_GUI pour améliorer l'expérience utilisateur en masquant les fonctionnalités qui ne sont pas encore pleinement opérationnelles.

## Options masquées dans l'interface

Certaines options ont été masquées dans l'interface utilisateur car elles ne fonctionnent pas correctement ou produisent des résultats de mauvaise qualité. Les fonctionnalités sont toujours présentes dans le code mais ne sont pas affichées aux utilisateurs pour éviter la confusion.

### Options masquées par langue

#### Anglais
- ❌ Glow-TTS (midel féminine)
- ❌ Speedy-Speech (midel féminine)
- ❌ Neural HMM (féminine)

#### Français
- ❌ VITS (bug)
- ❌ YourTTS (féminine)
- ❌ YourTTS (masculin)

#### Néerlandais
- ❌ YourTTS

### Sélecteur de genre pour XTTS

Le sélecteur de genre pour XTTS a également été masqué dans l'interface utilisateur, mais reste fonctionnel en arrière-plan. Cette modification a été réalisée car :

1. La sélection du genre n'avait pas d'impact perceptible sur la qualité ou le type de voix générée
2. L'option "Femme" est définie par défaut
3. L'élément reste présent dans le code pour une éventuelle amélioration future

## Détails techniques

### Filtrage des modèles

Le système utilise désormais un tableau d'objets avec des attributs `name` et `show` pour chaque modèle. Seuls les modèles avec `show: true` sont ajoutés à l'interface utilisateur, ce qui permet de conserver tous les modèles dans le code tout en filtrant leur affichage.

```python
# Exemple de la structure utilisée
models = [
    {"name": "XTTS v2 (Voix reference)", "show": True},
    {"name": "VITS (bug)", "show": False},  # Option masquée
]

# Affichage filtré
for model in models:
    if model["show"]:
        self.model_combo.addItem(model["name"])
```

### Masquage du sélecteur de genre

Le sélecteur de genre XTTS a été masqué via les méthodes `hide()` de Qt :

```python
# Masquer le sélecteur de genre (tout en le conservant fonctionnel)
self.xtts_gender_label.hide()
self.xtts_gender_combo.hide()
```

Cette approche permet de préserver toute la logique existante sans la modifier, tout en simplifiant l'interface utilisateur.

## Prochaines étapes

Ces modifications sont temporaires. Lorsque les modèles concernés seront améliorés ou que les problèmes seront résolus, il suffira de :

1. Changer les valeurs `show` de `False` à `True` pour les modèles concernés
2. Supprimer les lignes `hide()` pour le sélecteur de genre XTTS
