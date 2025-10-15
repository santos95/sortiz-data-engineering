from langchain_nvidia_ai_endpoints import ChatNVIDIA
from langchain_core.prompts import ChatPromptTemplate 
from langchain_core.output_parsers import StrOutputParser 
from langchain_core.runnables import RunnableLambda, RunnableParallel
from dotenv import load_dotenv
import os

load_dotenv()

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

# construct parallel runnable
# create two runnbles to execute in parallel and text the feature
title_case = RunnableLambda(lambda text: text.title())

count_words = RunnableLambda(lambda text: len(text.split()))


# this two can run in parallel because are not required for each other
text = 'building large lenguage models with prompt engineering'
title =  title_case.invoke(text)
print(f"title: {title}")

word_count = count_words.invoke(text)
print(f"word_count: {word_count}")

# work them in parallel using RunnbaleParallel
# to work with runnableParallel - past input a dict with a key value pairs
# the key is arbitrary and the values are the runnable that we want to execute in parallel
parallel_chain = RunnableParallel({'title': title_case, 'word_count': count_words})

# the results are mapped with the same key 
# the result will be a dict with the same keys with the result of runnables as values
response = parallel_chain.invoke(text)

print(response)

# the repsonse of runnableparallel are a dict 
# so, runnableparallel is a runnable and can be composed with other runnables 
# create a chain in which run in parallel the runnableparallel and at the end
# past the result to a runnable function to printout the output - format the output 
describe_title = RunnableLambda(lambda x: f"{x['title']} has {x['word_count']} words!")
print(describe_title.invoke({'title': title, 'word_count': word_count}))

# create a chain to with runnableparallel and the previous runnable 
final_chain = parallel_chain | describe_title

print("Test final chain: ", final_chain.invoke(text))