from openai import OpenAI

# base url - point to the nvidia site - listen on port 8000 /v1 endpoint
base_url = "https://integrate.api.nvidia.com:8000/v1"
api_key = "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"

# instance the open ai client
client = OpenAI(base_url = base_url, api_key = api_key)

# list models availables throuhgt the client 
available_models = client.models.list()

# print all the values and their content
print(available_models)

# print model available
print(available_models.data[0].id)

# make a simple chat completion request
model = 'meta/llama-3.1-8b-instruct'
prompt = 'Tell me a short fun fact about space.'

response = client.chat.completion.create(
    model = model 
    messages = [{'role': 'user', 'content': prompt}]
)

# print raw response
print(response)

print(response.choices[0].message.content)
