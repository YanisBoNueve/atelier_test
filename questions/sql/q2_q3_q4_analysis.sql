-- Q2 : Meilleure progression le premier mois (progression et TP corrigés)
WITH first_month_progress AS (
  SELECT
    ups.training_name,
    ups.user_id,
    MAX(ups.training_progress) AS max_progress_first_month
  FROM `projet.atelier.analytics.training_user_progress_snapshot` AS ups
  WHERE ups.training_start_date IS NOT NULL
    AND ups.training_start_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR)
    AND ups.dbt_valid_from < TIMESTAMP_ADD(CAST(ups.training_start_date AS TIMESTAMP), INTERVAL 30 DAY)
    AND (ups.dbt_valid_to IS NULL OR ups.dbt_valid_to <= TIMESTAMP_ADD(CAST(ups.training_start_date AS TIMESTAMP), INTERVAL 30 DAY))
  GROUP BY ups.training_name, ups.user_id
),
first_month_homeworks AS (
  SELECT
    uhs.user_id,
    ups.training_name,
    COUNTIF(uhs.corrected_at IS NOT NULL) AS corrected_homeworks_first_month
  FROM `projet.atelier.analytics.user_homework_submission` AS uhs
  JOIN `projet.atelier.analytics.training_user_progress_snapshot` AS ups
    ON uhs.user_id = ups.user_id
  WHERE ups.training_start_date IS NOT NULL
    AND uhs.submition_date < TIMESTAMP_ADD(CAST(ups.training_start_date AS TIMESTAMP), INTERVAL 30 DAY)
    AND ups.training_start_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR)
  GROUP BY uhs.user_id, ups.training_name
)
SELECT
  p.training_name,
  COUNT(DISTINCT p.user_id) AS learners,
  AVG(p.max_progress_first_month) AS avg_progress_first_month,
  AVG(IFNULL(h.corrected_homeworks_first_month, 0)) AS avg_corrected_homeworks_first_month
FROM first_month_progress AS p
LEFT JOIN first_month_homeworks AS h
  ON p.user_id = h.user_id AND p.training_name = h.training_name
GROUP BY p.training_name
HAVING learners >= 5
ORDER BY avg_progress_first_month DESC, avg_corrected_homeworks_first_month DESC
LIMIT 20
;

-- Q3 : Formation avec les meilleurs résultats pédagogiques (progression et travaux corrigés)
WITH user_pedagogy AS (
  SELECT
    ups.training_name,
    ups.user_id,
    MAX(ups.training_progress) AS final_progress,
    COUNTIF(uhs.corrected_at IS NOT NULL) AS total_corrected_homeworks,
    AVG(uhs.homework_score) AS avg_homework_score
  FROM `projet.atelier.analytics.training_user_progress_snapshot` AS ups
  LEFT JOIN `projet.atelier.analytics.user_homework_submission` AS uhs
    ON ups.user_id = uhs.user_id
  WHERE ups.training_start_date IS NOT NULL
    AND ups.training_start_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR)
  GROUP BY ups.training_name, ups.user_id
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
ORDER BY avg_final_progress DESC, avg_corrected_homeworks DESC, avg_score DESC
LIMIT 20
;

-- Q4 : Marge par formation (CA reconnu selon avancement, coût correction 5€)
WITH revenue_per_user AS (
  SELECT
    ts.user_id,
    ts.item_amount,
    ups.training_name,
    MAX(ups.training_progress) AS final_progress
  FROM `projet.atelier.analytics.training_sales` AS ts
  JOIN `projet.atelier.analytics.training_user_progress_snapshot` AS ups
    ON ts.user_id = ups.user_id
  WHERE ups.training_start_date IS NOT NULL
  GROUP BY ts.user_id, ts.item_amount, ups.training_name
),
homework_costs AS (
  SELECT
    ups.training_name,
    uhs.user_id,
    COUNTIF(uhs.corrected_at IS NOT NULL) * 5 AS correction_cost
  FROM `projet.atelier.analytics.user_homework_submission` AS uhs
  JOIN `projet.atelier.analytics.training_user_progress_snapshot` AS ups
    ON uhs.user_id = ups.user_id
  GROUP BY ups.training_name, uhs.user_id
)
SELECT
  r.training_name,
  SUM(r.item_amount * IFNULL(r.final_progress, 0)) AS recognized_revenue,
  SUM(IFNULL(h.correction_cost, 0)) AS correction_costs,
  SUM(r.item_amount * IFNULL(r.final_progress, 0)) - SUM(IFNULL(h.correction_cost, 0)) AS margin
FROM revenue_per_user AS r
LEFT JOIN homework_costs AS h
  ON r.user_id = h.user_id AND r.training_name = h.training_name
GROUP BY r.training_name
ORDER BY margin DESC
;
