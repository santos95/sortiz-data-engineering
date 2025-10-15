from langchain_nvidia_ai_endpoints import ChatNVIDIA
from langchain_core.prompts import ChatPromptTemplate 
from langchain_core.output_parsers import StrOutputParser 
from langchain_core.runnables import RunnableLambda

base_url = "https://integrate.api.nvidia.com/v1"
api_key = ""
model = 'meta/llama-3.1-8b-instruct'

llm = ChatNVIDIA(base_url=base_url, model=model, api_key=api_key, temperature=0)

# test
test = llm.invoke("Which is the capital of Spain?")
print(test.content)

# runnable functions 

def double(x):
    return 2 * x 

try:
    double.invoke(2)
except AttributeError:
    print("'double' is a python function and does not have invoke method.")

# so double can not be used as a runnable - we can convert it into a custom runnable function
# using runnablelamda we can convert into a runnable
runnable_double = RunnableLambda(double)

print("Runnbale doble function:")
print(runnable_double.invoke(10))

# batch the runnable function
print(runnable_double.batch([10, 20, 30, 40]))

# chain the runnable function
multiply_by_eight = runnable_double | runnable_double | runnable_double
print("Chain runnable output for a value of 10: ", multiply_by_eight.invoke(10))


# creates a function to normalize text
import re 
import contractions 

def normalize_text(text) -> str:
    # convert text into lowercase
    text = text.lower()

    # Expand contractions 
    text = contractions.fix(text)

    # remove extra whitespaces 
    text = re.sub(r'\s+', ' ', text).strip()

    return text 

# create a runnable function to normalize text 
# 1 - create a runnable function to normalize text based on the above function
# 2 - Use it to batch process a list of reviews

reviews = [
    "I LOVE this product! It's absolutely   amazing   ",
    "Not bad, but could be better. I've seen worse.",
    "Terrible experience... I'm never buying again!!",
    "Pretty good, isn't it? Will buy again!",
    "Excellent value for the money!!! Highly recommended."
]

#  1 - normalize text runnable
normalize_text_runnable = RunnableLambda(normalize_text)

# test 
test = normalize_text(reviews[0])
print("Test of normalization: ", test)

# 2 - normalize batching the reviews list using the custom runnable function
normalized_reviews = normalize_text_runnable.batch(reviews)

print("Normalize - using the custom runnable function:")
for review in normalized_reviews:
    print(review)

# now creates a runnable to prepare the the normalized reviews and pass it to a prompt template
# so from the reviews, now we got a list of noramlized reviews, but the template needs a key value pairs
# requires a dict with the key - text: review - to be pased to the prompt template for each of the reviews in the list

sentiment_template = ChatPromptTemplate.from_template("""In a single word, either 'positive' or 'negative' \
provide the overall sentiment of the following piece of thext: {text}""")

# generates the prompt for each of the reviews - we use a python lamnda which receive a text as input and return a dict
prep_for_sentiment_template = RunnableLambda(lambda text: {"text": text})

normalized_for_prompt_template = prep_for_sentiment_template.batch(normalized_reviews)


print("Dict for prompt template")
for r in normalized_for_prompt_template:
    print(r)


# so create a chain that 1 normalize, 2 formatting to template 3 generate the prompt template 4 use the 
# prompt template to the llm and finally parsing the llm output with a strouputparser 
    
reviews = [
    "I LOVE this product! It's absolutely   amazing   ",
    "Not bad, but could be better. I've seen worse.",
    "Terrible experience... I'm never buying again!!",
    "Pretty good, isn't it? Will buy again!",
    "Excellent value for the money!!! Highly recommended."
]