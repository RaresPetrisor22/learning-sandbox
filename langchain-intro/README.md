# LangChain Weather Agent & Embeddings

**Source:** https://www.youtube.com/watch?v=J7j5tCB_y4w&t=70s&pp=ygUSbGFuZ2NoYWluIHR1dG9yaWFs

## Tech Stack

- Python
- LangChain & LangGraph
- OpenAI API (gpt-4.1-mini, text-embedding-3-large)
- wttr.in API

## What I Learned

- Building an AI agent using LangChain's `create_agent` and `init_chat_model`.
- Defining custom tools with the `@tool` decorator and passing runtime context (`ToolRuntime`).
- Enforcing structured LLM responses using Python `dataclasses`.
- Managing conversation memory using LangGraph's `InMemorySaver`.
- Passing multimodal inputs (images) to chat models.
- Generating text embeddings with `OpenAIEmbeddings` and performing similarity searches using `FAISS`.

## How to Run

1. Create a `.env` file in the same directory and add your required API keys (e.g., `OPENAI_API_KEY=your_api_key`).
2. Install the required dependencies: `pip install langchain langchain-openai langchain-community langgraph faiss-cpu requests python-dotenv`.
3. Run the agent script: `python weather_agent.py`
4. Run the embeddings script: `python llm_embeddings.py`
