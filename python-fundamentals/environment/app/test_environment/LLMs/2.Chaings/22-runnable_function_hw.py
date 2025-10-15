from langchain_nvidia_ai_endpoints import ChatNVIDIA
from langchain_core.prompts import ChatPromptTemplate 
from langchain_core.output_parsers import StrOutputParser 
from langchain_core.runnables import RunnableLambda
import re 
import contractions 

base_url = "https://integrate.api.nvidia.com/v1"
api_key = ""
model = 'meta/llama-3.1-8b-instruct'

# instance of the llm 
llm = ChatNVIDIA(
    base_url=base_url, 
    model=model, 
    api_key=api_key, 
    temperature=0
)

#reviews = [
#    "I LOVE this product! It's absolutely   amazing   ",
#    "Not bad, but could be better. I've seen worse.",
#    "Terrible experience... I'm never buying again!!",
#    "Pretty good, isn't it? Will buy again!",
#    "Excellent value for the money!!! Highly recommended."
#]

reviews = [
    "I LOVE this product! It's absolutely     amazing. ",
    "Not bad, but could be better. I've seen worse.",
    "Terrible experience... I'm never buying again!!",
    "Pretty good, isn't it? Will buy again!",
    "Excellent value for the money!!! Highly recommended."
]

# normalize reviews
def normalize_text(text) -> str:
    # convert text into lowercase
    text = text.lower()

    # Expand contractions 
    text = contractions.fix(text)

    # remove extra whitespaces 
    text = re.sub(r'\s+', ' ', text).strip()

    return text 

# define the prompt template
sentiment_template = ChatPromptTemplate.from_template("""In a single word, either 'positive' or 'negative' \
provide the overall sentiment of the following piece of thext: {text}""")


# normalize text runnable function
normalize_text_runnable = RunnableLambda(normalize_text)

# format normalize text for prompt template
prep_for_sentiment_template = RunnableLambda(lambda text: {"text": text})

# define the output parser 
parser = StrOutputParser()

# define the chain 
chain = normalize_text_runnable | prep_for_sentiment_template | sentiment_template | llm | parser

responses = chain.batch(reviews)

#print(normalize_text_runnable.invoke(reviews[0]))
for review, response in zip(reviews, responses):
    print(
        f"Review: {review}\n" 
        f"Overall sentiment: {response}\n"
        )

