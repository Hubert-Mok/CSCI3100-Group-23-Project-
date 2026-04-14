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

  This prepares the test database and runs the tests inside the same Docker environment used in development. Requires the container to have been started after the latest `docker-compose.yml` (which injects `TEST_DATABASE_URL`). If you see a socket connection error, stop and restart: `docker compose down && docker compose up -d` then run the command again.

### CI (GitHub Actions)

On each push and pull request to `main`, GitHub Actions runs:
- **Security scans (Ruby)**: `bin/brakeman` and `bin/bundler-audit`
- **Security scan (JavaScript)**: `bin/importmap audit`
- **Linting**: `bin/rubocop -f github`
- **Tests**: `bin/rails db:test:prepare test`

### Current status
- Rails app set up with products (listings), users, and likes.
- Email/password authentication with sign up / sign in / sign out flows.
- School-email verification (CUHK domains only) — sent on sign-up, sign-in blocked until verified.
- Forgot-password reset flow via time-limited email token (30-minute expiry).
- User profile, password management, and Stripe account connection pages in place.
- Product listing pages (index/show) with create/edit forms, image upload, and enums for status (available/reserved/sold) and type (sale/gift).
- Fuzzy search, category/status filtering, and sorting (price, most liked, newest) for product listings.
- Stripe-based checkout with escrow-style payments (orders, success/cancel flow, webhook handling, and seller payout when buyer confirms receipt).
- Real-time updates and notifications for key events (order/payment lifecycle, status changes) using Turbo Streams / Action Cable.
- GitHub Actions CI pipeline for security scans, linting, and running the Rails test suite.
- Basic PWA manifest and service worker views stubbed.


There's another production link(with azure config and cloudflare dns) : https://cuhkmarket.com (UI/UX different deign)

| Feature Name | Primary Developer (Development) | Secondary Developer (Testing and Bugfix) | Notes |
| :--- | :--- | :--- | :--- |
| User Authentication | Ben | Kwok Chi Him Jacco | Sign up, sign in, sign out flows |
| Email Verification | Ben, MOK Yik Him Hubert | Jacco | School-email verification (CUHK domains) |
| User Profiles | Ben | Jacco, Hubert | View and edit user profiles |
| Products Publising | - | Jacco, Hubert | Create, edit, delete, and publish product listings |
| Searching | Jacco  | Hubert | Fuzzy search, category/status filtering, sorting |
| Product Likes | - | Jacco, Hubert | Like/unlike products and view liked products |
| Notifications | Ben  | Jacco, Hubert | Real-time notifications via Turbo Streams & Action Cable |
| Messaging | Ben | Jacco, Hubert | Buyer-seller conversations with message management |
| Orders & Checkout | Ben | Jacco | Stripe-based escrow payment flow |
| Data initialization | - | - | give virtual and initialal data setup|
| Delay use testing | - | - | Daily normal usage test |
| Website deployment | Hubert | - | deploy the website to heroku |
| Bug Analyise | - | - | Find error and bugs |  
| Fraud Detection | Hubert | - | Find suspicious products and messages
| Admin Moderation| Hubert | - | Added Admin access and Admin Dashboard to check suspicious products and messages
