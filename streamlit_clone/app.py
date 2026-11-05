import re

import snowflake.connector
import streamlit as st


st.set_page_config(page_title="Snowflake DB Clone", page_icon="❄")
st.title("Клонирование базы Snowflake")

clone_name = st.text_input(
    "Название клона",
    value="AIRLINE_DWH_DEV_CLONE_APP",
)

if st.button("Создать клон"):
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]{0,254}", clone_name):
        st.error("Используй английские буквы, цифры и _, начиная с буквы.")
        st.stop()

    connection = None
    cursor = None

    try:
        connection = snowflake.connector.connect(
            **dict(st.secrets["snowflake"])
        )
        cursor = connection.cursor()

        statements = [
            f"CREATE OR REPLACE DATABASE {clone_name} CLONE AIRLINE_DWH",

            f"GRANT USAGE ON DATABASE {clone_name} "
            "TO ROLE AIRLINE_US_ANALYST",

            f"GRANT USAGE ON SCHEMA {clone_name}.MART "
            "TO ROLE AIRLINE_US_ANALYST",

            f"GRANT SELECT ON VIEW "
            f"{clone_name}.MART.VW_FACT_AIRLINE_TRAVEL_SECURE "
            "TO ROLE AIRLINE_US_ANALYST",

            f"GRANT OWNERSHIP ON DATABASE {clone_name} "
            "TO ROLE AIRLINE_DWH_DEV COPY CURRENT GRANTS",

            f"GRANT OWNERSHIP ON ALL SCHEMAS IN DATABASE {clone_name} "
            "TO ROLE AIRLINE_DWH_DEV COPY CURRENT GRANTS",

            f"GRANT OWNERSHIP ON ALL TABLES IN DATABASE {clone_name} "
            "TO ROLE AIRLINE_DWH_DEV COPY CURRENT GRANTS",

            f"GRANT OWNERSHIP ON ALL VIEWS IN DATABASE {clone_name} "
            "TO ROLE AIRLINE_DWH_DEV COPY CURRENT GRANTS",

            f"GRANT OWNERSHIP ON ROW ACCESS POLICY "
            f"{clone_name}.MART.AIRLINE_COUNTRY_RAP "
            "TO ROLE AIRLINE_DWH_DEV COPY CURRENT GRANTS",
        ]

        for statement in statements:
            cursor.execute(statement)

        st.success(f"Клон {clone_name} создан, права назначены.")

    except Exception as error:
        st.error(f"Snowflake вернул ошибку: {error}")

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()