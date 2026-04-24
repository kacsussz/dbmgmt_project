import os
from pathlib import Path
from urllib.parse import urlparse

import mysql.connector
from mysql.connector import Error
from dotenv import load_dotenv

env_path = Path(__file__).resolve().parent / ".env"
load_dotenv(dotenv_path=env_path)


def get_connection():
    try:
        db_url = os.getenv("MYSQL_PUBLIC_URL")

        if not db_url:
            print("MYSQL_PUBLIC_URL is missing from .env")
            return None

        parsed = urlparse(db_url)

        connection = mysql.connector.connect(
            host=parsed.hostname,
            user=parsed.username,
            password=parsed.password,
            database=parsed.path.lstrip("/"),
            port=parsed.port or 3306,
        )

        return connection

    except Error as e:
        print("Database connection error:", e)
        return None