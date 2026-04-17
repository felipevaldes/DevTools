"""
Firefox configuration: export/import extensions and bookmarks.
"""

import json
import re
import shutil
import sqlite3
from datetime import datetime
from pathlib import Path
from typing import Optional

from . import config
from .logger import (
    console,
    print_success,
    print_warning,
    print_error,
    print_info,
    print_table,
    changes_log,
    create_progress,
)
from .utils import (
    run_command,
    ensure_directory,
    download_file,
)


def find_default_profile() -> Optional[Path]:
    """Find the default Firefox profile directory."""
    profiles_ini = config.FIREFOX_PROFILE_DIR / "profiles.ini"
    
    if not profiles_ini.exists():
        print_warning("Firefox profiles.ini not found")
        return None
    
    content = profiles_ini.read_text()
    
    # Parse all sections
    sections = {}
    current_section = None
    
    for line in content.splitlines():
        line = line.strip()
        
        if line.startswith("[") and line.endswith("]"):
            current_section = line[1:-1]
            sections[current_section] = {}
        elif "=" in line and current_section:
            key, value = line.split("=", 1)
            sections[current_section][key] = value
    
    # First, check Install section for Default profile
    install_default = None
    for section_name, section_data in sections.items():
        if section_name.startswith("Install"):
            install_default = section_data.get("Default")
            break
    
    # If Install default exists, find the matching profile
    if install_default:
        for section_name, section_data in sections.items():
            if section_name.startswith("Profile"):
                profile_path = section_data.get("Path")
                profile_name = section_data.get("Name")
                if profile_path == install_default or profile_name == install_default:
                    profile_dir = config.FIREFOX_PROFILE_DIR / profile_path
                    if profile_dir.exists():
                        return profile_dir
    
    # Fallback: Look for profile with Default=1
    for section_name, section_data in sections.items():
        if section_name.startswith("Profile") and section_data.get("Default") == "1":
            profile_path = section_data.get("Path")
            if profile_path:
                profile_dir = config.FIREFOX_PROFILE_DIR / profile_path
                if profile_dir.exists():
                    return profile_dir
    
    # Final fallback: Try to find any profile with .default-release suffix
    for profile_dir in config.FIREFOX_PROFILE_DIR.iterdir():
        if profile_dir.is_dir() and ".default-release" in profile_dir.name:
            return profile_dir
    
    print_warning("Could not find default Firefox profile")
    return None


def export_firefox() -> None:
    """Export Firefox extensions and bookmarks."""
    profile_dir = find_default_profile()
    
    if not profile_dir:
        print_error("No Firefox profile found. Is Firefox installed?")
        return
    
    print_info(f"Using Firefox profile: {profile_dir.name}")
    
    ensure_directory(config.FIREFOX_CONFIG_DIR)
    
    # Export extensions
    extensions = _export_extensions(profile_dir)
    if extensions:
        extensions_file = config.FIREFOX_CONFIG_DIR / "extensions.json"
        with open(extensions_file, "w") as f:
            json.dump(extensions, f, indent=2)
        print_success(f"Exported {len(extensions)} extensions to extensions.json")
    
    # Export bookmarks
    bookmarks = _export_bookmarks(profile_dir)
    if bookmarks:
        bookmarks_file = config.FIREFOX_CONFIG_DIR / "bookmarks.json"
        with open(bookmarks_file, "w") as f:
            json.dump(bookmarks, f, indent=2)
        print_success(f"Exported {len(bookmarks)} bookmarks to bookmarks.json")
    
    # Create summary
    _create_firefox_manifest(extensions, bookmarks)


def _export_extensions(profile_dir: Path) -> list[dict]:
    """Export installed extensions from extensions.json."""
    extensions_json = profile_dir / "extensions.json"
    
    if not extensions_json.exists():
        print_warning("extensions.json not found - no extensions to export")
        return []
    
    with open(extensions_json) as f:
        data = json.load(f)
    
    extensions = []
    
    for addon in data.get("addons", []):
        # Skip system addons and themes
        addon_type = addon.get("type", "")
        if addon_type in ("theme", "dictionary", "locale"):
            continue
        
        # Skip built-in addons
        if addon.get("location") == "app-system-defaults":
            continue
        
        ext_info = {
            "id": addon.get("id", ""),
            "name": addon.get("defaultLocale", {}).get("name", addon.get("id", "")),
            "version": addon.get("version", ""),
            "description": addon.get("defaultLocale", {}).get("description", ""),
            "homepage": addon.get("defaultLocale", {}).get("homepageURL", ""),
            "enabled": addon.get("active", False),
        }
        
        # Try to get Mozilla addon URL
        source_uri = addon.get("sourceURI") or ""
        if source_uri and "addons.mozilla.org" in source_uri:
            ext_info["install_url"] = source_uri
        
        extensions.append(ext_info)
    
    return extensions


def _export_bookmarks(profile_dir: Path) -> list[dict]:
    """Export bookmarks from places.sqlite."""
    places_db = profile_dir / "places.sqlite"
    
    if not places_db.exists():
        print_warning("places.sqlite not found - no bookmarks to export")
        return []
    
    # Make a copy of the database to avoid locking issues
    temp_db = profile_dir / "places_temp.sqlite"
    shutil.copy2(places_db, temp_db)
    
    bookmarks = []
    
    try:
        conn = sqlite3.connect(temp_db)
        cursor = conn.cursor()
        
        # Query bookmarks
        cursor.execute("""
            SELECT b.id, b.title, p.url, b.parent, b.position, b.type
            FROM moz_bookmarks b
            LEFT JOIN moz_places p ON b.fk = p.id
            WHERE b.type IN (1, 2)  -- 1=bookmark, 2=folder
            ORDER BY b.parent, b.position
        """)
        
        rows = cursor.fetchall()
        
        # Build bookmark tree
        items_by_id = {}
        root_items = []
        
        for row in rows:
            item_id, title, url, parent_id, position, item_type = row
            
            item = {
                "id": item_id,
                "title": title or "",
                "type": "folder" if item_type == 2 else "bookmark",
                "parent_id": parent_id,
            }
            
            if url:
                item["url"] = url
            
            items_by_id[item_id] = item
        
        # Organize into tree (simplified - just flat list with parent refs)
        for item in items_by_id.values():
            # Skip root folders (menu, toolbar, unfiled, mobile)
            if item["parent_id"] in (1, 2, 3, 4, 5, 6):
                bookmarks.append(item)
            elif item["parent_id"] in items_by_id:
                parent = items_by_id[item["parent_id"]]
                if "children" not in parent:
                    parent["children"] = []
                parent["children"].append(item)
        
        conn.close()
    
    except sqlite3.Error as e:
        print_error(f"Error reading bookmarks database: {e}")
    
    finally:
        temp_db.unlink(missing_ok=True)
    
    return bookmarks


def _create_firefox_manifest(extensions: list, bookmarks: list) -> None:
    """Create a manifest file with Firefox export summary."""
    manifest = config.FIREFOX_CONFIG_DIR / "manifest.txt"
    
    with open(manifest, "w") as f:
        f.write("# Firefox Configuration Export\n")
        f.write(f"# Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        
        f.write("## Extensions\n")
        for ext in extensions:
            f.write(f"  - {ext['name']} ({ext['id']})\n")
        
        f.write(f"\n## Bookmarks: {len(bookmarks)} items\n")
    
    print_info(f"Created manifest: {manifest}")


def configure_firefox() -> None:
    """Configure Firefox with exported settings."""
    # Check if Firefox config exists
    if not config.FIREFOX_CONFIG_DIR.exists():
        print_warning("No Firefox configuration found")
        print_info("Run 'devtools export-firefox' first to export settings")
        return
    
    # Install extensions using policies.json
    extensions_file = config.FIREFOX_CONFIG_DIR / "extensions.json"
    if extensions_file.exists():
        _setup_firefox_policies(extensions_file)
    
    # Import bookmarks
    bookmarks_file = config.FIREFOX_CONFIG_DIR / "bookmarks.json"
    if bookmarks_file.exists():
        _import_bookmarks(bookmarks_file)
    
    changes_log.log("FIREFOX", "Configured Firefox", str(config.FIREFOX_CONFIG_DIR))


def _setup_firefox_policies(extensions_file: Path) -> None:
    """Set up Firefox policies for extension installation."""
    with open(extensions_file) as f:
        extensions = json.load(f)
    
    if not extensions:
        return
    
    # Create policies.json for Firefox
    # This works for Firefox ESR and system-wide installations
    policies_dir = Path("/etc/firefox/policies")
    policies_file = policies_dir / "policies.json"
    
    # Build extension install list
    install_urls = []
    for ext in extensions:
        if "install_url" in ext:
            install_urls.append(ext["install_url"])
        elif ext.get("id"):
            # Try to construct Mozilla addon URL
            addon_url = f"https://addons.mozilla.org/firefox/downloads/latest/{ext['id']}/latest.xpi"
            install_urls.append(addon_url)
    
    policies = {
        "policies": {
            "ExtensionSettings": {
                "*": {
                    "installation_mode": "allowed"
                }
            },
            "Extensions": {
                "Install": install_urls
            }
        }
    }
    
    # Write policies (requires sudo)
    try:
        run_command(["mkdir", "-p", str(policies_dir)], sudo=True)
        
        # Write to temp file then move
        temp_file = Path("/tmp/firefox_policies.json")
        with open(temp_file, "w") as f:
            json.dump(policies, f, indent=2)
        
        run_command(["cp", str(temp_file), str(policies_file)], sudo=True)
        temp_file.unlink()
        
        print_success(f"Created Firefox policies for {len(install_urls)} extensions")
        print_info("Extensions will be installed on next Firefox launch")
        
        changes_log.log("FIREFOX", "Created policies.json", str(policies_file))
    
    except Exception as e:
        print_warning(f"Could not create system policies: {e}")
        print_info("Extensions need to be installed manually from addons.mozilla.org")


def _import_bookmarks(bookmarks_file: Path) -> None:
    """Import bookmarks into Firefox."""
    # Firefox bookmark import is complex - we'll use a simpler approach
    # Just inform the user to import manually
    
    print_info("Bookmarks exported to: {bookmarks_file}")
    print_info("To import bookmarks:")
    print_info("  1. Open Firefox and press Ctrl+Shift+O (Bookmarks Manager)")
    print_info("  2. Click 'Import and Backup' > 'Restore' > 'Choose File'")
    print_info(f"  3. Select: {bookmarks_file}")
    
    # Alternatively, we could create an HTML bookmark file
    _create_bookmarks_html(bookmarks_file)


def _create_bookmarks_html(bookmarks_file: Path) -> None:
    """Create an HTML bookmark file for easy import."""
    with open(bookmarks_file) as f:
        bookmarks = json.load(f)
    
    html_file = bookmarks_file.with_suffix(".html")
    
    html_content = """<!DOCTYPE NETSCAPE-Bookmark-file-1>
<!-- This is an automatically generated file.
     It will be read and overwritten.
     DO NOT EDIT! -->
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks</H1>
<DL><p>
"""
    
    def render_item(item: dict, indent: int = 1) -> str:
        prefix = "    " * indent
        result = ""
        
        if item.get("type") == "folder":
            result += f'{prefix}<DT><H3>{item.get("title", "Folder")}</H3>\n'
            result += f'{prefix}<DL><p>\n'
            for child in item.get("children", []):
                result += render_item(child, indent + 1)
            result += f'{prefix}</DL><p>\n'
        else:
            url = item.get("url", "")
            title = item.get("title", url)
            if url and not url.startswith("place:"):
                result += f'{prefix}<DT><A HREF="{url}">{title}</A>\n'
        
        return result
    
    for bookmark in bookmarks:
        html_content += render_item(bookmark)
    
    html_content += "</DL><p>\n"
    
    with open(html_file, "w") as f:
        f.write(html_content)
    
    print_success(f"Created importable bookmark file: {html_file}")
    print_info("Import in Firefox: Ctrl+Shift+O > Import and Backup > Import from HTML")
