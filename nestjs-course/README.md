# DevMatch - NestJS REST API

**Source:** https://youtu.be/21_I-12f5JE (freeCodeCamp NestJS course)

A REST API for a fictional dating app for developers, built while learning NestJS fundamentals.

## Tech Stack

- NestJS 12 + TypeScript
- Express (default HTTP adapter)

## What I Learned

- Structuring an app with modules, controllers and providers, and how Nest's decorators wire them together.
- Building a full CRUD controller: `@Get`, `@Post`, `@Put`, `@Delete` with `@Param`, `@Body` and `@HttpCode`.
- Moving business logic out of the controller into an injectable service via constructor dependency injection.
- Exception filters: how thrown errors bubble up, and throwing `NotFoundException` for proper 404 responses.
- Pipes for transformation (`ParseUUIDPipe`) and validation (global `ValidationPipe` + DTOs with class-validator decorators).
- Guards: implementing `CanActivate` and applying it to a route with `@UseGuards`.

## Folder Structure

- `src/profiles/` - the feature module: controller, service, guard and specs
- `src/profiles/dto/` - `CreateProfileDto` and `UpdateProfileDto` validation schemas
- `src/app.module.ts` - root module importing `ProfilesModule`
- `src/main.ts` - bootstrap, registers the global `ValidationPipe`
- `post.sh` / `put.sh` / `delete.sh` - curl scripts for testing the endpoints
- `test/` - e2e tests

## API Endpoints

| Method | Route           | Description            |
| ------ | --------------- | ---------------------- |
| GET    | `/profiles`     | List all profiles      |
| GET    | `/profiles/:id` | Get a single profile   |
| POST   | `/profiles`     | Create a profile       |
| PUT    | `/profiles/:id` | Update a profile       |
| DELETE | `/profiles/:id` | Delete a profile (204) |

## How to Run

1. Install dependencies: `npm install`
2. Start the dev server: `npm run start:dev` (runs on http://localhost:3000)
3. Hit the endpoints with `curl http://localhost:3000/profiles`, or run `bash post.sh` / `bash put.sh` / `bash delete.sh` (update the IDs in the scripts first).
