# Second-Hand Marketplace

### Getting Started (Docker)

**Prerequisites:** [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running.

**1. Start the app:**
```bash
docker compose up --build
```
Wait until you see `Listening on http://0.0.0.0:3000`. The first run takes a few minutes to download and build.

**2. In a new terminal tab, set up the database (first time only):**
```bash
docker compose exec web bundle exec rails db:create db:migrate
```

**3. Open in your browser:**
```
http://localhost:3000
```

**To stop the app:** Press `Ctrl+C` in the terminal running `docker compose up`.

**To start again after stopping:**
```bash
docker compose up
```

### Current status (brief)
- Rails app set up with products (listings), users, and likes.
- Email/password authentication with sign up / sign in / sign out flows.
- User profile and password management pages in place.
- Product listing pages (index/show) and basic create/edit forms implemented.
- Basic PWA manifest and service worker views stubbed.

### TODO (brief)
- Polish product creation/editing UI and add stronger validations.
- Implement search, sorting, and filtering for product listings.
- Add image upload for products and display in views.
- Add flash messages and better error handling on auth and forms.
- Configure database seeds with realistic sample data.
- Write model, controller, and request specs/tests.
- Prepare production deployment configuration and environment variables.
