# dbmgmt_project
Multi-layer Database System for online multiplayer games

This project is an AI-powered database assistant that allows users to ask questions in natural language and receive results from a cloud-hosted MySQL database without needing to write SQL manually.

 To run it, first install the required dependencies using pip install -r requirements.txt, then create a .env file in the project directory containing the MYSQL_PUBLIC_URL and ANTHROPIC_API_KEY. 
 
 Start the backend by running uvicorn main:app --reload, and in a separate terminal launch the user interface with streamlit run app.py, 

 then open the provided local URL in your browser. From there, you can test queries such as “Who are the richest characters?” or “Show suspicious large currency transfers,” and the system will generate SQL,

execute it safely, and display the results. The application is designed to only allow safe SELECT queries, limit output size, 

and provide a structured interface for exploring MMO-style data, while keeping credentials secure by excluding environment variables from version control.



Example prompts: 
“Who are the richest characters?”
“Which characters have the most gold?”
“Show top 5 players by inventory value”

“Show suspicious large currency transfers”
“Which accounts have suspicious login activity?”
“Who is sending unusually large amounts of currency?”

“Show recent transactions”
“Who trades the most?”
“Show transaction summary for players”

“Show character overview”
“Which class has the highest level players?”
“Show legendary item drop rules”