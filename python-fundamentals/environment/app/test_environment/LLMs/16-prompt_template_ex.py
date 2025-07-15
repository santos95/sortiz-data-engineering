# import required libraries
from langchain_nvidia_ai_endpoints import ChatNVIDIA
from langchain_core.prompts import ChatPromptTemplate 
from langchain_core.prompts import ChatPromptTemplate

# define parameters
base_url = "https://integrate.api.nvidia.com/v1"
api_key = "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"
model = 'meta/llama-3.1-8b-instruct'

# create the llm langchain instance
llm = ChatNVIDIA(
    base_url=base_url, 
    api_key=api_key,
    model=model, 
    temperature=0
    )

# General task - capture 3 llm-related tasks into a prompt template and apply them to a list of statements
# 1 - Sentimental analysis - Ascertain the overall sentiment of a given text
# 2 - Main topic identification - identify the main topic for a given text
# 3 - Followup question generation = Generates an appropiate followup question to clarify some aspect of a text

# list of statements to work with
statements = [
    "I had a fantastic time hiking up the mountain yesterday.",
    "The new restaurant downtown serves delicious vegetarian dishes.",
    "I am feeling quite stressed about the upcoming project deadline.",
    "Watching the sunset at the beach was a calming experience.",
    "I recently started reading a fascinating book about space exploration."
]

# Define the templates 
# sentimental analysis template
sentimental_analysis_temp = ChatPromptTemplate.from_template("""Perform a sentimental analysis of the next piece of a text \
by specifying if the text is 'positive' or 'negative'. The result has to be the single word if is 'Positive' or 'Negative'. \
Avoid any other sentence.This is the text: {statement}""")

main_topic_temp = ChatPromptTemplate.from_template("""Identify accurately and conscisely the main topic of a text. Only return the \
the main topic description and avoid any other sentences. This is the text: {statement}""")

followup_temp = ChatPromptTemplate.from_template("""Generate an interesting and appropiate followup question in away that allows to clarify some aspect of a text. \
Returns as result only the generated question, without any other sentece. This is the text: {statement}""")

# create the prompt 
sentimental_analysis_prompts = [sentimental_analysis_temp.invoke({"statement":statement}) for statement in statements]

main_topic_prompts = [main_topic_temp.invoke({"statement":statement}) for statement in statements]

followup_prompts = [followup_temp.invoke({"statement":statement}) for statement in statements]


# define the response list
sentimental_responses = []
main_topic_responses = []
followup_responses = []

# request the llms 
sentimental_responses = llm.batch(sentimental_analysis_prompts)

main_topic_responses = llm.batch(main_topic_prompts)

followup_responses = llm.batch(followup_prompts)

for statement, sentimental_response, main_topic_response, followup_response in zip(statements, sentimental_responses, main_topic_responses, followup_responses):
    
    print(
        f"Statement: {statement}\n"
        f"Overall Sentiment: {sentimental_response.content}\n"
        f"Main Topic: {main_topic_response.content}\n"
        f"Followup question: {followup_response.content}\n"
        )
