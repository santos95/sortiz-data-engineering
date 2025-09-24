# prompts templates to capture llM-RELATED tasks into prompts templates
# in that way create reusable prompt templates
# perform a variety llm powered tasks on a collection of text examples 
from langchain_nvidia_ai_endpoints import ChatNVIDIA
from langchain_core.prompts import ChatPromptTemplate 

base_url = ""
api_key = ""
model = 'meta/llama-3.1-8b-instruct'

llm = ChatNVIDIA(
    base_url=base_url, 
    api_key=api_key,
    model=model, 
    temperature=0
    )

# emulate the reuse code of functions functionality - thats what we want with prompts template
# be able to reuse prompts with different inputs 

# test with one off taks
one_off_prompt = "Translate the following from English to Spanish: 'Today is a good day.'"

def print_prompt(prompt):
    print(f"This is my prompt: {prompt}")

def print_response(response):
    print(f"This is the response: {response}")


# perform a llm request
print_prompt(one_off_prompt)
response = llm.invoke(one_off_prompt).content 

print_response(response)

## so we can make that prompt into a reusable one 
# we do that by abstracting parts of the prompts into arguments 
# in that way we get a prompt that can be used with arbitraries inputs

# this functions creates a prompt template that capture the functionality of translating and english statement into a spanish
def translate_from_eng_to_sp(en_statement):
    return f"Translate the following from English to Spanish: {en_statement}"

# set a list of statements to test

en_statements = [
    'Today is a good day.'
    'Tomorrow will be even better.'
]

# create a list of prompts with the template function
prompts = [translate_from_eng_to_sp(en_statement) for en_statement in en_statements]


# test - perform batch statements
translations = llm.batch(prompts)

# print the translations
for translation in translations:
    print(translation.content)


# create a template that are able to to the same but adding from which language to a lenguage
def translate(from_lang, to_lang, statement):
    return f"Translate the following from {from_lang} to {to_lang}. Provide only the translated text: {statement}"

print(llm.invoke(translate('English', 'Portugues', 'I am become death the destroyer of worlds!')))


# use the prompt template from the ChatPromptTemplate package from langchain
from langchain_core.prompts import ChatPromptTemplate

# creates a template 
en_to_sp_template = ChatPromptTemplate.from_template("""Translate the following from English to Spanish. \
Provide only the translated text: '{english_statement}'""")

# get the prompt from the template
prompt = en_to_sp_template.invoke("Now I am become death, the destroyer of worlds!")

print(prompt)

print("This is the response: ", llm.invoke(prompt).content)

# the best practices for templates when we create them is to use a dict to map
# the placeholders values with the content, the above only pass whe content because is a single value
# for more than one values is necessary to pass dicts. but as best practice even 
# is it only one pass a dict
prompt = en_to_sp_template.invoke({"english_statement":"Now I am become death, the destroyer of worlds!"})

print(prompt)
