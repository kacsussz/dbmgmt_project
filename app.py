# Streamlit app

import requests
import streamlit as st
import pandas as pd

API_URL = "http://127.0.0.1:8000"

st.set_page_config(
    page_title="MMO AI Database Assistant",
    page_icon="🎮",
    layout="wide"
)

st.title("🎮 MMO AI Database Query Assistant")
st.caption("Natural language database assistant for MMO operations, economy, and security monitoring.")

st.info("Try prompts like: 'Who are the richest characters?' or 'Show suspicious login activity'.")

example_prompts = [
    "Who are the richest characters?",
    "Which characters have the most gold?",
    "Show suspicious large currency transfers",
    "Which accounts have suspicious login activity?",
    "Show recent transactions",
    "Show legendary item drop rules",
    "Show character overview",
]

st.sidebar.header("Quick Test Prompts")

selected_prompt = st.sidebar.selectbox(
    "Choose a professor-friendly test prompt:",
    example_prompts
)

if st.sidebar.button("Use selected prompt"):
    st.session_state["question"] = selected_prompt

question = st.text_area(
    "Ask a database question:",
    value=st.session_state.get("question", "Who are the richest characters?"),
    height=100
)

if st.button("Ask AI"):
    if not question.strip():
        st.warning("Please enter a question.")
    else:
        with st.spinner("Thinking..."):
            try:
                response = requests.post(
                    f"{API_URL}/ask",
                    json={"question": question}
                )

                if response.status_code == 200:
                    data = response.json()

                    st.subheader("Generated SQL")
                    st.code(data["query"], language="sql")
                    st.subheader("Explanation")
                    st.write(data["explanation"])
                    st.subheader("Results")

                    results = data.get("results", [])

                    if results:
                        df = pd.DataFrame(results)
                        st.dataframe(df, use_container_width=True)
                    else:
                        st.info("No results found.")
                else:
                    st.error(response.text)

            except Exception as e:
                st.error(f"Error: {e}")

st.divider()

st.subheader("Direct API Checks")

col1, col2, col3 = st.columns(3)

with col1:
    if st.button("Characters"):
        try:
            r = requests.get(f"{API_URL}/characters")
            if r.status_code == 200:
                st.dataframe(pd.DataFrame(r.json()["characters"]), use_container_width=True)
            else:
                st.error(r.text)
        except Exception as e:
            st.error(f"Error: {e}")

with col2:
    if st.button("Richest"):
        try:
            r = requests.get(f"{API_URL}/richest")
            if r.status_code == 200:
                st.dataframe(pd.DataFrame(r.json()["richest_players"]), use_container_width=True)
            else:
                st.error(r.text)
        except Exception as e:
            st.error(f"Error: {e}")

with col3:
    if st.button("Suspicious Transfers"):
        try:
            r = requests.get(f"{API_URL}/suspicious-transactions")
            if r.status_code == 200:
                st.dataframe(pd.DataFrame(r.json()["suspicious_transactions"]), use_container_width=True)
            else:
                st.error(r.text)
        except Exception as e:
            st.error(f"Error: {e}")