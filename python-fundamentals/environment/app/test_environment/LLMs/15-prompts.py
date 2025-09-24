from langchain_nvidia_ai_endpoints import ChatNVIDIA

base_url = ""
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
Only give me the result of the Email format, do not add any sentence or innecessary white spaces, string result"\
"""

result = llm.invoke(prompt)

llm_address = result.content

# have to return true
llm_address == target_address

# # Understanding Completion and Chat Completion Endpoints
# We have been working with the chat.completions endpoint, but when working with the OpenAI API, you also have the option to use the completions endpoint. Understanding the differences between these endpoints is crucial, as they handle prompts and generate responses differently, even for a single prompt.

# The chat.completions endpoint is designed to handle multi-turn conversations, keeping track of the context provided by previous messages. It generates more concise, focused responses by anticipating a back-and-forth interaction, even if only a single prompt is provided.

# The completions endpoint is designed for generating a response to a single prompt without maintaining conversational context. It aims to complete the prompt that was given to it, rather than respond to it conversationally.

# The main takeaway is that when working with "chat" or "instruction" models (like the llama-3.1-8b-instruct model you are working with today), use chat.completions and not completions.