from langchain_nvidia_ai_endpoints import ChatNVIDIA

base_url = "https://integrate.api.nvidia.com:8000/v1"
model = 'meta/llama-3.1-8b-instruct'

# create model instance 
llm = ChatNVIDIA(base_url = base_url, model = model, temperature=0)

# be as verbose and specific to get the right answer for the llms or the desire response 
# be careful with white spaces and new lines - impacts llms responses, for well or worst can generate different answers from llms

# ways of handle - using the \ to scape new lines characters 
prompt = """\
I am trying to figure out the trim of cars based on feauters like motor size, \
number of seats, model, year, motor, and some other features like if the car has \
backup camera, sunroof, and other. So, based on the car data compare with real car \
data to get the most accurate trim for the car data that is passed to yout.\
"""

# for functions where we have to format the code with white spaces for the python interpreter - we can manage in this way
def get_large_prompt():
    return """I am trying to figure out the trim of cars based on feauters like motor size, \
number of seats, model, year, motor, and some other features like if the car has \
backup camera, sunroof, and other. So, based on the car data compare with real car \
data to get the most accurate trim for the car data that is passed to yout.\
"""
# the previous way affect a little bit the format but in that way we can avoid four spaces that can be intruduced uninteded when we inded the code

# another way - python automatically concatenate json string literals 
def get_large_prompt():
    return (
        "I am trying to figure out the trim of cars based on feauters like motor size"
        "number of seats, model, year, motor, and some other features like if the car has "
        "backup camera, sunroof, and other. So, based on the car data compare with real car "
        "data to get the most accurate trim for the car data that is passed to yout."
        )

## asignment
llm_address = ''

prompt = """Give me the address for a letter of email format address convention. \
The company names is "Some Company". The address is 12345 NW Green Meadow Drive, \
the state is Portland, and also add the postal code 97203. Be detailed with the \
whitespaces and new lines required to get the best format.\
"""

result = llm.invoke(prompt)

llm_address = result.content
