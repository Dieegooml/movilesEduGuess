#!/usr/bin/env python3
"""
EduGuess - Scraper + LLM Classifier
====================================
Scrapes character names from Wikipedia, classifies them into EduGuess
boolean attributes using OpenAI/Claude, and exports a JSON file for
import into the SwiftData database.

Usage:
    export OPENAI_API_KEY="sk-..."
    python3 scrape_and_classify.py --output characters.json
    python3 scrape_and_classify.py --output characters.json --limit 50
"""

import argparse
import json
import os
import sys
import time
from typing import Any

import requests

# ---------------------------------------------------------------------------
# Attribute pool (must match AttributeDefinition.swift exactly, plus new ones)
# ---------------------------------------------------------------------------
ALL_ATTRIBUTES = [
    # Identity
    "isReal", "isFictional", "isHistorical", "isAlive",
    # Origin
    "isFromMovie", "isFromBook", "isFromTV", "isFromVideoGame",
    "isFromComic", "isFromMythology", "isFromAnime",
    "isFromPeru", "isLatinAmerican",
    # Franchise
    "isFromMarvel", "isFromDC", "isFromDisney", "isFromStarWars",
    # Nature
    "isHuman", "isAnimal", "isMagical", "isSuperhero", "isVillain", "isRoyalty",
    # Appearance
    "hasHair", "wearsGlasses", "hasBeard", "isFemale", "isChild", "isElderly",
    # Abilities
    "usesMagic", "usesTechnology", "hasSuperpowers", "isStrong", "isSmart",
    # Items
    "hasWeapon", "drivesVehicle", "wearsCape", "wearsHat",
    # Role / Occupation
    "isAthlete", "isMusician", "isPolitician", "isWriter", "isScientist", "isReligious",
]

# ---------------------------------------------------------------------------
# Character sources (Wikipedia category pages)
# ---------------------------------------------------------------------------
SOURCES: list[dict[str, str | list[str]]] = [
    # Peruvian real people
    {"category": "Peruvian_writers",      "type": "peruvian_real"},
    {"category": "Peruvian_footballers",  "type": "peruvian_real"},
    {"category": "Peruvian_male_actors",  "type": "peruvian_real"},
    {"category": "Peruvian_female_actors","type": "peruvian_real"},
    {"category": "Peruvian_musicians",    "type": "peruvian_real"},
    {"category": "Peruvian_politicians",  "type": "peruvian_real"},
    {"category": "Peruvian_artists",      "type": "peruvian_real"},
    {"category": "Peruvian_scientists",   "type": "peruvian_real"},
    {"category": "Incas",                 "type": "peruvian_real"},
    # International – broadly known
    {"category": "DC_Comics_superheroes",             "type": "international"},
    {"category": "Marvel_Comics_superheroes",          "type": "international"},
    {"category": "Disney_animated_characters",         "type": "international"},
    {"category": "Star_Wars_characters",               "type": "international"},
    {"category": "The_Simpsons_characters",            "type": "international"},
    {"category": "Harry_Potter_characters",            "type": "international"},
    {"category": "Dragon_Ball_characters",             "type": "international"},
    {"category": "Nintendo_characters",                "type": "international"},
    {"category": "Super_Sentai_characters",            "type": "international"},
    {"category": "Pokémon_characters",                 "type": "international"},
    {"category": "Fairy_tale_characters",              "type": "international"},
    {"category": "Greek_mythology_characters",         "type": "international"},
    {"category": "Norse_mythology_characters",         "type": "international"},
]

WIKI_API = "https://en.wikipedia.org/w/api.php"
USER_AGENT = "EduGuess-Scraper/1.0 (educational project)"


# ---------------------------------------------------------------------------
# Wikipedia helpers
# ---------------------------------------------------------------------------

def wiki_request(params: dict[str, Any]) -> dict[str, Any]:
    params["format"] = "json"
    headers = {"User-Agent": USER_AGENT}
    resp = requests.get(WIKI_API, params=params, headers=headers, timeout=15)
    resp.raise_for_status()
    return resp.json()


def fetch_category_members(category: str, max_members: int = 50) -> list[str]:
    """Return page titles under a Wikipedia category."""
    titles: list[str] = []
    cmcontinue: str | None = None
    while len(titles) < max_members:
        params: dict[str, Any] = {
            "action": "query",
            "list": "categorymembers",
            "cmtitle": f"Category:{category}",
            "cmlimit": "50",
            "cmtype": "page",
        }
        if cmcontinue:
            params["cmcontinue"] = cmcontinue

        data = wiki_request(params)
        for m in data.get("query", {}).get("categorymembers", []):
            title: str = m["title"]
            if ":" not in title:  # skip subcategory pages
                titles.append(title)
                if len(titles) >= max_members:
                    return titles

        cont = data.get("continue", {})
        cmcontinue = cont.get("cmcontinue")
        if not cmcontinue:
            break
        time.sleep(0.3)
    return titles


def fetch_summary(title: str) -> str:
    """Get a short plain-text summary of a Wikipedia article."""
    params = {
        "action": "query",
        "prop": "extracts",
        "exintro": True,
        "explaintext": True,
        "titles": title,
        "redirects": 1,
    }
    data = wiki_request(params)
    pages = data.get("query", {}).get("pages", {})
    for page in pages.values():
        return page.get("extract", "") or ""
    return ""


# ---------------------------------------------------------------------------
# LLM classifier
# ---------------------------------------------------------------------------

LLM_MODEL = "gpt-4o-mini"  # cheap & fast – change as needed

SYSTEM_PROMPT = f"""Eres un clasificador de personajes. Recibes un nombre y una descripción,
y debes responder ÚNICAMENTE un JSON con los {len(ALL_ATTRIBUTES)} atributos booleanos.

Reglas:
- Usa SOLO true o false, sin explicaciones ni markdown.
- Si no hay suficiente información para un atributo, usa false.
- isReal = persona real histórica o viva; isFictional = personaje ficticio.
- isHistorical = figura histórica (fallecida hace décadas o siglos).
- isAlive = actualmente vivo (2026).
- Los atributos de franquicia (isFromMarvel, isFromDC, etc.) SOLO son true
  si el personaje pertenece oficialmente a esa franquicia.
- Los atributos de apariencia son sobre su apariencia TÍPICA/CONOCIDA.
- Para personajes peruanos: isFromPeru = true, isLatinAmerican = true.
- Para latinoamericanos no peruanos: isFromPeru = false, isLatinAmerican = true.

Atributos: {json.dumps(ALL_ATTRIBUTES)}

Ejemplo para "Mario Vargas Llosa":
{{"isReal":true,"isFictional":false,"isHistorical":false,"isAlive":false,
"isFromMovie":false,"isFromBook":true,"isFromTV":false,"isFromVideoGame":false,
"isFromComic":false,"isFromMythology":false,"isFromAnime":false,
"isFromPeru":true,"isLatinAmerican":true,
"isFromMarvel":false,"isFromDC":false,"isFromDisney":false,"isFromStarWars":false,
"isHuman":true,"isAnimal":false,"isMagical":false,"isSuperhero":false,
"isVillain":false,"isRoyalty":false,
"hasHair":true,"wearsGlasses":false,"hasBeard":false,"isFemale":false,
"isChild":false,"isElderly":true,
"usesMagic":false,"usesTechnology":false,"hasSuperpowers":false,
"isStrong":false,"isSmart":true,
"hasWeapon":false,"drivesVehicle":false,"wearsCape":false,"wearsHat":false}}"""


def classify_with_openai(name: str, summary: str) -> dict[str, bool] | None:
    """Send character info to OpenAI and parse returned JSON."""
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("ERROR: OPENAI_API_KEY environment variable not set.")
        sys.exit(1)

    user_msg = f"Personaje: {name}\nDescripción: {summary[:1500]}"

    payload = {
        "model": LLM_MODEL,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_msg},
        ],
        "temperature": 0.1,
        "max_tokens": 800,
    }
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }

    for attempt in range(3):
        try:
            resp = requests.post(
                "https://api.openai.com/v1/chat/completions",
                json=payload,
                headers=headers,
                timeout=30,
            )
            resp.raise_for_status()
            content = resp.json()["choices"][0]["message"]["content"].strip()
            # Strip markdown code fences if present
            if content.startswith("```"):
                content = content.split("\n", 1)[-1]
                content = content.rsplit("```", 1)[0].strip()

            parsed = json.loads(content)
            # Validate all keys present
            for attr in ALL_ATTRIBUTES:
                if attr not in parsed:
                    parsed[attr] = False
            return parsed
        except Exception as e:
            print(f"  LLM attempt {attempt + 1} failed: {e}")
            time.sleep(2)
    return None


# ---------------------------------------------------------------------------
# Main pipeline
# ---------------------------------------------------------------------------

def scrape_and_classify(
    output_path: str,
    limit: int = 200,
    max_per_source: int = 15,
) -> list[dict[str, Any]]:
    """Main pipeline: scrape → classify → export JSON."""
    results: list[dict[str, Any]] = []
    seen_names: set[str] = set()

    print(f"Scraping from {len(SOURCES)} Wikipedia categories...")

    for source in SOURCES:
        category: str = source["category"]
        src_type: str = source["type"]
        print(f"\n--- Category: {category} ({src_type}) ---")

        titles = fetch_category_members(category, max_members=max_per_source)
        print(f"  Found {len(titles)} pages")

        for title in titles:
            if len(results) >= limit:
                break
            if title in seen_names:
                continue
            seen_names.add(title)

            print(f"  Processing: {title}")
            summary = fetch_summary(title)
            if not summary:
                print(f"    No summary found, skipping")
                continue

            attrs = classify_with_openai(title, summary)
            if attrs is None:
                print(f"    LLM classification failed, skipping")
                continue

            results.append({
                "name": title,
                "image": "",
                "attributes": attrs,
                "_source": category,
                "_type": src_type,
            })
            print(f"    ✓ Classified successfully")

            # Rate limit: 1 request per second
            time.sleep(1.0)

        if len(results) >= limit:
            break

    # Write output
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)

    print(f"\n{'='*60}")
    print(f"Done! {len(results)} characters saved to {output_path}")

    # Print summary stats
    peruvian = sum(1 for r in results if r["attributes"].get("isFromPeru"))
    latin = sum(1 for r in results if r["attributes"].get("isLatinAmerican"))
    fictional = sum(1 for r in results if r["attributes"].get("isFictional"))
    real = sum(1 for r in results if r["attributes"].get("isReal"))
    print(f"  Peruvian: {peruvian} | Latin American: {latin}")
    print(f"  Fictional: {fictional} | Real: {real}")

    return results


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="EduGuess character scraper + classifier")
    parser.add_argument(
        "--output", "-o",
        default="characters.json",
        help="Output JSON file path (default: characters.json)",
    )
    parser.add_argument(
        "--limit", "-l",
        type=int,
        default=200,
        help="Maximum number of characters to collect (default: 200)",
    )
    parser.add_argument(
        "--per-source",
        type=int,
        default=15,
        help="Max characters per Wikipedia category (default: 15)",
    )
    args = parser.parse_args()

    scrape_and_classify(
        output_path=args.output,
        limit=args.limit,
        max_per_source=args.per_source,
    )
