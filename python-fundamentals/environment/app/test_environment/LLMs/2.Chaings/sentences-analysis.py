from langchain_nvidia_ai_endpoints import ChatNVIDIA
from langchain_core.prompts import ChatPromptTemplate 
from langchain_core.output_parsers import StrOutputParser 
from langchain_core.runnables import RunnableLambda, RunnableParallel
from dotenv import load_dotenv
import os

load_dotenv()

# define parameters
api_key = os.getenv("API_KEY")
base_url = "https://integrate.api.nvidia.com/v1"
model = 'meta/llama-3.1-8b-instruct'

# instance of the llm 
llm = ChatNVIDIA(
    base_url=base_url, 
    model=model, 
    api_key=api_key, 
    temperature=0
)

# base statements to work with
statements = [
    "I had a fantastic time hiking up the mountain yesterday.",
    "The new restaurant downtown serves delicious vegetarian dishes.",
    "I am feeling quite stressed about the upcoming project deadline."]

# create the prompts templates

sentimental_template = ChatPromptTemplate.from_template("""In a single word, either 'positive' or 'negative', \
provide the overall sentiment of the following piece of text: {text}""")

main_topic_template = ChatPromptTemplate.from_template("""Identify and state, as concisely as possible, the main topic \
of the following piece of text: Only provide the main topic and no other helpful comments, Text: {text}""")

followup_template = ChatPromptTemplate.from_template("""What is an appropiate and interesting followup question that would help \
me learn more about the provided text? Only supply the question. Text: {text}""")

# define the outputparser
parser = StrOutputParser()

# define the output format
output_formatter = RunnableLambda(lambda responses: (
    f"Statement: {responses['statement']}\n"
    f"Overall sentiment: {responses['sentiment']}\n"
    f"Main Topic: {responses['main_topic']}\n"
    f"Followup question: {responses['followup']}\n"
))

# define a input runnable to get a dict for statements
prep_statements_for_template = RunnableLambda(lambda text: {"text": text})

# define chains
sentimental_analysis_chain =  sentimental_template | llm | parser 
main_topic_chain = main_topic_template | llm | parser
followup_chain = followup_template | llm | parser
statement_chain = RunnableLambda(lambda response: response['text'])

# define parallel chain
parallel_chain = RunnableParallel({
    'statement': statement_chain, 
    'sentiment': sentimental_analysis_chain, 
    'main_topic': main_topic_chain, 
    'followup': followup_chain
    })

# define the final chain
final_chain = prep_statements_for_template | parallel_chain | output_formatter 

# batch the statements into the final chain
responses = final_chain.batch(statements)

# print the responses
for response in responses:
    print(response)