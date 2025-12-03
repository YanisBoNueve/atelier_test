# ATELIER_TEST  
**Améliorer la performance de nos formations en ligne**

[![BigQuery](https://img.shields.io/badge/SQL-Google%20BigQuery-4285F4.svg)](https://cloud.google.com/bigquery)
[![Metabase](https://img.shields.io/badge/BI-Metabase-509EE3.svg)](https://www.metabase.com/)
[![VS Code](https://img.shields.io/badge/Éditeur-VS%20Code-007ACC.svg)](https://code.visualstudio.com/)

---

### Outils et technologies utilisés  
`SQL` • `Google BigQuery` • `Metabase` • `VS Code`

---

## Table des matières
- [Aperçu](#aperçu)
- [Prise en main](#prise-en-main)
- [Structure du projet](#structure-du-projet)
- [Utilisation](#utilisation)
- [Dashboards](#dashboards)
- [Résultats & insights](#résultats--insights)
- [Prochaines étapes](#prochaines-étapes)
- [Auteur](#auteur)

---

## Aperçu

**ATELIER_TEST** est un cas pratique de Data Analyst pour **L’Atelier des Chefs**, organisme de formation en ligne préparant notamment à des CAP (CAP Fleuriste, CAP Métiers de la mode, Vêtement flou, CAP Monteur en Installations Thermiques).

Le projet part de trois tables brutes pour construire des **indicateurs métier lisibles** autour de :

- la **performance commerciale** des formations (ventes, CA reconnu, marge),
- la **progression des apprenants** dans les parcours,
- l’**engagement pédagogique** (travaux pratiques soumis, corrigés, notés).

Les principales questions adressées sont :

1. **Quelle formation montre la meilleure progression au cours du premier mois**, en combinant avancement et travaux pratiques corrigés ?
2. **Quelle formation obtient les meilleurs résultats pédagogiques** en fin de parcours, en combinant progression finale, nombre de TP corrigés et scores ?
3. **Quelle est la marge par formation** si :
   - le chiffre d’affaires est reconnu proportionnellement à l’avancement de chaque apprenant,
   - et chaque correction de TP est valorisée à **5 €** ?

Le livrable final est un ensemble de **requêtes SQL BigQuery**, complété par des **dashboards Metabase** et une **présentation PowerPoint** orientée parties prenantes non techniques.

---

## Prise en main

### Prérequis

- Un projet **Google BigQuery** (ou équivalent) avec les tables chargées,
- Une instance **Metabase** connectée à la base de données (facultatif mais recommandé),
- Git + **VS Code** pour naviguer dans le dépôt.

### Données

Les fichiers CSV sont fournis dans le dépôt :

data/raw/training_sales.csv

data/raw/training_user_progress_snapshot.csv

data/raw/user_homework_submission.csv

Dans BigQuery, ils sont utilisés via les tables :

raw.training_sales

raw.training_user_progress_snapshot

raw.user_homework_submission

Les schémas détaillés sont documentés dans les fichiers YAML du dossier docs/.

## Structure du projet
<img width="791" height="609" alt="Capture d’écran 2025-12-03 à 18 24 44" src="https://github.com/user-attachments/assets/e94617e0-9c2a-4286-a953-fcadcdf1dfb8" />

### Utilisation
1. Exécuter les contrôles de qualité

Dans BigQuery, ouvrir questions/sql/data_quality_checks.sql et exécuter les requêtes pour :

vérifier les valeurs NULL critiques (progression, dates de correction, scores),

contrôler les plages de valeurs (training_progress dans [0,1], notes de TP dans [0,100]),

identifier les doublons éventuels et la cohérence des périodes SCD.

Ces checks permettent de sécuriser les analyses qui suivent.

2. Reproduire les analyses métier (Q2, Q3, Q4)

Le fichier questions/sql/q2_q3_q4_analysis.sql contient les requêtes prêtes à l’emploi pour :

Q2 – Meilleure progression le premier mois
→ calcul de la progression moyenne dans les 30 premiers jours + nombre de TP corrigés sur cette période.

Q3 – Meilleurs résultats pédagogiques
→ progression finale, nombre total de TP corrigés, note moyenne par apprenant, puis agrégation par formation.

Q4 – Marge par formation
→ CA reconnu = prix * progression finale, coût pédagogique = 5 € par TP corrigé, marge = CA reconnu – coût.

Ces requêtes servent de base pour alimenter les dashboards Metabase.

### Dashboards

Le dossier questions/dashboards/ contient des exports PDF des principaux tableaux de bord construits dans Metabase :

**Questions_Principales.pdf**

Meilleure progression le premier mois (progression + TP corrigés),

Formation avec les meilleurs résultats pédagogiques,

Marge par formation (CA reconnu vs coût de correction).

**Visualisations_exploration.pdf**

Évolution mensuelle des inscriptions et du CA,

Répartition des apprenants par niveau d’avancement,
etc

Les dashboards sont conçus pour des parties prenantes non techniques : titres métier, métriques lisibles, absence de jargon SQL.

### Résultats & insights

Quelques enseignements clés issus de l’analyse :

**CAP Fleuriste**

meilleure progression moyenne, dès le premier mois et en fin de parcours,

nombre de travaux pratiques corrigés par apprenant le plus élevé,

notes de TP solides (~89/100).
**C’est la formation la plus équilibrée pédagogiquement.**

**CAP Monteur en Installations Thermiques (MIT)**

progression correcte mais inférieure à Fleuriste,

très peu de TP corrigés par apprenant,

notes de TP très élevées (~96/100) pour ceux qui en rendent.
**Formation à fort potentiel, mais avec un risque de manque de feedback pour une partie des apprenants.**

**CAP Métiers de la mode – Vêtement flou**

progression moyenne la plus faible,

notes de TP plus basses (~84/100),

volume de TP corrigés intermédiaire.
**C’est la formation la plus fragile en termes d’expérience apprenant.**

**Sur le plan financier :**

Le CA reconnu est calculé de façon réaliste (proportionnelle à l’avancement réel),

Le coût de correction (5 € par TP corrigé) reste très faible par rapport au CA,

Les trois formations génèrent des marges élevées, proches du CA reconnu.

Conclusion business : le levier clé n’est pas de réduire le coût pédagogique, mais de mieux faire progresser les apprenants et de limiter le décrochage, en particulier sur les formations les plus fragiles.

### Prochaines étapes

Quelques pistes pour aller plus loin :

Mettre en place des analyses de cohortes (par mois d’inscription) pour mieux comprendre à quel moment les apprenants décrochent.

Étudier les trajectoires de progression dans le temps (stagnations, pics d’activité, arrêts nets) afin d’identifier précocement les profils à risque.

Analyser l’impact du feedback pédagogique : délais de correction des TP, volume de TP corrigés, niveau de note, et lien avec la poursuite ou non de la formation.

Construire un score de risque de décrochage pour prioriser les relances, le coaching et les actions pédagogiques.

Industrialiser les dashboards (Metabase / Power BI) et la boucle d’amélioration continue : mesurer l’impact des changements sur la progression et la complétion.

### Auteur

Yanis Boutouba — Data / Analytics Engineering
Projet réalisé dans le cadre du cas pratique Data Analyst @ L’Atelier des Chefs.
