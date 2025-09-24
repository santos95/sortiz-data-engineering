from langchain_nvidia_ai_endpoints import ChatNVIDIA
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

base_url = 'http://llama:8000/v1'
model = 'meta/llama-3.1-8b-instruct'

# runnables 1 - LLM
llm = ChatNVIDIA(base_url=base_url, model=model, temperature=0)

# runnables 2 - template
translation_template = ChatPromptTemplate.from_template("""Translate the following statement from {from_lang} 
to {to_lang}. Provide only the translated text: {text}""")

# runnble 3 - parser
parser = StrOutputParser()

# define the chain - we use LCEL | To chain the runnbales in logic - template > llm > parser 
chain = translation_template | llm | parser

chain.input_schema.schema()

print(chain.get_graph().draw_ascii())

answer = chain.invoke({"from_lang": "English", "to_lang": "Portugues", "text": "I am the king of kings!"})

# string because of the parser
print(f"The answer: {answer}")