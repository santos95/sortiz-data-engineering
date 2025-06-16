from langchain_nvidia_ia_endpoints import ChatNVIDIA

base_url = "https://integrate.api.nvidia.com:8000/v1"
model = 'meta/llama-3.1-8b-instruct'

# create model instance 
llm = ChatNVIDIA(base_url = base_url, model = model, temperature=0)

# sanity check
prompt = "Where and when was NVIDIA founded?"

result = llm.invoke(prompt)

print(result.content)

# streaming resmponse as alternative of invoke - allow to recieve responses in chunks, mainly for large responses
# with invoke we have to wait that the entire response is ready - with chunks me get the response as is generated 
prompt = 'Explain who you are in roughly 500 words'

# use the stream to get the responses as chunks - get the response as is generated 
for chunk in llm.stream(prompt):
    print(chunk.content, end='')

# end='' override de default of print - which is ending fit next line
    
### using batch to use full capacity of llms - llms has some capacity to process multiple inputs at the same time
### that features enables to process multiple promps batch and process their response in parallel
### leverage the efficient use of the computational capacity of the llms - improve overall time to respond 


## a list of promps that need to be processed
state_capital_questions = [
    'What is the capital of Spain?',
    'What is the capital of Germany?',
    'What is the capital of France?',
    'What is the capital of Argentina?',
]

# get a reposponse for every prompt - with batch we process the entire list
capitals = llm.batch(state_capital_questions)

# get the size of response - must be 4 - one answer for every prompt that was send and processed concurrently
len(capitals)

for capital in capitals:
    print(capital.content)

## so - the time the response all that promps is less that running any of them indiviually
## the time required is bigger that running in parallel with batch
for scq in state_capital_questions:
    llm.invoque(scp)

# test - Batch process to create FAQ Document
faq_questions = ['What is a large lenguage model?',
                 'How do LLMs works?', 
                 'What are common applications of LLMs?',
                 'What is fine-tuning in the context of LLMs']

def create_faq_document(faq_questions, faq_answers):
    faq_document = ''

    for question, response in zip(faq_questions, faq_answers):
        faq_document += f'{question.upper()}\n\n'
        faq_document += f'{response.content}\n\n'
        faq_document += "-" * 30 + '\n\n'

# populate faq_answer with the answers of that questions 
faq_answers = llm.batch(faq_questions)

for answer in faq_questions:
    print(answer.content)