#!/usr/bin/env python3
"""Adds new Swift files to the Xcode project's pbxproj."""

import re
import uuid
import sys

PBPROJ = "/Users/dieegooml/Downloads/EduGuess/EduGuess.xcodeproj/project.pbxproj"

NEW_FILES = [
    "CharacterListView.swift",
    "CharacterDetailView.swift",
]

def new_id():
    return uuid.uuid4().hex.upper()[:24]

with open(PBPROJ, 'r') as f:
    content = f.read()

# Build PBXFileReference entries
file_refs = {}
for fname in NEW_FILES:
    fid = new_id()
    entry = f'\t\t{fid} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {fname}; sourceTree = "<group>"; }};'
    file_refs[fname] = (fid, entry)

# Add to PBXFileReference section
content = content.replace(
    '/* End PBXFileReference section */',
    '\n'.join(e for _, e in file_refs.values()) + '\n/* End PBXFileReference section */'
)

# Build PBXBuildFile entries
build_file_entries = {}
for fname, (fid, _) in file_refs.items():
    bid = new_id()
    entry = f'\t\t{bid} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {fname} */; }};'
    build_file_entries[fname] = (bid, entry)

# Add to PBXBuildFile section
content = content.replace(
    '/* End PBXBuildFile section */',
    '\n'.join(e for _, e in build_file_entries.values()) + '\n/* End PBXBuildFile section */'
)

# Add file references to the Views PBXGroup
# Find the Views group and add file references
views_group_pattern = r'(\t\t[A-F0-9]{{24}} \/\* Views \*\/ = \{{\n.*?children = \(\n)(.*?)(\);\n.*?\};)'

def add_to_group(match):
    prefix = match.group(1)
    children = match.group(2)
    suffix = match.group(3)
    for fname, (fid, _) in file_refs.items():
        children += f'\t\t\t\t{fid} /* {fname} */,\n'
    return prefix + children + suffix

content = re.sub(views_group_pattern, add_to_group, content, count=1, flags=re.DOTALL)

# Add build files to Sources build phase
# Find the Sources build phase and add file references
sources_phase_pattern = r'(\t\t[A-F0-9]{{24}} \/\* Sources \*\/ = \{{\n.*?isa = PBXSourcesBuildPhase;\n.*?buildActionMask = [^;]+;\n.*?files = \(\n)(.*?)(\);\n.*?\};)'

def add_to_sources(match):
    prefix = match.group(1)
    files = match.group(2)
    suffix = match.group(3)
    for fname, (bid, _) in build_file_entries.items():
        files += f'\t\t\t\t{bid} /* {fname} in Sources */,\n'
    return prefix + files + suffix

content = re.sub(sources_phase_pattern, add_to_sources, content, count=1, flags=re.DOTALL)

with open(PBPROJ, 'w') as f:
    f.write(content)

print(f"Added {len(NEW_FILES)} files to project.")
for fname in NEW_FILES:
    print(f"  {fname} (ref: {file_refs[fname][0]}, build: {build_file_entries[fname][0]})")
