# MMO AI Database API

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from db import get_connection
from ai_sql import generate_sql, explain_query

app = FastAPI()


class QueryRequest(BaseModel):
    query: str


class AskRequest(BaseModel):
    question: str


def is_safe_query(query: str):
    return query.strip().lower().startswith("select")


@app.get("/")
def root():
    return {"message": "MMO AI Database API is running"}


@app.post("/query")
def run_query(request: QueryRequest):
    query = request.query.strip()

    if not is_safe_query(query):
        raise HTTPException(status_code=400, detail="Unsafe query detected")

    conn = get_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Database connection failed")

    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(query)
        results = cursor.fetchall()
        return {"query": query, "results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()


@app.post("/ask")
def ask_ai(request: AskRequest):
    question = request.question.strip()
    sql_query = generate_sql(question)

    # Limit API results by default to prevent huge AI-generated queries.
    sql_query = sql_query.strip().rstrip(";")

    if "limit" not in sql_query.lower():
        sql_query += " LIMIT 50"

    sql_query += ";"

    if not is_safe_query(sql_query):
        raise HTTPException(status_code=400, detail="Unsafe query generated")

    conn = get_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Database connection failed")

    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(sql_query)
        results = cursor.fetchall()

        explanation = explain_query(question, sql_query)

        return {
            "query": sql_query,
            "explanation": explanation,
            "results": results
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()


@app.get("/characters")
def get_characters():
    conn = get_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Database connection failed")

    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM vw_character_overview")
        results = cursor.fetchall()
        return {"characters": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()


@app.get("/richest")
def richest_players():
    conn = get_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Database connection failed")

    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT * FROM vw_inventory_value
            ORDER BY total_inventory_value DESC
            LIMIT 10
        """)
        results = cursor.fetchall()
        return {"richest_players": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()


@app.get("/suspicious-transactions")
def suspicious_transactions():
    conn = get_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Database connection failed")

    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM vw_suspicious_large_currency_transfers")
        results = cursor.fetchall()
        return {"suspicious_transactions": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()