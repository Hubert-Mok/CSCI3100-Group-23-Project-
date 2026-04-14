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

### CI (GitHub Actions)

On each push and pull request to `main`, GitHub Actions runs:
- **Security scans (Ruby)**: `bin/brakeman` and `bin/bundler-audit`
- **Security scan (JavaScript)**: `bin/importmap audit`
- **Linting**: `bin/rubocop -f github`
- **Tests**: `bin/rails db:test:prepare test`


| Feature Name | Primary Developer (Development) | Secondary Developer (Testing and Bugfix) | Notes |
| :--- | :--- | :--- | :--- |
| User Authentication | Ben | Kwok Chi Him Jacco | Sign up, sign in, sign out flows |
| Email Verification | Ben | Jacco | School-email verification (CUHK domains) |
| User Profiles | Ben | Jacco | View and edit user profiles |
| Products Publising | - | Jacco Alice| Create, edit, delete, and publish product listings |
| Searching | Jacco  | - | Fuzzy search, category/status filtering, sorting |
| Product Likes |Alice| Jacco| Like/unlike products and view liked products |
| Notifications | Ben  | Jacco | Real-time notifications via Turbo Streams & Action Cable |
| Messaging | Ben | Jacco | Buyer-seller conversations with message management |
| Orders & Checkout | Ben | Jacco | Stripe-based escrow payment flow |
| Data initialization | Alice | - | give virtual and initialal data setup|
| Delay use testing | - | - | Daily normal usage test |
| Website deployment | - | - | deploy the website to heroku |
| Bug Analyise | - | Alice | Find error and bugs |  
|PWA support|Alice|-|manifest and service worker views|
| Email Verification | Ben, MOK Yik Him Hubert | Jacco, Ng Hei Yi Melody | School-email verification (CUHK domains) |
| User Profiles | Ben | Jacco, Hubert | View and edit user profiles |
| Products Publising | - | Jacco, Hubert | Create, edit, delete, and publish product listings |
| Searching | Jacco  | Hubert | Fuzzy search, category/status filtering, sorting |
| Product Likes | - | Jacco, Hubert, Ng Hei Yi Melody | Like/unlike products and view liked products |
| Notifications | Ben  | Jacco, Hubert | Real-time notifications via Turbo Streams & Action Cable |
| Messaging | Ben | Jacco, Hubert | Buyer-seller conversations with message management |
| Orders & Checkout | Ben | Jacco | Stripe-based escrow payment flow |
| Data initialization | Ng Hei Yi Melody | - | give virtual and initialal data setup|
| Delay use testing | - | - | Daily normal usage test |
| Website deployment | Hubert | - | deploy the website to heroku |
| Bug Analyise | - | Ng Hei Yi Melody | Find error and bugs |  
| Fraud Detection | Hubert | - | Find suspicious products and messages
| Admin Moderation | Hubert | Ng Hei Yi Melody | Added Admin access and Admin Dashboard to check suspicious products and messages
| Demo video Editing | Ng Hei Yi Melody | - | Screen shooting and editing the demo video with narration and subtitle added
