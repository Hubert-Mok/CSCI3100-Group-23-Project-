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

**7. Testing:**

**Unit Tests (RSpec):**
```bash
docker compose exec web bundle exec rspec
```

**Minitest:**
```bash
docker compose exec web bin/rails db:test:prepare test
```

**Behavior Tests (Cucumber):**
```bash
docker compose exec web bundle exec cucumber
```



| Feature Name | Primary Developer (Development) | Secondary Developer (Testing and Bugfix) | Notes |
| :--- | :--- | :--- | :--- |
| User Authentication | Ben | Kwok Chi Him Jacco | Sign up, sign in, sign out flows |
| Email Verification | Ben, MOK Yik Him Hubert | Jacco, Ng Hei Yi Melody | School-email verification (CUHK domains) |
| User Profiles | Ben | Jacco, Hubert | View and edit user profiles |
| Products Publishing | Alice | Jacco, Hubert | Create, edit, delete, and publish product listings |
| Searching | Jacco | Hubert | Fuzzy search, category/status filtering, sorting |
| Product Likes | Chan Yat Yin Alice | Jacco, Hubert, Ng Hei Yi Melody | Like/unlike products and view liked products |
| Notifications | Ben | Jacco, Hubert | Real-time notifications via Turbo Streams & Action Cable |
| Messaging | Ben | Jacco, Hubert | Buyer-seller conversations with message management |
| Orders & Checkout | Ben | Jacco | Stripe-based escrow payment flow |
| Data initialization | Alice, Ng Hei Yi Melody | - | Database seeds with 8 users, 19 products across all categories, and likes |
| Delay use testing | Hubert, Ng Hei Yi Meldoy | Alice | Daily normal usage test |
| Website deployment | Hubert | - | deploy the website to heroku |
| handle http error code | - | Alice, Ng Hei Yi Melody | Fixed lint errors, added 404 error handling |
| Fraud Detection | Hubert | - | Find suspicious products and messages |
| Admin Moderation | Hubert | Ng Hei Yi Melody | Added Admin access and Admin Dashboard to check suspicious products and messages |
| PWA Support | Alice | - | Manifest, service worker, basic offline behaviour |
| Demo Video Editing | Ng Hei Yi Melody | Alice | Screen shooting and editing the demo video with narration and subtitle added |

 **SimpleCov Report**
 ![SimpleCov Screenshot](./Screenshot%202026-04-14%20233457.png)