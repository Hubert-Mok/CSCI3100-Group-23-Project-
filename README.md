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

**6. Email (verification + password reset):** Add the following to `.env.development`:
- `RESEND_API_KEY` — your [Resend](https://resend.com) API key (e.g. `re_...`)
- `MAILER_FROM` — the verified sender address in your Resend domain (e.g. `noreply@yourdomain.com`)

Without `RESEND_API_KEY` set, emails are printed to the Rails log in development (no real emails sent). In production, also set:
- `APP_HOST` — your production hostname (e.g. `marketplace.example.com`)

Docker Compose loads `.env.development` into the web service.

### Development & testing

Run these from the project root with the stack up (`docker compose up`).

- **RuboCop**:

  ```bash
  docker compose exec web bin/rubocop
  ```

- **Tests (Minitest, RSpec, Cucumber)** — uses `TEST_DATABASE_URL` from `docker-compose.yml`:

  ```bash
  docker compose exec -e RAILS_ENV=test web bin/rails db:test:prepare test
  docker compose exec -e RAILS_ENV=test web bundle exec rspec
  docker compose exec -e RAILS_ENV=test web bundle exec cucumber
  ```

  If the database connection fails, restart the stack: `docker compose down && docker compose up -d`.

### Azure (production)

Deploy the production [Dockerfile](Dockerfile) to **Azure Container Apps** with **PostgreSQL Flexible Server** using the Azure Developer CLI. See [infra/README.md](infra/README.md) for `azd up`, secrets, migrations, custom domains, and Stripe webhooks. CI includes an optional [`.github/workflows/azure-dev.yml`](.github/workflows/azure-dev.yml) workflow (manual run after `azd pipeline config`).

### CI (GitHub Actions)

On each push and pull request to `main`, GitHub Actions runs:
- **Security scans (Ruby)**: `bin/brakeman` and `bin/bundler-audit`
- **Security scan (JavaScript)**: `bin/importmap audit`
- **Linting**: `bin/rubocop -f github`
- **Tests**: Minitest (`bin/rails db:test:prepare test`), RSpec, and Cucumber (with PostgreSQL and dummy Stripe test env vars)

### Current status (brief)
- Rails app set up with products (listings), users, and likes.
- Email/password authentication with sign up / sign in / sign out flows.
- School-email verification (CUHK domains only) — sent on sign-up, sign-in blocked until verified.
- Forgot-password reset flow via time-limited email token (30-minute expiry).
- User profile, password management, and Stripe account connection pages in place.
- Product listing pages (index/show) with create/edit forms, image upload, and enums for status (available/reserved/sold) and type (sale/gift).
- Search, category/status filtering, and sorting (price, most liked, newest) for product listings.
- Stripe-based checkout with escrow-style payments (orders, success/cancel flow, webhook handling, and seller payout when buyer confirms receipt).
- Real-time updates and notifications for key events (order/payment lifecycle, status changes) using Turbo Streams / Action Cable.
- GitHub Actions CI pipeline for security scans, linting, and running the Rails test suite.
- Basic PWA manifest and service worker views stubbed.

### TODO (brief)
- Refine product creation/editing UI and validations (e.g. price rules, description length).
- Add more robust flash messages and edge-case handling (e.g. expired sessions, unauthorized access).
- Set `email_verified_at` on seeded users (or document the email-verification step) so README demo credentials can sign in without extra friction.
- Expand automated tests (models, controllers, and key flows via system tests).
- Production on Azure: see [infra/README.md](infra/README.md); optional Kamal/registry settings remain separate if you use that path.
- Enable and polish PWA support (manifest route, service worker, basic offline behaviour).
