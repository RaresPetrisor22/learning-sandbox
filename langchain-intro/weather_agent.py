from dataclasses import dataclass

import requests
from dotenv import load_dotenv
from langchain.agents import create_agent
from langchain.tools import tool, ToolRuntime
from langchain_core.runnables import RunnableConfig
from langgraph.checkpoint.memory import InMemorySaver

from langchain.chat_models import init_chat_model
from langchain.messages import HumanMessage

load_dotenv()

@dataclass
class Context:
    user_id: str

@dataclass
class ResponseFormat:
    summary: str
    temperature_celsius: float  
    temperature_fahrenheit: float
    humidity: float

@tool('get_weather', description="Get the current weather for a given location",return_direct=False)
def get_weather(city: str):
    response = requests.get(f'https://wttr.in/{city}?format=j1')
    return response.json()

@tool('locate_user', description="Locate the user based on the context", return_direct=False)
def locate_user(runtime: ToolRuntime[Context]):
    match runtime.context.user_id:
        case 'ABC123':
            return 'Vienna'
        case 'XYZ456':
            return 'London'
        case "HJKL111":
            return 'Paris'
        case _:
            return 'Unknown'
        
model = init_chat_model('gpt-4.1-mini',temperature=0.3)

checkpointer = InMemorySaver()

agent = create_agent(
    model = model, 
    tools = [get_weather,locate_user],
    system_prompt="You are a helpful weather assistant that always cracks jokes but remains helpful",
    context_schema = Context,
    response_format=ResponseFormat,
    checkpointer = checkpointer
)

config: RunnableConfig = {'configurable': {'thread_id': '1'}}

response = agent.invoke(
    {
        'messages': [
            {'role': 'user', 'content': 'And is this usual?'}
        ]
    },
    config=config,
    context=Context(user_id='XYZ456')
)
print(response['structured_response'])
print(response['structured_response'].summary)
print(response['structured_response'].temperature_celsius)


model = init_chat_model('gpt-4.1-mini')

message = {
    'role': 'user',
    'content': [
        {'type': 'text', 'text': 'Describe the content of this image?'},
        {'type': 'image','url': 'https://static.wikia.nocookie.net/character-stats-and-profiles/images/5/52/Sahur2.webp/revision/latest/scale-to-width-down/340?cb=20250510085254'}
    ]
}

response =model.invoke([message])
print(response.content)