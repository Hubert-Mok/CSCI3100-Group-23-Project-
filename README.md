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

**4. Stripe (payments):** Create a `.env.development` file in the project root with:
- `STRIPE_SECRET_PUBLIC_KEY` — your Stripe publishable key (e.g. `pk_test_...`)
- `STRIPE_SECRET_PRIVATE_KEY` — your Stripe secret key (e.g. `sk_test_...`)
- `STRIPE_WEBHOOK_SECRET` — from `stripe listen --forward-to localhost:3000/webhooks/stripe` (development) or the Stripe Dashboard (production)

Docker Compose loads `.env.development` into the web service. For local dev without Docker, the app uses the `dotenv-rails` gem to load `.env.development`.

### Current status (brief)
- Rails app set up with products (listings), users, and likes.
- Email/password authentication with sign up / sign in / sign out flows.
- User profile and password management pages in place.
- Product listing pages (index/show) and basic create/edit forms implemented.
- Basic PWA manifest and service worker views stubbed.

### TODO (brief)
- Refine product creation/editing UI and validations (e.g. price rules, description length).
- Add more robust flash messages and edge-case handling (e.g. expired sessions, unauthorized access).
- Configure database seeds with realistic sample users, products, and likes.
- Expand automated tests (models, controllers, and key flows via system tests).
- Finalize production deployment configuration, environment variables, and Kamal registry/host settings.
- ~~Implement a secure payment flow (e.g. Stripe/PayPal integration)~~ — Stripe Connect + Checkout with escrow (buyer confirms receipt before seller is paid).
- Add real-time item status updates and notifications (e.g. reserved/sold) using Action Cable so buyers and sellers see changes instantly.
- Enable and polish PWA support (manifest route, service worker, basic offline behaviour).
