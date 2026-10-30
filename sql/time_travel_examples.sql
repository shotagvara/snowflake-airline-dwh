-- DDL 1: историческая копия DIM_DATE, состояние пять минут назад
CREATE OR REPLACE TABLE AIRLINE_DWH.AUDIT.DIM_DATE_TT_CLONE
    CLONE AIRLINE_DWH.MART.DIM_DATE
    AT (OFFSET => -60*5);


-- DDL 2: создать таблицу из исторических данных DIM_DATE
CREATE OR REPLACE TABLE AIRLINE_DWH.AUDIT.DIM_DATE_TT_ASOF AS
SELECT *
FROM AIRLINE_DWH.MART.DIM_DATE
    AT (OFFSET => -60*5);

"""
Первое это zero-copy cloning: в момент создания клон изначально разделяет хранилище с исходной таблицей.
А второе это отдельная таблица 
"""

-- DML 1: удалить дату из тестовой копии, сверяясь с исторической версией
DELETE FROM AIRLINE_DWH.AUDIT.DIM_DATE_TT_ASOF
WHERE DEPARTURE_DATE IN (
    SELECT DEPARTURE_DATE
    FROM AIRLINE_DWH.MART.DIM_DATE
        AT (OFFSET => -60*5)
    WHERE DEPARTURE_DATE = '2022-01-01'::DATE
);

-- DML 2: восстановить удалённую дату из исторической версии
INSERT INTO AIRLINE_DWH.AUDIT.DIM_DATE_TT_ASOF
SELECT historical.*
FROM AIRLINE_DWH.MART.DIM_DATE
    AT (OFFSET => -60*5) AS historical
WHERE historical.DEPARTURE_DATE = '2022-01-01'::DATE
  AND NOT EXISTS (
      SELECT 1
      FROM AIRLINE_DWH.AUDIT.DIM_DATE_TT_ASOF AS target
      WHERE target.DEPARTURE_DATE = historical.DEPARTURE_DATE
  );