# tools/import

How this snapshot was assembled from the upstream projects. Kept so every imported
file can be traced back, and the import can be redone or checked.

| File | What |
|---|---|
| `manifest.tsv` | every imported file: new path, upstream repo, commit, original path, note |
| `patches/` | our changes to imported files, applied in name order |
| `assemble.py` | copies files from local upstream clones per the manifest, applies the patches, writes `../../SOURCES.md` |

Upstream snapshots:
- nestang `869140ca36953e6f0395de357a86c90823f84585` (v0.12)
- snestang `58bb70aba31eb3055aceba910dc1d5c407da853b` (v0.9)

Redo the import into a scratch folder and compare with the repo:
```sh
git clone https://github.com/nand2mario/nestang  /tmp/nestang
git clone https://github.com/nand2mario/snestang /tmp/snestang
python3 tools/import/assemble.py --nestang /tmp/nestang --snestang /tmp/snestang --out /tmp/check
```

After the initial import, files are edited directly in the repo. The patches here
record only the changes made at import time.
