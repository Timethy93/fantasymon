"""Verify a locally exported pack contains neither developer UI nor tests/MCP."""
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1]) as archive:
    paths = archive.namelist()
    forbidden = [path for path in paths if path.startswith(("dev/", "tests/", "addons/godot_mcp_toolkit/")) or "life_debug_menu" in path]
    assert not forbidden, forbidden
    assert "project.binary" in paths
    assert any("world_clock" in path for path in paths)
    assert any("feeding_service" in path for path in paths)
    print(f"Release archive: {len(paths)} entries; no developer UI, tests or MCP files")
