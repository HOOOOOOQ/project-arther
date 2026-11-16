#!/usr/bin/env python3
"""Check the built Rojo hierarchy, script source and statically expressible requires.

This checks the current repository's require patterns; it is not a Luau interpreter
and cannot discover dynamically constructed dependencies or Roblox runtime errors.
"""
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path, PurePosixPath

root = Path(__file__).resolve().parents[1]
build = ET.parse(sys.argv[1]).getroot()
nodes = {}

def walk(element, parent=""):
    for item in element.findall("Item"):
        props = item.find("Properties")
        name = props.find("string[@name='Name']").text
        path = parent + "/" + name
        assert path not in nodes, f"duplicate instance {path}"
        nodes[path] = (item.attrib["class"], props.findtext("string[@name='Source']"))
        walk(item, path)

walk(build)
workspace = next(item for item in build.findall("Item") if item.attrib["class"] == "Workspace")
assert workspace.findtext("./Properties/bool[@name='StreamingEnabled']") == "true", "streaming not enabled"
script_paths = {}
for file in (root / "src").rglob("*.luau"):
    rel = file.relative_to(root / "src").as_posix()
    name = rel[:-5]
    kind = "ModuleScript"
    if name.endswith(".server"):
        name, kind = name[:-7], "Script"
    elif name.endswith(".client"):
        name, kind = name[:-7], "LocalScript"
    path = "/" + name
    assert path in nodes, f"missing {path}"
    actual_kind, source = nodes[path]
    assert actual_kind == kind, f"wrong class for {path}: {actual_kind}"
    assert source == file.read_text(), f"source mismatch: {path}"
    script_paths[path] = file

for path, file in script_paths.items():
    source = file.read_text()
    for chain in re.findall(r"require\(script((?:\.\w+)+)\)", source):
        dep = PurePosixPath(path)
        for component in chain.lstrip(".").split("."):
            dep = dep.parent if component == "Parent" else dep / component
        assert nodes.get(str(dep), (None,))[0] == "ModuleScript", f"missing require {path} -> {dep}"
    for shared in re.findall(r"require\(ReplicatedStorage\.Shared\.(\w+)\)", source):
        assert nodes.get("/ReplicatedStorage/Shared/" + shared, (None,))[0] == "ModuleScript", shared
    for shared in re.findall(r'require\(ReplicatedStorage:WaitForChild\("Shared"\):WaitForChild\("(\w+)"\)\)', source):
        assert nodes.get("/ReplicatedStorage/Shared/" + shared, (None,))[0] == "ModuleScript", shared
    if path.startswith(("/StarterPlayer/", "/ReplicatedStorage/")):
        assert "ServerScriptService" not in source and "DataStoreService" not in source, f"server dependency in {path}"
print(f"PASS: {len(script_paths)} built script paths/classes/sources and static require patterns")
print("PASS: client/shared sources contain no direct DataStoreService or ServerScriptService reference")
