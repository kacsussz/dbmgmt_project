import os
from anthropic import Anthropic
from dotenv import load_dotenv

load_dotenv()

client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

# AI schema context
SCHEMA_CONTEXT = """
You generate safe MySQL SELECT queries for an MMO game operations database.

STRICT RULES:
- Only generate SELECT queries.
- Never generate INSERT, UPDATE, DELETE, DROP, ALTER, CREATE, TRUNCATE, or CALL.
- Prefer querying views instead of raw tables.
- Use exact column names only.
- Do not invent columns.
- Add LIMIT 50 unless the question clearly asks for fewer rows.
- Return only SQL. No markdown. No explanation.

MAIN ANALYTICS VIEWS:

vw_character_overview
Columns:
char_id, character_name, account_email, class_name, level, current_exp, exp_required_for_current_level

vw_inventory_value
Columns:
char_id, character_name, total_inventory_value

vw_currency_balances
Columns:
char_id, character_name, currency_name, is_tradable, balance

vw_transaction_summary
Columns:
trans_id, sender_character, receiver_character, transaction_type, timestamp, total_currency_amount, total_item_quantity

vw_suspicious_large_currency_transfers
Columns:
trans_id, sender_character, receiver_character, currency_name, amount, transaction_type, timestamp

vw_suspicious_login_activity
Columns:
user_id, email, different_ip_count, login_count, first_seen, last_seen

vw_monster_drop_rules
Columns:
monster_name, monster_level, item_name, rarity, quantity, drop_rate
"""

def generate_sql(question: str) -> str:
    response = client.messages.create(
        model="claude-haiku-4-5",
        max_tokens=300,
        messages=[
            {
                "role": "user",
                "content": f"{SCHEMA_CONTEXT}\n\nQuestion: {question}"
            }
        ]
    )

    return response.content[0].text.strip().replace("```sql", "").replace("```", "").strip()


def explain_query(question: str, sql: str) -> str:
    response = client.messages.create(
        model="claude-haiku-4-5",
        max_tokens=150,
        messages=[
            {
                "role": "user",
                "content": f"""
Explain in simple terms what this SQL query does.

Question: {question}
SQL: {sql}

Keep it short and human-friendly.
"""
            }
        ]
    )

    return response.content[0].text.strip()