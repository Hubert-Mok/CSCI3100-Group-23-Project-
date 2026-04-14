#!/usr/bin/env python3
import json
import os
from pathlib import Path
from typing import Any, Dict, List

from playwright.sync_api import Page, TimeoutError as PlaywrightTimeoutError, sync_playwright

BASE_URL = "https://cuhk-marketplace-2219fdf8f1c3.herokuapp.com"
DATASET_PATH = Path(__file__).with_name("items_to_post.json")

# WARNING: hardcoded credentials are unsafe. Prefer environment variables.
DEFAULT_EMAIL = "1155214377@link.cuhk.edu.hk"
DEFAULT_PASSWORD = "Ss69966043!"


def load_items() -> List[Dict[str, Any]]:
    raw = json.loads(DATASET_PATH.read_text(encoding="utf-8"))
    if not isinstance(raw, list):
        raise ValueError("items_to_post.json must be an array of item objects.")
    if len(raw) < 10:
        raise ValueError("items_to_post.json must contain at least 10 items.")
    return raw[:10]


def sign_in(page: Page, email: str, password: str) -> None:
    page.goto(f"{BASE_URL}/sign_in", wait_until="domcontentloaded")
    page.get_by_label("Email").fill(email)
    page.get_by_label("Password").fill(password)
    page.get_by_role("button", name="Sign In").click()
    page.wait_for_timeout(800)
    if "/sign_in" in page.url:
        raise RuntimeError("Sign in failed. Check email/password or account status.")


def fill_listing_form(page: Page, item: Dict[str, Any], script_dir: Path) -> None:
    page.goto(f"{BASE_URL}/products/new", wait_until="domcontentloaded")

    page.get_by_label("Title").fill(str(item.get("title", "")))
    page.get_by_label("Category").select_option(label=str(item.get("category", "")))

    listing_type = str(item.get("listing_type", "sale")).lower()
    if listing_type == "gift":
        page.locator("#listing_type_gift").check()
    else:
        page.locator("#listing_type_sale").check()

    price = item.get("price", 0)
    price_value = "0" if listing_type == "gift" else str(int(price))
    page.get_by_label("Price (HKD)").fill(price_value)
    page.get_by_label("Description").fill(str(item.get("description", "")))

    image_path = Path(str(item.get("image_path", "")))
    if not image_path.is_absolute():
        image_path = (script_dir / image_path).resolve()
    if not image_path.exists():
        raise FileNotFoundError(f"Image not found: {image_path}")
    page.locator('input[name="product[thumbnail]"]').set_input_files(str(image_path))


def submit_listing(page: Page) -> None:
    page.get_by_role("button", name="Publish Listing").click()
    try:
        page.wait_for_url("**/products/*", timeout=10000)
    except PlaywrightTimeoutError:
        if "prevented this listing from being saved" in page.content():
            raise RuntimeError("Validation failed on listing form.")
        raise RuntimeError("Submit timed out without reaching listing page.")


def main() -> None:
    script_dir = Path(__file__).resolve().parent
    email = os.getenv("MARKETPLACE_EMAIL", DEFAULT_EMAIL)
    password = os.getenv("MARKETPLACE_PASSWORD", DEFAULT_PASSWORD)
    headless = os.getenv("HEADLESS", "false").lower() in {"1", "true", "yes"}

    items = load_items()
    artifacts_dir = script_dir / "artifacts"
    artifacts_dir.mkdir(exist_ok=True)

    success_count = 0
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=headless)
        context = browser.new_context()
        page = context.new_page()

        sign_in(page, email, password)

        for index, item in enumerate(items, start=1):
            title = str(item.get("title", f"item-{index}"))
            try:
                fill_listing_form(page, item, script_dir)
                submit_listing(page)
                success_count += 1
                print(f"[OK] {index}/10 posted: {title}")
            except Exception as exc:
                screenshot = artifacts_dir / f"failed_item_{index}.png"
                page.screenshot(path=str(screenshot), full_page=True)
                print(f"[FAIL] {index}/10 {title}: {exc}")
                print(f"       screenshot: {screenshot}")

        context.close()
        browser.close()

    print(f"Completed: {success_count}/10 listings posted successfully.")


if __name__ == "__main__":
    main()
