# Docker Tutorial

**Source:** https://youtu.be/pg19Z8LL06w, https://youtu.be/SXwC9fSwct8

## Tech Stack

- Docker & Docker Compose
- Node.js / Express
- MongoDB & Mongo Express

## What I Learned

- Docker fundamentals: images vs containers, writing a `Dockerfile`, and building/running images with the Docker CLI.
- Multi-container apps with Docker Compose, using a `services` YAML file to define an app, database, and admin UI together.
- Passing configuration and secrets into containers via environment variables (e.g. Mongo credentials).
- Publishing an image to Docker Hub for reuse in `docker-compose.yaml`.

## How to Run

**docker fundamentals**

1. `cd "docker fundamentals"`
2. `docker build -t docker-fundamentals .`
3. `docker run -p 3000:3000 docker-fundamentals`

**docker compose**

1. `cd "docker compose"`
2. Create a `.env` file with `MONGO_ADMIN_USER` and `MONGO_ADMIN_PASS`.
3. `docker compose -f mongo-services.yaml up`
4. Open `http://localhost:3000` (app) and `http://localhost:8081` (Mongo Express).
