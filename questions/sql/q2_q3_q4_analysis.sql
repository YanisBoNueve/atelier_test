-- Q2 : Meilleure progression le premier mois (progression + TP corrigés)

WITH user_training AS (
  SELECT
    user_id,
    training_name,
    MIN(training_start_date) AS training_start_date
  FROM `raw.training_user_progress_snapshot`
  WHERE training_start_date IS NOT NULL
    AND training_start_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR)
  GROUP BY user_id, training_name
),

first_month_progress AS (
  SELECT
    ut.user_id,
    ut.training_name,
    MAX(ups.training_progress) AS max_progress_first_month
  FROM user_training AS ut
  JOIN `raw.training_user_progress_snapshot` AS ups
    ON ut.user_id = ups.user_id
   AND ut.training_name = ups.training_name
  WHERE ups.dbt_valid_from >= CAST(ut.training_start_date AS TIMESTAMP)
    AND ups.dbt_valid_from < TIMESTAMP_ADD(CAST(ut.training_start_date AS TIMESTAMP), INTERVAL 30 DAY)
  GROUP BY ut.user_id, ut.training_name
),

first_month_homeworks AS (
  SELECT
    ut.user_id,
    ut.training_name,
    COUNTIF(uhs.corrected_at IS NOT NULL) AS corrected_homeworks_first_month
  FROM user_training AS ut
  LEFT JOIN `raw.user_homework_submission` AS uhs
    ON uhs.user_id = ut.user_id
   AND uhs.submition_date >= CAST(ut.training_start_date AS TIMESTAMP)
   AND uhs.submition_date < TIMESTAMP_ADD(CAST(ut.training_start_date AS TIMESTAMP), INTERVAL 30 DAY)
  GROUP BY ut.user_id, ut.training_name
)

SELECT
  p.training_name,
  COUNT(DISTINCT p.user_id) AS learners,
  AVG(p.max_progress_first_month) AS avg_progress_first_month,
  AVG(IFNULL(h.corrected_homeworks_first_month, 0)) AS avg_corrected_homeworks_first_month
FROM first_month_progress AS p
LEFT JOIN first_month_homeworks AS h
  ON p.user_id = h.user_id
 AND p.training_name = h.training_name
GROUP BY p.training_name
HAVING learners >= 5
ORDER BY
  avg_progress_first_month DESC,
  avg_corrected_homeworks_first_month DESC;

/* 
Ligne	training_name	learners	avg_progress_first_month	avg_corrected_homeworks_first_month
1	CAP Fleuriste	495	0.13531313131313136	0.2464646464646465
2	CAP Monteur en Installations Thermiques (MIT)	318	0.12410094637223981	0.028301886792452845
3	CAP Métiers de la mode - Vêtement Flou	488	0.11151950718685832	0.29098360655737693	
C'est donc la formation de CAP Fleuriste, avec la meilleure progression moyenne, et avec 1/4
des apprenants qui ont au moins un tp corrigé sur le premier mois*/

-- Q3 : Formation avec les meilleurs résultats pédagogiques
-- (progression finale + travaux pratiques corrigés)

WITH user_training AS (
  SELECT
    user_id,
    training_name,
    MIN(training_start_date) AS training_start_date
  FROM `raw.training_user_progress_snapshot`
  WHERE training_start_date IS NOT NULL
    AND training_start_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR)
  GROUP BY user_id, training_name
),

user_final_progress AS (
  SELECT
    ut.user_id,
    ut.training_name,
    MAX(ups.training_progress) AS final_progress
  FROM user_training AS ut
  JOIN `raw.training_user_progress_snapshot` AS ups
    ON ut.user_id = ups.user_id
   AND ut.training_name = ups.training_name
  GROUP BY ut.user_id, ut.training_name
),

user_homeworks AS (
  SELECT
    ut.user_id,
    ut.training_name,
    COUNTIF(uhs.corrected_at IS NOT NULL) AS total_corrected_homeworks,
    AVG(uhs.homework_score) AS avg_homework_score
  FROM user_training AS ut
  LEFT JOIN `raw.user_homework_submission` AS uhs
    ON ut.user_id = uhs.user_id
   AND uhs.submition_date >= CAST(ut.training_start_date AS TIMESTAMP)
  GROUP BY ut.user_id, ut.training_name
),

user_pedagogy AS (
  SELECT
    fp.training_name,
    fp.user_id,
    fp.final_progress,
    IFNULL(uh.total_corrected_homeworks, 0) AS total_corrected_homeworks,
    uh.avg_homework_score
  FROM user_final_progress AS fp
  LEFT JOIN user_homeworks AS uh
    ON fp.user_id = uh.user_id
   AND fp.training_name = uh.training_name
)

SELECT
  training_name,
  COUNT(DISTINCT user_id) AS learners,
  AVG(final_progress) AS avg_final_progress,
  AVG(total_corrected_homeworks) AS avg_corrected_homeworks,
  AVG(avg_homework_score) AS avg_score
FROM user_pedagogy
GROUP BY training_name
HAVING learners >= 5
ORDER BY
  avg_final_progress DESC,          
  avg_corrected_homeworks DESC,     
  avg_score DESC                    
;
/* 
Ligne	training_name	learners	avg_final_progress	avg_corrected_homeworks	avg_score
1	CAP Fleuriste	497	0.3249698189134812	1.2837022132796763	89.403326663356566
2	CAP Monteur en Installations Thermiques (MIT)	321	0.23383177570093475	0.33021806853582519	95.775459136822789
3	CAP Métiers de la mode - Vêtement Flou	490	0.20483673469387748	0.78571428571428514	84.274910394265191
C'est donc une nouvelle fois le CAP Fleuriste, car c’est celle où les apprenants vont le plus loin en moyenne,
celle où il y a le plus de TP corrigés par apprenant, avec une note moyenne très élevée.
*/

-- Q4 : Marge par formation (CA reconnu selon avancement, coût correction 5€)

WITH user_training AS (
  SELECT
    user_id,
    training_name,
    MIN(training_start_date) AS training_start_date
  FROM `raw.training_user_progress_snapshot`
  WHERE training_start_date IS NOT NULL
    AND training_start_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR)
  GROUP BY user_id, training_name
),

user_final_progress AS (
  SELECT
    ut.user_id,
    ut.training_name,
    MAX(ups.training_progress) AS final_progress
  FROM user_training AS ut
  JOIN `raw.training_user_progress_snapshot` AS ups
    ON ut.user_id = ups.user_id
   AND ut.training_name = ups.training_name
  GROUP BY ut.user_id, ut.training_name
),

revenue_per_user AS (
  SELECT
    ts.user_id,
    ufp.training_name,
    ts.item_amount,
    IFNULL(ufp.final_progress, 0) AS final_progress,
    ts.item_amount * IFNULL(ufp.final_progress, 0) AS recognized_revenue
  FROM `raw.training_sales` AS ts
  LEFT JOIN user_final_progress AS ufp
    ON ts.user_id = ufp.user_id
),

homework_costs AS (
  SELECT
    ut.user_id,
    ut.training_name,
    COUNTIF(uhs.corrected_at IS NOT NULL) * 5 AS correction_cost
  FROM user_training AS ut
  LEFT JOIN `raw.user_homework_submission` AS uhs
    ON ut.user_id = uhs.user_id
   AND uhs.submition_date >= CAST(ut.training_start_date AS TIMESTAMP)
  GROUP BY ut.user_id, ut.training_name
)

SELECT
  r.training_name,
  SUM(r.recognized_revenue) AS recognized_revenue,
  SUM(IFNULL(h.correction_cost, 0)) AS correction_costs,
  SUM(r.recognized_revenue) - SUM(IFNULL(h.correction_cost, 0)) AS margin
FROM revenue_per_user AS r
LEFT JOIN homework_costs AS h
  ON r.user_id = h.user_id
 AND r.training_name = h.training_name
GROUP BY r.training_name
ORDER BY margin DESC;

/* 
Ligne	training_name	recognized_revenue	correction_costs	margin
1	CAP Fleuriste	310394.05740000005	3190	307204.05740000005
2	CAP Métiers de la mode - Vêtement Flou	192016.94000000018	1925	190091.94000000018
3	CAP Monteur en Installations Thermiques (MIT)	129113.62439999999	530	128583.62439999999
*/

/*
    Notes/Choix techniques pas explicités dans l'énoncé mais qui apportent une plus-value.

  - Fenêtre temporelle sur 2 ans :
    On limite l’analyse aux formations démarrées dans les 2 dernières années
    (training_start_date >= CURRENT_DATE - 2 ans) pour se concentrer sur les cohortes cohérentes, récentes
    et réduire le volume de données traité (je suis sur BigQuery donc je voulais limiter les ressources consommées
    pour le billing de mon essai gratuit).

  - Table d’ancrage user_training :
    On construit une CTE user_training (user_id, training_name) avec la première
    date de début de formation. Cette table sert de base à tous les calculs pour éviter
    les doublons liés à la table SCD2 training_user_progress_snapshot.

  - Calcul au grain (user, formation) avant agrégation :
    Toutes les métriques (progression finale, progression 1er mois, nombre de TP corrigés,
    score moyen, CA reconnu, coût des corrections) sont d’abord calculées par apprenant,
    puis agrégées par formation. Cela garantit l’absence de double comptage.

  - Filtrage des TP par la date de début :
    Les TP sont rattachés à une formation uniquement si leur date de soumission est
    postérieure à la date de début de formation, ce qui évite de compter des TP réalisés
    avant le début effectif du parcours.

  - Seuil minimum d’apprenants :
    On filtre les formations avec HAVING learners >= 5 afin d’éviter de conclure sur
    des formations avec très peu de données (résultats non représentatifs).

  - Gestion des valeurs manquantes :
    IFNULL() est utilisé pour considérer explicitement l’absence de progression ou de TP
    comme 0 (et non comme valeur manquante), ce qui permet de garder tous les apprenants
    dans les agrégations.

  - Classement multi-critères :
    Les formations sont classées en priorité sur la progression moyenne, puis sur le volume
    de TP corrigés et enfin sur le score moyen, ce qui reflète une bonne logique métier de
    combinaison des résultats pédagogiques.
*/
