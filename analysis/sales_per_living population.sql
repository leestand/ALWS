-- 2024년 12월 생활인구 합계
WITH population_monthly AS (
  SELECT
    행정동코드 AS region_code,
    TO_CHAR(TO_DATE(기준일ID, 'YYYYMMDD'), 'YYYYMM') AS year_month,
    SUM(총생활인구수) AS total_population
  FROM LOCAL_POPULATION
  WHERE
    SUBSTR(행정동코드, 1, 5) = '11215'  -- 광진구
    AND TO_CHAR(TO_DATE(기준일ID, 'YYYYMMDD'), 'YYYYMM') = '202412'
  GROUP BY
    행정동코드,
    TO_CHAR(TO_DATE(기준일ID, 'YYYYMMDD'), 'YYYYMM')
),

-- 외식업 관련 업종의 2024년 4분기 매출 합계
sales_q4 AS (
  SELECT
    행정동_코드 AS region_code,
    행정동_코드_명 AS region_name,
    기준_년분기_코드 AS standard_year_quarter_code,
    SUM(당월_매출_금액) AS total_sales_q4
  FROM SALES_DATA
  WHERE
    기준_년분기_코드 = 20244
    AND SUBSTR(행정동_코드, 1, 5) = '11215'
    AND 서비스_업종_코드_명 IN (
      '한식음식점', '일식음식점', '중식음식점', '양식음식점',
      '분식전문점', '치킨전문점', '제과점', '커피-음료',
      '패스트푸드점', '호프-간이주점'
    )
  GROUP BY
    행정동_코드, 행정동_코드_명, 기준_년분기_코드
),

-- 매출 및 인구 매핑
per_sales AS (
  SELECT
    s.region_code,
    s.region_name,
    s.standard_year_quarter_code,
    p.year_month,
    p.total_population,
    ROUND(s.total_sales_q4 / 3, 2) AS estimated_monthly_sales,
    ROUND((s.total_sales_q4 / 3) / NULLIF(p.total_population, 0), 4) AS sales_per_population
  FROM
    sales_q4 s
  JOIN
    population_monthly p ON s.region_code = p.region_code
),

-- 평균 및 표준편차 계산
mean AS (
  SELECT
    AVG(sales_per_population) AS avg_sales,
    STDDEV(sales_per_population) AS std_sales
  FROM per_sales
)

-- 최종 결과 (2024년 12월만)
SELECT
  p.region_code,
  p.region_name,
  p.year_month,
  p.total_population,
  p.estimated_monthly_sales,
  p.sales_per_population,
  ROUND((p.sales_per_population - m.avg_sales) / NULLIF(m.std_sales, 0), 2) AS z_score
FROM per_sales p
CROSS JOIN mean m
WHERE p.year_month = '202412'
ORDER BY p.region_name DESC;
