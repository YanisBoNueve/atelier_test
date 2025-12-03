-- DQ1 : Profilage global des 3 tables (nb de lignes)
SELECT 'training_sales' AS table_name, COUNT(*) AS row_count
FROM `raw.training_sales`
UNION ALL
SELECT 'training_user_progress_snapshot', COUNT(*)
FROM `raw.training_user_progress_snapshot`
UNION ALL
SELECT 'user_homework_submission', COUNT(*)
FROM `raw.user_homework_submission`
;

-- DQ2 : Nullité et distribution des colonnes clés
SELECT
  'training_sales' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT user_id) AS distinct_users,
  COUNTIF(item_amount IS NULL) AS null_item_amount
FROM `raw.training_sales`
UNION ALL
SELECT
  'training_user_progress_snapshot',
  COUNT(*),
  COUNT(DISTINCT user_id),
  COUNTIF(training_progress IS NULL)
FROM `raw.training_user_progress_snapshot`
UNION ALL
SELECT
  'user_homework_submission',
  COUNT(*),
  COUNT(DISTINCT user_id),
  COUNTIF(homework_score IS NULL)
FROM `raw.user_homework_submission`
;

-- DQ3 : Unicité des identifiants principaux (si présents)
SELECT
  COUNT(*) AS row_count,
  COUNT(DISTINCT sale_id) AS distinct_sale_ids
FROM `raw.training_sales`
;

SELECT
  COUNT(*) AS row_count,
  COUNT(DISTINCT snapshot_id) AS distinct_snapshot_ids
FROM `raw.training_user_progress_snapshot`
;

SELECT
  COUNT(*) AS row_count,
  COUNT(DISTINCT submission_id) AS distinct_submission_ids
FROM `raw.user_homework_submission`
;

-- DQ4 : NULL vs 0 sur training_progress
SELECT
  COUNTIF(training_progress IS NULL) AS nb_null_progress,
  COUNTIF(training_progress = 0) AS nb_zero_progress,
  COUNTIF(training_progress BETWEEN 0 AND 1) AS nb_between_0_1,
  COUNTIF(training_progress < 0 OR training_progress > 1) AS nb_out_of_range
FROM `raw.training_user_progress_snapshot`
;

-- DQ5 : Cohérence SCD (doublons actifs)
SELECT
  user_id,
  training_name,
  training_start_date,
  COUNTIF(dbt_valid_to IS NULL) AS active_versions
FROM `raw.training_user_progress_snapshot`
GROUP BY user_id, training_name, training_start_date
HAVING active_versions > 1
ORDER BY active_versions DESC
LIMIT 50
;

-- DQ6 : Evolution de la progression (régressions ou stagnations longues)
WITH ordered_snapshots AS (
  SELECT
    user_id,
    training_name,
    training_start_date,
    dbt_valid_from,
    training_progress,
    LAG(training_progress) OVER(PARTITION BY user_id, training_name, training_start_date ORDER BY dbt_valid_from) AS prev_progress
  FROM `raw.training_user_progress_snapshot`
)
SELECT
  COUNTIF(training_progress < prev_progress) AS regressions,
  COUNTIF(training_progress = prev_progress) AS stagnations
FROM ordered_snapshots
;

-- DQ7 : Scores de devoirs aberrants ou non corrigés
SELECT
  COUNT(*) AS total_submissions,
  COUNTIF(homework_score IS NULL) AS null_scores,
  COUNTIF(homework_score < 0 OR homework_score > 100) AS out_of_range_scores,
  COUNTIF(corrected_at IS NULL) AS not_corrected
FROM `raw.user_homework_submission`
;

-- DQ8 : Délai de correction des devoirs
SELECT
  APPROX_QUANTILES(TIMESTAMP_DIFF(corrected_at, submition_date, DAY), [0, 0.5, 0.9, 0.95, 1]) AS correction_delay_days_quantiles
FROM `raw.user_homework_submission`
WHERE corrected_at IS NOT NULL
;

-- DQ9 : Ventes sans progression ou progression sans vente
SELECT
  COUNT(DISTINCT ts.user_id) AS sales_without_progress
FROM `raw.training_sales` AS ts
LEFT JOIN `raw.training_user_progress_snapshot` AS ups
  ON ts.user_id = ups.user_id
WHERE ups.user_id IS NULL
;

SELECT
  COUNT(DISTINCT ups.user_id) AS progress_without_sales
FROM `raw.training_user_progress_snapshot` AS ups
LEFT JOIN `raw.training_sales` AS ts
  ON ts.user_id = ups.user_id
WHERE ts.user_id IS NULL
;

-- DQ10 : Ventilation des progressions par formation
SELECT
  training_name,
  COUNT(*) AS snapshots,
  AVG(training_progress) AS avg_progress,
  COUNTIF(training_progress IS NULL) AS null_progress
FROM `raw.training_user_progress_snapshot`
GROUP BY training_name
ORDER BY snapshots DESC
LIMIT 50
;
