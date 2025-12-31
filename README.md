# DevOps Assignment: User Registration App

This project consists of a Python Flask application for user registration, connected to a PostgreSQL database, and fully containerized using Docker.

## 📋 Assignment Requirements & Implementation

The project was built according to the following requirements:

### Task 1: Application Development (Flask + DB)
- ✅ Developed a Web application displaying a registration form.
- ✅ The application retrieves the database address via an environment variable (`DB_HOST`).
- ✅ Created a `users` table within a PostgreSQL database.

### Task 2: Docker & Docker Compose
- ✅ Created a `Dockerfile` using the `python:slim` version to minimize image size.
- ✅ Created a `docker-compose.yml` file defining both Web and DB services.
- ✅ Configured a `Volume` for database persistence to ensure data is saved even if the container crashes.

### Task 3: Automation (Ansible)
- ✅ Created a `playbook.yml` designed to install the environment (Docker & Compose) and deploy the project files onto a clean Linux server.

---

## 🚀 How to Run

To run the full system, execute the following command in the terminal:

```bash
docker-compose up --build