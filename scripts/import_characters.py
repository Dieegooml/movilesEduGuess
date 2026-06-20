#!/usr/bin/env python3
"""
EduGuess Character Bulk Importer
==================================
Fetches character data from Wikipedia + Wikidata and maps it to EduGuess
boolean attributes. Optionally uses Gemini AI for remaining attributes.

Usage:
  # Process a list of names
  python3 scripts/import_characters.py --names "Goku,Naruto,Batman" -o characters.json

  # With Gemini for better accuracy (uses your existing API key)
  python3 scripts/import_characters.py --names "Goku,Naruto" --gemini-key "AIzaSy..."

  # From a text file (one name per line)
  python3 scripts/import_characters.py --file characters.txt --gemini-key "AIzaSy..."

  # Discover characters from a Wikipedia category
  python3 scripts/import_characters.py --discover "Peruvian_male_writers" -o peruvian_writers.json

  # Discover + Gemini
  python3 scripts/import_characters.py --discover "Fictional_characters_from_anime_series" --gemini-key "AIzaSy..." -o anime.json

Examples:
  python3 scripts/import_characters.py --names "Mario Vargas Llosa,Paolo Guerrero,Goku" --gemini-key "AIzaSy..." -o output.json
  python3 scripts/import_characters.py --discover "Peruvian_sportspeople" -o peruvian_sports.json
"""

import argparse
import copy
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Any, Optional

ALL_ATTRIBUTES: list[str] = [
    "isReal", "isFictional", "isHistorical", "isAlive",
    "isFromMovie", "isFromBook", "isFromTV", "isFromVideoGame",
    "isFromComic", "isFromMythology", "isFromAnime",
    "isFromPeru", "isLatinAmerican",
    "isFromMarvel", "isFromDC", "isFromDisney", "isFromStarWars",
    "isHuman", "isAnimal", "isMagical", "isSuperhero", "isVillain", "isRoyalty",
    "hasHair", "wearsGlasses", "hasBeard", "isFemale", "isChild", "isElderly",
    "usesMagic", "usesTechnology", "hasSuperpowers", "isStrong", "isSmart",
    "hasWeapon", "drivesVehicle", "wearsCape", "wearsHat",
    "isAthlete", "isMusician", "isPolitician", "isWriter", "isScientist", "isReligious",
]

WIKI_API = "https://en.wikipedia.org/w/api.php"
WIKI_REST = "https://en.wikipedia.org/api/rest_v1"
USER_AGENT = "EduGuessImporter/1.0 (edu-guess-app)"

# -- Helpers ----------------------------------------------------------------

def api_get(url: str, retries: int = 3) -> Optional[dict[str, Any]]:
    """HTTP GET with retry and exponential backoff."""
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
            with urllib.request.urlopen(req, timeout=20) as resp:
                return json.loads(resp.read())
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return None
            if e.code == 429 and attempt < retries - 1:
                wait = (attempt + 1) * 3
                print(f"  [RATE-LIMITED] retrying in {wait}s...")
                time.sleep(wait)
                continue
            # Check if it's a search-not-found or similar
            if e.code in (400, 405, 500):
                return None
            if attempt == retries - 1:
                print(f"  [WARN] HTTP {e.code}: {url[:80]}...")
                return None
        except Exception as e:
            if attempt == retries - 1:
                print(f"  [WARN] API error: {e}")
                return None
            time.sleep((attempt + 1) * 2)
    return None


def wiki_action(params: dict[str, str]) -> Optional[dict[str, Any]]:
    params["format"] = "json"
    url = f"{WIKI_API}?{urllib.parse.urlencode(params)}"
    return api_get(url)


def rest_get(path: str) -> Optional[dict[str, Any]]:
    url = f"{WIKI_REST}{path}"
    return api_get(url)


# -- Wikipedia data fetching ------------------------------------------------

def rest_summary(title: str) -> Optional[dict[str, Any]]:
    """Fetch page summary via REST API, falling back to action API."""
    result = rest_get(f"/page/summary/{urllib.parse.quote(title)}")
    if result and not result.get("missing"):
        return result
    data = wiki_action({
        "action": "query",
        "prop": "extracts",
        "exintro": 1,
        "explaintext": 1,
        "titles": title,
    })
    if data:
        pages = data.get("query", {}).get("pages", {})
        for pid, page in pages.items():
            if pid != "-1" and page.get("extract"):
                return {
                    "title": page.get("title", title),
                    "extract": page.get("extract", ""),
                    "pageid": pid,
                }
    return None


def fetch_wikipedia_data(name: str) -> Optional[dict[str, Any]]:
    """Fetch extract, categories, and Wikidata ID for a character."""
    summary = rest_summary(name)
    if summary is None:
        search = wiki_action({
            "action": "query",
            "list": "search",
            "srsearch": name,
            "srlimit": 3,
        })
        if search:
            for r in search.get("query", {}).get("search", []):
                summary = rest_summary(r["title"])
                if summary:
                    break

    if summary is None:
        return None

    title = summary.get("title", name)
    extract = summary.get("extract", "")
    page_id = summary.get("pageid")

    categories = []
    cat_data = wiki_action({
        "action": "query",
        "prop": "categories",
        "pageids": page_id,
        "cllimit": "max",
    })
    if cat_data:
        pages = cat_data.get("query", {}).get("pages", {})
        if pages:
            page = next(iter(pages.values()))
            categories = [c["title"] for c in page.get("categories", [])]

    wd_id = None
    pp_data = wiki_action({
        "action": "query",
        "prop": "pageprops",
        "pageids": page_id,
        "ppprop": "wikibase_item",
    })
    if pp_data:
        pages = pp_data.get("query", {}).get("pages", {})
        if pages:
            pp = next(iter(pages.values())).get("pageprops", {})
            wd_id = pp.get("wikibase_item")

    return {
        "title": title,
        "extract": extract,
        "categories": categories,
        "wikidata_id": wd_id,
        "summary": summary,
    }


def fetch_wikidata_entity(wd_id: str) -> Optional[dict[str, Any]]:
    """Fetch structured claims from Wikidata."""
    url = f"https://www.wikidata.org/wiki/Special:EntityData/{wd_id}.json"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read())
            return data.get("entities", {}).get(wd_id, {})
    except Exception:
        return None


# -- Rule-based attribute mapping -------------------------------------------

def apply_rules(page: dict[str, Any]) -> dict[str, Optional[bool]]:
    """Apply category-based rules to determine attribute values."""
    result: dict[str, Optional[bool]] = {a: None for a in ALL_ATTRIBUTES}

    categories = page.get("categories", [])
    categories_text = " ".join(c.lower() for c in categories)
    extract = page.get("extract", "").lower()
    title = page.get("title", "").lower()

    # ── Fiction / Reality ──
    if re.search(r"fictional", categories_text):
        result["isFictional"] = True
        result["isReal"] = False
    elif re.search(r"living people|real people", categories_text):
        result["isReal"] = True
        result["isFictional"] = False
    else:
        has_fiction_cat = bool(re.search(r"fictional characters|fiction", categories_text))
        has_real_cat = bool(re.search(r"(living|deceased|century|born|died)", categories_text))
        if not has_fiction_cat and has_real_cat:
            result["isReal"] = True
            result["isFictional"] = False

    # ── Alive / Historical ──
    if re.search(r"living people", categories_text):
        result["isAlive"] = True
    if re.search(r"\d{4} (births|deaths)", categories_text):
        result["isHistorical"] = True
    elif re.search(r"century|ancient|historical", categories_text):
        result["isHistorical"] = True

    # ── Origin / Nationality ──
    if re.search(r"peruvian", categories_text):
        result["isFromPeru"] = True
        result["isLatinAmerican"] = True
    elif re.search(r"(mexican|argentine|brazilian|chilean|colombian|"
                   r"ecuadorian|venezuelan|cuban|bolivian)", categories_text):
        result["isLatinAmerican"] = True

    # ── Media Origin (strict: only match known category patterns) ──
    if re.search(r"american (film|motion picture)|film (character|actor)", categories_text):
        result["isFromMovie"] = True
    if re.search(r"television series|tv series|television characters", categories_text):
        result["isFromTV"] = True
    if re.search(r"(novel|book|literary|writer|author)", categories_text):
        result["isFromBook"] = True
    if re.search(r"video game", categories_text):
        result["isFromVideoGame"] = True
    if re.search(r"comics? characters|graphic novel|superhero comics?", categories_text):
        result["isFromComic"] = True
    if re.search(r"anime|manga", categories_text):
        result["isFromAnime"] = True
    if re.search(r"mytholog|legend", categories_text):
        result["isFromMythology"] = True

    # ── Franchise ──
    if re.search(r"marvel comics|marvel characters", categories_text):
        result["isFromMarvel"] = True
    if re.search(r"dc comics|dc characters", categories_text):
        result["isFromDC"] = True
    if re.search(r"disney", categories_text):
        result["isFromDisney"] = True
    if re.search(r"star wars", categories_text):
        result["isFromStarWars"] = True

    # ── Nature ──
    if re.search(r"\bhuman\b", categories_text) and not re.search(r"superhuman", categories_text):
        result["isHuman"] = True
    if re.search(r"\b(animal|mammal|bird|dog|cat)\b", categories_text):
        result["isAnimal"] = True
    if re.search(r"magical|wizard|sorcerer|witch", categories_text):
        result["isMagical"] = True
    if re.search(r"superhero", categories_text):
        result["isSuperhero"] = True
    if re.search(r"(super)?villain|antagonist", categories_text):
        result["isVillain"] = True
    if re.search(r"royalty|monarch|king|queen|prince|princess", categories_text):
        result["isRoyalty"] = True

    # ── Appearance ──
    if re.search(r"female characters|women", categories_text):
        result["isFemale"] = True
    if re.search(r"child characters|children", categories_text):
        result["isChild"] = True
    if re.search(r"elderly|older", categories_text):
        result["isElderly"] = True
    if re.search(r"bald", categories_text):
        result["hasHair"] = False
    if re.search(r"\bglasses\b|eyeglasses", categories_text):
        result["wearsGlasses"] = True
    if re.search(r"\bbeard\b|mustache", categories_text):
        result["hasBeard"] = True

    # ── Equipment ──
    if re.search(r"\bweapon\b|\bsword\b|\bgun\b|archer", categories_text):
        result["hasWeapon"] = True
    if re.search(r"\bvehicle\b|motorcycle|\bcar\b", categories_text):
        result["drivesVehicle"] = True
    if re.search(r"\bcape\b|\bcloak\b", categories_text):
        result["wearsCape"] = True
    if re.search(r"\bhat\b|headgear|helmet", categories_text):
        result["wearsHat"] = True

    # ── Abilities ──
    if re.search(r"superpower|superhuman", categories_text):
        result["hasSuperpowers"] = True
    if re.search(r"technology|scientist|robot|cyborg", categories_text):
        result["usesTechnology"] = True
    if re.search(r"intelligen|genius", categories_text):
        result["isSmart"] = True
    if re.search(r"fighter|martial artist|strong", categories_text):
        result["isStrong"] = True
    if re.search(r"magic users|spell", categories_text):
        result["usesMagic"] = True

    # ── Role / Occupation ──
    if re.search(r"(football|soccer|basketball|baseball|tennis|athlete|sport|boxer|player)",
                 categories_text):
        result["isAthlete"] = True
    if re.search(r"(singer|musician|guitarist|pianist|composer|songwriter|rapper)",
                 categories_text):
        result["isMusician"] = True
    if re.search(r"(politician|president|prime minister|senator|congress|governor)",
                 categories_text):
        result["isPolitician"] = True
    if re.search(r"(writer|author|novelist|poet|playwright|essayist|journalist)",
                 categories_text):
        result["isWriter"] = True
    if re.search(r"(scientist|physicist|chemist|biologist|inventor|researcher|mathematician)",
                 categories_text):
        result["isScientist"] = True
    if re.search(r"(religious|pope|priest|pastor|monk|nun|saint|clergy|missionary)",
                 categories_text):
        result["isReligious"] = True

    # ── Extract-based override (only for clear fiction) ──
    if result["isFictional"] is None and result["isReal"] is None:
        if re.search(r"fictional character|is a fictional", extract):
            result["isFictional"] = True
            result["isReal"] = False

    return result


# Wikidata IDs for mapping
# P31 (instance of) -> attribute mappings
P31_MAP: dict[str, list[tuple[str, bool]]] = {
    # Real / Base
    "Q5": [("isHuman", True), ("isReal", True), ("isFictional", False)],
    "Q215627": [("isHuman", True), ("isReal", True)],
    "Q16521": [("isAnimal", True)],
    "Q729": [("isAnimal", True)],
    # Fictional (general)
    "Q61895": [("isFictional", True), ("isReal", False)],
    "Q95074": [("isFictional", True), ("isHuman", True), ("isReal", False)],
    "Q15632617": [("isFictional", True), ("isHuman", True), ("isReal", False)],
    "Q21070568": [("isFictional", True), ("isAnimal", True), ("isReal", False)],
    "Q1114461": [("isFictional", True), ("isFromComic", True), ("isReal", False)],
    # Fictional by medium
    "Q15773347": [("isFictional", True), ("isFromMovie", True), ("isReal", False)],
    "Q15773317": [("isFictional", True), ("isFromTV", True), ("isReal", False)],
    "Q15711870": [("isFictional", True), ("isReal", False)],
    "Q80447738": [("isFictional", True), ("isFromAnime", True), ("isReal", False)],
    "Q87576284": [("isFictional", True), ("isFromComic", True), ("isFromAnime", True), ("isReal", False)],
    "Q28020127": [("isFictional", True), ("isHuman", True), ("isReal", False)],
    # Fictional subtypes
    "Q15944511": [("isFictional", True), ("isSuperhero", True), ("isReal", False)],
    "Q156326": [("isFictional", True), ("isVillain", True), ("isReal", False)],
    "Q15184295": [("isFictional", True), ("isRoyalty", True), ("isReal", False)],
    "Q23931755": [("isFictional", True), ("isChild", True), ("isReal", False)],
    "Q48789194": [("isFictional", True), ("isElderly", True), ("isReal", False)],
    # Mythological / Magical
    "Q229886": [("isFromMythology", True), ("isFictional", True), ("isReal", False)],
    "Q186015": [("isMagical", True), ("isFictional", True), ("isReal", False)],
    # Superhero
    "Q188451": [("isSuperhero", True), ("isFictional", True)],
    # Literary / mythological
    "Q3658341": [("isFictional", True), ("isFromBook", True), ("isReal", False)],
    "Q6439708": [("isFictional", True), ("isHuman", True), ("isReal", False)],
    "Q719506": [("isFictional", True), ("isMagical", True), ("isReal", False)],
    "Q76450109": [("isFictional", True), ("isReal", False)],
}

# P27 (country of citizenship) -> isFromPeru / isLatinAmerican
LATAM_COUNTRIES = {"Q419", "Q96", "Q155", "Q414", "Q733", "Q77", "Q79",
                   "Q55", "Q881", "Q241", "Q774", "Q118", "Q784", "Q750",
                   "Q189", "Q786", "Q804", "Q783", "Q736", "Q801"}

# P106 (occupation) -> attribute hints
OCCUPATION_HINTS: dict[str, list[tuple[str, bool]]] = {
    "Q3391743": [("isFromMovie", True)],   # actor
    "Q2526255": [("isFromMovie", True)],   # film director
    "Q10855167": [("isFromMovie", True)],  # film producer
    "Q10798782": [("isFromTV", True)],     # television actor
    "Q36180": [("isFromBook", True)],      # writer
    "Q6625963": [("isFromTV", True)],      # television presenter
    "Q483501": [("isFromBook", True)],     # poet
    "Q5716684": [("isFromBook", True)],    # novelist
    "Q214917": [("isFromBook", True)],     # playwright
    "Q1930187": [("isFromComic", True)],   # comic writer
    "Q1280930": [("isFromComic", True)],   # comic book writer
    "Q1047104": [("isFromBook", True)],    # children's writer
    "Q245068": [("isFromComic", True)],    # comic artist
    "Q1281618": [("isFromVideoGame", True)], # video game designer
    "Q1734662": [("isFromVideoGame", True)], # video game developer
    "Q18536029": [("isFromVideoGame", True)], # voice actor in video game
    "Q2405480": [("isFromVideoGame", True)], # video game programmer
    "Q82955": [("isHistorical", True)],    # politician
    "Q625994": [("isRoyalty", True)],      # monarch
    "Q16707842": [("isRoyalty", True)],    # member of royalty
    "Q189290": [("isSmart", True)],        # scientist
    "Q901": [("isSmart", True)],           # scientist (alt)
    "Q81096": [("isSmart", True)],         # engineer
    "Q188094": [("isSmart", True)],        # economist
    "Q1622272": [("isSmart", True)],       # university teacher
    "Q1235853": [("isSmart", True)],       # mathematician
    "Q169470": [("isSmart", True)],        # inventor
    "Q49757": [("isStrong", True)],        # soldier/military
    "Q2066131": [("isStrong", True)],      # martial artist
    "Q11124885": [("isStrong", True)],     # martial artist (alt)
    "Q6503241": [("isStrong", True)],      # basketball player
    "Q937857": [("isStrong", True)],       # football player
    "Q188784": [("isSuperhero", True)],    # superhero (occupation)
    "Q3190387": [("isStrong", True)],      # vigilante
    "Q484876": [("isSmart", True)],        # CEO / business executive
    "Q43845": [("isSmart", True)],         # businessperson
    "Q12362622": [("isSmart", True)],      # philanthropist
}

# P1434 (franchise) -> franchise attributes
FRANCHISE_MAP: dict[str, list[tuple[str, bool]]] = {
    "Q324451": [("isFromStarWars", True)],
    "Q214282": [("isFromMarvel", True)],
    "Q8470": [("isFromDC", True)],
    "Q220659": [("isFromDC", True)],
}

# P1080 (from narrative universe) -> franchise
UNIVERSE_MAP: dict[str, list[tuple[str, bool]]] = {
    "Q214282": [("isFromMarvel", True)],
    "Q8470": [("isFromDC", True)],
    "Q1152150": [("isFromDC", True)],
}

def extract_wikidata_claims(wd_entity: dict[str, Any]) -> dict[str, Optional[bool]]:
    """Extract attributes from Wikidata claims using extensive mappings."""
    result: dict[str, Optional[bool]] = {}
    claims = wd_entity.get("claims", {})

    # P31 (instance of) - most reliable classification
    for claim in claims.get("P31", []):
        val = (claim.get("mainsnak", {})
               .get("datavalue", {})
               .get("value", {}))
        qid = val.get("id") if isinstance(val, dict) else None
        if qid and qid in P31_MAP:
            for attr, v in P31_MAP[qid]:
                result[attr] = v

    # P21 (gender)
    for claim in claims.get("P21", []):
        val = (claim.get("mainsnak", {})
               .get("datavalue", {})
               .get("value", {}))
        qid = val.get("id") if isinstance(val, dict) else None
        if qid == "Q6581072":
            result["isFemale"] = True
        elif qid == "Q6581097":
            result["isFemale"] = False

    # P27 (country of citizenship)
    p27_ids = set()
    for claim in claims.get("P27", []):
        val = (claim.get("mainsnak", {})
               .get("datavalue", {})
               .get("value", {}))
        qid = val.get("id") if isinstance(val, dict) else None
        if qid:
            p27_ids.add(qid)
    if "Q419" in p27_ids:
        result["isFromPeru"] = True
        result["isLatinAmerican"] = True
    elif p27_ids & LATAM_COUNTRIES:
        result["isLatinAmerican"] = True

    # P569 + P570 (birth/death dates)
    p569 = claims.get("P569", [])
    p570 = claims.get("P570", [])
    if p569:
        result["isAlive"] = not bool(p570)
        if p570:
            result["isHistorical"] = True

    # P106 (occupation)
    for claim in claims.get("P106", []):
        val = (claim.get("mainsnak", {})
               .get("datavalue", {})
               .get("value", {}))
        qid = val.get("id") if isinstance(val, dict) else None
        if qid and qid in OCCUPATION_HINTS:
            for attr, v in OCCUPATION_HINTS[qid]:
                if result.get(attr) is None:
                    result[attr] = v

    # P1434 (franchise)
    for claim in claims.get("P1434", []):
        val = (claim.get("mainsnak", {})
               .get("datavalue", {})
               .get("value", {}))
        qid = val.get("id") if isinstance(val, dict) else None
        if qid and qid in FRANCHISE_MAP:
            for attr, v in FRANCHISE_MAP[qid]:
                result[attr] = v

    # P1080 (narrative universe)
    for claim in claims.get("P1080", []):
        val = (claim.get("mainsnak", {})
               .get("datavalue", {})
               .get("value", {}))
        qid = val.get("id") if isinstance(val, dict) else None
        if qid and qid in UNIVERSE_MAP:
            for attr, v in UNIVERSE_MAP[qid]:
                result[attr] = v

    # P144 (based on) -> could indicate book origin
    if claims.get("P144"):
        for attr in ["isFromBook"]:
            if result.get(attr) is None:
                result[attr] = True

    # P449 (original network) -> TV
    if claims.get("P449"):
        if result.get("isFromTV") is None:
            result["isFromTV"] = True

    return result


# -- Gemini classification --------------------------------------------------

GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

def classify_with_gemini(name: str, extract: str, uncertain_attrs: list[str],
                          api_key: str) -> dict[str, bool]:
    """Use Gemini to classify uncertain attributes based on Wikipedia extract."""
    if not extract:
        extract = name

    extract_clean = extract[:2000]

    prompt = (
        "You are an AI assistant for the EduGuess game. "
        "Given a character name and their Wikipedia description, "
        "classify the following boolean attributes as true or false. "
        f"Character: {name}\n\n"
        f"Wikipedia summary: {extract_clean}\n\n"
        f"Attributes to classify (only these): {', '.join(uncertain_attrs)}\n\n"
        "Rules:\n"
        "- isReal: real person, not fictional\n"
        "- isFictional: from fiction (movie, book, etc.)\n"
        "- isHistorical: lived in the past, historical figure\n"
        "- isAlive: currently alive\n"
        "- isFromPeru: Peruvian nationality/origin\n"
        "- isLatinAmerican: from Latin America\n"
        "- isHuman: human being\n"
        "- isAnimal: non-human animal\n"
        "- isMagical: magical being\n"
        "- isSuperhero, isVillain, isRoyalty: self-evident\n"
        "- isFemale: female character\n"
        "- isChild: child or young\n"
        "- isElderly: old/elderly\n"
        "- hasHair: has visible hair (default true for humans)\n"
        "- wearsGlasses, hasBeard, hasWeapon, drivesVehicle, wearsCape, wearsHat: self-evident\n"
        "- usesMagic, usesTechnology, hasSuperpowers, isStrong, isSmart: self-evident\n"
        "- isFromMovie, isFromBook, isFromTV, isFromVideoGame, isFromComic, "
        "isFromAnime, isFromMythology: origin media\n"
        "- isFromMarvel, isFromDC, isFromDisney, isFromStarWars: franchise\n\n"
        "Return ONLY valid JSON with NO markdown formatting, no code fences:\n"
        '{' + ', '.join(f'"{a}": true/false' for a in uncertain_attrs) + '}'
    )

    payload = {
        "contents": [{
            "parts": [{"text": prompt}]
        }],
        "generationConfig": {
            "temperature": 0.0,
            "responseMimeType": "application/json",
        }
    }

    url = f"{GEMINI_URL}?key={api_key}"
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            body = json.loads(resp.read())
        text = (body.get("candidates", [{}])[0]
                .get("content", {})
                .get("parts", [{}])[0]
                .get("text", "{}"))
        parsed = json.loads(text)
        result: dict[str, bool] = {}
        for attr in uncertain_attrs:
            if attr in parsed and isinstance(parsed[attr], bool):
                result[attr] = parsed[attr]
        return result
    except Exception as e:
        print(f"  [WARN] Gemini error for '{name}': {e}")
        return {}


# -- Main pipeline ----------------------------------------------------------

def apply_defaults(attrs: dict[str, Optional[bool]]) -> None:
    """Apply sensible defaults based on known attributes."""
    is_real = attrs.get("isReal")
    is_fictional = attrs.get("isFictional")
    is_human = attrs.get("isHuman")
    is_animal = attrs.get("isAnimal")

    # Real people are human and usually have hair
    if is_real == True:
        if is_human is None and is_animal is None:
            attrs["isHuman"] = True
            attrs["isAnimal"] = False
        if attrs.get("hasHair") is None:
            attrs["hasHair"] = True
        if attrs.get("isFictional") is None:
            attrs["isFictional"] = False

    # Fictional characters that are humanoid usually have hair
    if is_fictional == True:
        if is_human is None and is_animal is None:
            attrs["isHuman"] = True
        if attrs.get("hasHair") is None:
            attrs["hasHair"] = True
        if attrs.get("isReal") is None:
            attrs["isReal"] = False

    if attrs.get("isFromPeru") == True:
        attrs["isLatinAmerican"] = True


def process_character(name: str, gemini_key: Optional[str] = None) -> Optional[dict[str, Any]]:
    """Full pipeline: fetch Wikipedia → Wikidata → rules → defaults → Gemini."""
    page = fetch_wikipedia_data(name)
    if page is None:
        print(f"  [SKIP] '{name}': not found on Wikipedia")
        return None

    print(f"  [OK] '{page['title']}' (Wikidata: {page.get('wikidata_id', 'N/A')})")

    attrs: dict[str, Optional[bool]] = {a: None for a in ALL_ATTRIBUTES}

    if page.get("wikidata_id"):
        wd_entity = fetch_wikidata_entity(page["wikidata_id"])
        if wd_entity:
            wd_attrs = extract_wikidata_claims(wd_entity)
            for a in ALL_ATTRIBUTES:
                if wd_attrs.get(a) is not None:
                    attrs[a] = wd_attrs[a]

    rule_attrs = apply_rules(page)
    for a in ALL_ATTRIBUTES:
        if attrs[a] is None and rule_attrs.get(a) is not None:
            attrs[a] = rule_attrs[a]

    apply_defaults(attrs)

    if gemini_key and gemini_key.startswith("AIzaSy"):
        uncertain = [a for a in ALL_ATTRIBUTES if attrs[a] is None]
        if uncertain:
            print(f"    → Gemini classifying {len(uncertain)} uncertain attributes...")
            gemini_result = classify_with_gemini(
                page["title"], page.get("extract", ""), uncertain, gemini_key
            )
            for a, v in gemini_result.items():
                if v is not None:
                    attrs[a] = v

    final: dict[str, bool] = {}
    for a in ALL_ATTRIBUTES:
        final[a] = attrs[a] if attrs[a] is not None else False

    known = sum(1 for a in ALL_ATTRIBUTES if attrs[a] is not None)
    print(f"    → {known}/{len(ALL_ATTRIBUTES)} attributes determined")

    return {
        "name": page["title"],
        "image": "",
        "attributes": final,
    }


def discover_category(category: str) -> list[str]:
    """Get all page titles from a Wikipedia category."""
    print(f"Discovering pages in Category:{category}...")
    names: list[str] = []
    cmcontinue = None
    while True:
        params: dict[str, str] = {
            "action": "query",
            "list": "categorymembers",
            "cmtitle": f"Category:{category}",
            "cmlimit": "max",
            "cmtype": "page",
        }
        if cmcontinue:
            params["cmcontinue"] = cmcontinue
        data = wiki_action(params)
        if not data:
            break
        members = data.get("query", {}).get("categorymembers", [])
        for m in members:
            ns = m.get("ns", 0)
            if ns == 0:
                names.append(m["title"])
        cont = data.get("continue", {})
        cmcontinue = cont.get("cmcontinue")
        time.sleep(0.2)
        if not cmcontinue:
            break
    print(f"  Found {len(names)} pages in Category:{category}")
    return names


def main():
    parser = argparse.ArgumentParser(
        description="EduGuess character bulk importer from Wikipedia"
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--names", help="Comma-separated list of character names")
    group.add_argument("--file", help="Text file with one name per line")
    group.add_argument("--discover", help="Wikipedia category name to discover pages from")
    parser.add_argument("--gemini-key",
                        default=os.environ.get("GEMINI_API_KEY"),
                        help="Gemini API key (or set GEMINI_API_KEY env var)")
    parser.add_argument("-o", "--output", default="characters_output.json",
                        help="Output JSON file path")
    parser.add_argument("--force-fictional", action="store_true",
                        help="Force all characters as fictional (overrides auto-detection)")
    parser.add_argument("--force-real", action="store_true",
                        help="Force all characters as real people (overrides auto-detection)")
    parser.add_argument("--max-workers", type=int, default=2,
                        help="Max parallel workers (default: 2)")
    parser.add_argument("--rate-limit", type=float, default=1.5,
                        help="Seconds between requests (default: 1.5)")

    args = parser.parse_args()

    if args.names:
        names = [n.strip() for n in args.names.split(",") if n.strip()]
    elif args.file:
        with open(args.file) as f:
            names = [line.strip() for line in f if line.strip()]
    elif args.discover:
        names = discover_category(args.discover)

    if not names:
        print("No names to process.")
        sys.exit(1)

    print(f"\nProcessing {len(names)} characters (max {args.max_workers} parallel)...\n")

    results: list[dict[str, Any]] = []
    skipped: list[str] = []

    with ThreadPoolExecutor(max_workers=args.max_workers) as pool:
        futures = {
            pool.submit(process_character, name, args.gemini_key): name
            for name in names
        }
        for future in as_completed(futures):
            name = futures[future]
            try:
                result = future.result()
                if result:
                    results.append(result)
                else:
                    skipped.append(name)
            except Exception as e:
                print(f"  [ERROR] '{name}': {e}")
                skipped.append(name)
            time.sleep(args.rate_limit)

    if args.force_fictional:
        for r in results:
            r["attributes"]["isReal"] = False
            r["attributes"]["isFictional"] = True
    elif args.force_real:
        for r in results:
            r["attributes"]["isReal"] = True
            r["attributes"]["isFictional"] = False

    results.sort(key=lambda r: r["name"].lower())

    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)

    print(f"\n{'='*50}")
    print(f"Done! {len(results)} characters imported, {len(skipped)} skipped")
    if skipped:
        print(f"Skipped ({len(skipped)}): {', '.join(skipped[:10])}")
        if len(skipped) > 10:
            print(f"  ... and {len(skipped)-10} more")
    print(f"Output: {os.path.abspath(args.output)}")
    print(f"\nTo import into the app:")
    print(f"  1. Upload {args.output} to a public URL (e.g. https://gist.github.com)")
    print(f"  2. In the app: Settings → Admin → Import URL")
    print(f"  3. Paste the URL and tap 'Importar desde API'")


if __name__ == "__main__":
    main()
