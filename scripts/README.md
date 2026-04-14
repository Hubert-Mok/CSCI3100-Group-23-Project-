# Bulk Post Listings Script

This folder contains a Python Playwright script to post 10 listings in one run to:

- https://cuhk-marketplace-2219fdf8f1c3.herokuapp.com/

## Files

- `bulk_post_items.py`: automation script
- `items_to_post.json`: 10-item input dataset
- `artifacts/`: failure screenshots generated during runs

## Setup

1. Install Python packages:

```bash
python3 -m pip install playwright
python3 -m playwright install chromium
```

2. (Recommended) set credentials with environment variables:

```bash
export MARKETPLACE_EMAIL="your_email@link.cuhk.edu.hk"
export MARKETPLACE_PASSWORD="your_password"
```

Notes:
- The script has hardcoded fallback credentials for convenience.
- Environment variables override hardcoded values.

## Run

Headed mode (recommended first):

```bash
python3 scripts/bulk_post_items.py
```

Headless mode:

```bash
HEADLESS=true python3 scripts/bulk_post_items.py
```

## Input format

Each item in `items_to_post.json` uses:

- `title` (string)
- `description` (string)
- `price` (number)
- `category` (must match site category exactly)
- `status` (kept for data completeness)
- `listing_type` (`sale` or `gift`)
- `image_path` (relative or absolute file path)

## Validation tips

- Test once with 1 item first by temporarily keeping only one object in `items_to_post.json`.
- Then restore 10 items and run the full batch.
- If an item fails, check console output and `scripts/artifacts/failed_item_*.png`.
