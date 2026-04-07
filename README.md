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

**3. In the second terminal tab, add sample data (for development only):**
```bash
docker compose exec web rails dev:reset_samples
```
You will see `⚠️  This will DELETE ALL PRODUCTS from the database! Are you sure? Type Y to continue, anything else to cancel.`, type `Y` to reset sample data.

**4. Open in your browser:**
```
http://localhost:3000
```

**To stop the app:** Press `Ctrl+C` in the terminal running `docker compose up`.

**To start again after stopping:**
```bash
docker compose up
```

**5. Stripe (payments):** Create a `.env.development` file in the project root with:
- `STRIPE_SECRET_PUBLIC_KEY` — your Stripe publishable key (e.g. `pk_test_...`)
- `STRIPE_SECRET_PRIVATE_KEY` — your Stripe secret key (e.g. `sk_test_...`)
- `STRIPE_WEBHOOK_SECRET` — from `stripe listen --forward-to localhost:3000/webhooks/stripe` (development) or the Stripe Dashboard (production)

Docker Compose loads `.env.development` into the web service. For local dev without Docker, the app uses the `dotenv-rails` gem to load `.env.development`.

### Development & testing

- **Ruby version**: 3.4 (managed via Docker images; no need to install Ruby locally if you use Docker).
- **Run RuboCop (style checks)**:

  ```bash
  docker compose exec web bin/rubocop
  ```

- **Run test suite**:

  ```bash
  docker compose exec web bin/rails db:test:prepare test
  ```

  This prepares the test database and runs the tests inside the same Docker environment used in development.

### CI (GitHub Actions)

On each push and pull request to `main`, GitHub Actions runs:
- **Security scans (Ruby)**: `bin/brakeman` and `bin/bundler-audit`
- **Security scan (JavaScript)**: `bin/importmap audit`
- **Linting**: `bin/rubocop -f github`
- **Tests**: `bin/rails db:test:prepare test`

### Current status (brief)
- Rails app set up with products (listings), users, and likes.
- Email/password authentication with sign up / sign in / sign out flows.
- User profile, password management, and Stripe account connection pages in place.
- Product listing pages (index/show) with create/edit forms, image upload, and enums for status (available/reserved/sold) and type (sale/gift).
- Search, category/status filtering, and sorting (price, most liked, newest) for product listings.
- Stripe-based checkout with escrow-style payments (orders, success/cancel flow, webhook handling, and seller payout when buyer confirms receipt).
- Real-time updates and notifications for key events (order/payment lifecycle, status changes) using Turbo Streams / Action Cable.
- GitHub Actions CI pipeline for security scans, linting, and running the Rails test suite.
- Basic PWA manifest and service worker views stubbed.

### TODO (brief)
-~~Refine product creation/editing UI and validations (e.g. price rules, description length)~~
- ~~Add more robust flash messages and edge-case handling (e.g. expired sessions, unauthorized access).~~
- ~~Configure database seeds with realistic sample users, products, and likes.~~
- Expand automated tests (models, controllers, and key flows via system tests).
- Finalize production deployment configuration, environment variables, and Kamal registry/host settings.
- ~~Implement a secure payment flow (e.g. Stripe/PayPal integration)~~ — Stripe Connect + Checkout with escrow (buyer confirms receipt before seller is paid).
- ~~Add real-time item status updates and notifications (e.g. reserved/sold) using Action Cable so buyers and sellers see changes instantly.~~ — implemented via Turbo Stream broadcasts for orders and item status, plus notification badge updates.
- Enable and polish PWA support (manifest route, service worker, basic offline behaviour).
