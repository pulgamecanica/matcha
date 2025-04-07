# 🧪 Matcha API — Love, Logic & Low-Latency 💘

[![Sinatra](https://img.shields.io/badge/Made%20with-Sinatra-ff69b4?logo=sinatra)](http://sinatrarb.com/)
[![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-336791?logo=postgresql)](https://www.postgresql.org/)
[![Dockerized](https://img.shields.io/badge/Dockerized-Yes-blue?logo=docker)](https://www.docker.com/)
[![Tested with RSpec](https://img.shields.io/badge/Tested%20with-RSpec-ff4155?logo=ruby)](https://rspec.info/)
[![TDD](https://img.shields.io/badge/TDD-Driven-%23cc0066?logo=testing-library)]
[![Custom DSL](https://img.shields.io/badge/DSL-api_doc-%23bada55)]()

> The only thing better than a Matcha latte is a **match made in Ruby**.  
> This is a fully-documented, TDD-driven Sinatra API for the Matcha dating platform. It’s modular, dockerized, and optimized for love at first request 💘

---

## 📦 Tech Stack

| Layer | Tech |
|-------|------|
| Framework | Sinatra (modular) |
| Language | Ruby 3.2 |
| Database | PostgreSQL 14 |
| ORM | Raw SQL (for now) |
| Containerization | Docker + Compose |
| Testing | RSpec + Rack::Test |
| API Docs | `api_doc` DSL (custom-built) |
| Tasking | Rakefile & Makefile |
| Console | `bin/console` via IRB |

---

## ⚙️ Features

- 🔥 Modular Sinatra architecture
- 🧪 TDD with RSpec from the start
- 📚 Internal `api_doc` DSL for route-level documentation
- 🐘 PostgreSQL-powered persistence
- 🐳 Fully Dockerized dev environment
- 🔄 Hot-reloading compatible
- 🧵 Clean task system via `rake`
- 👨‍💻 IRB dev console with app context

---

## 🗂️ Project Structure

```
.
├── app/
│   ├── controllers/     # Modular Sinatra route files
│   ├── doc/             # DSL for API documentation
│   ├── helpers/         # Request validation, shared logic
├── config/
│   └── environment.rb   # Loads env, controllers, etc
├── db/
│   ├── migrate/         # DB migrations (manual for now)
│   └── seeds.rb
├── spec/                # RSpec tests
├── docker/              # Dockerfile lives here
├── bin/
│   └── console          # IRB REPL with app context
├── docker-compose.yml
├── .env
├── Rakefile
├── README.md
└── config.ru
```

---

## 🚀 Getting Started

### 🔧 Local Dev (Dockerized)

```bash
git clone https://github.com/yourname/matcha-api
cd matcha-api

# build the containers
docker compose build

# run the app
docker compose up

# test it
docker compose run web bundle exec rspec

# open a console
docker compose run web ./bin/console
```

---

## 🛠️ Developer Shortcuts (Makefile)

For quick and consistent dev flow, use the provided `Makefile`:

```bash
# Export API docs to docs/exported.md
make docs

# Create the database
make create

# Run all migrations
make migrate

# Run tests via RSpec
make test

# Open an interactive Ruby console with app context
make console
```

Behind the scenes, these commands run inside the Docker container and use `rake` + `irb` for tasks and dev tooling.

---

## 🧪 Testing

All tests live in `spec/`, written with `RSpec` and `Rack::Test`.

---

## 📘 API Docs (WIP)

Every route is documented inline using the `api_doc` DSL.  
You can export them as Markdown:

```bash
make docs
```

➡ Output: `docs/exported.md`

---

## 🎯 Roadmap

- [x] Docker support
- [x] RSpec + test coverage
- [x] Custom DSL for inline route docs
- [x] Rake-based dev tasks
- [ ] Auth system (`/auth/register`, `/auth/login`)
- [ ] Password hashing with BCrypt
- [ ] User validation
- [ ] Tag system and search
- [ ] Real-time notifications (optional)
- [ ] Deployment docs

---

## 💡 Philosophy

> Don't write docs later — build them in.  
> Don't trust specs — test first.  
> 🧙‍♂️ Made With Love
> code clarity
> full test coverage
> zero-dependency power

---

