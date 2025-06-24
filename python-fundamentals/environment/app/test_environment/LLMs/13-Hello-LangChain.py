# for the llm running on nvidia nim - llama model - requires the langchain_nvidia_ai_endopoints with the ChatNVIDIA method
from langchain_nvidia_ai_endpoints import ChatNVIDIA

# requires the base url, the model and instance of the model
base_url = 'http://llama:800/v1'
model = 'meta/llama-3..1-8b-instruct'

# temperature - hyperparameter used to modify how much deterministic the model will be
# 0 more deterministic (most probable answer) - 1 more random answers - is less probable to get the most probable answer - creativity
llm = ChatNVIDIA(base_url = base_url, model = model, temperature = 0)

# create the prompt
prompt = 'Who are you?'

# simple send the promnt thoruhg the invoke method 
result = llm.invoke(prompt)

# the answer include tokens to keep the context of the previous propmts
print(result)
print(result.content)

