# Legacy Directory - Deprecation Notice

## ⚠️ Everything in this directory is DEPRECATED

**Do not use any files in this directory for new deployments.**

---

## What's in Here?

This directory contains **archived tools and scripts that are no longer supported:**

- `powershell/` - Old v1.0/v2.0 scripts (superseded by v3.0)
- `psinfo/` - PSTools/PSInfo (external dependencies, security issues)
- `wmic/` - WMIC scripts (removed by Microsoft in Windows 11)

---

## What Should You Use Instead?

### ✅ Current Version: v3.0

**Main scripts:**
- `Invoke-AssetInventory.ps1` - Full-featured scanner
- `AssetInventory.psm1` - Reusable module
- `Start-AssetInventory.ps1` - Config-based wrapper

**See:** `../REPOSITORY_STRUCTURE.md` for complete details.

---

## Timeline

| Date | Action |
|------|--------|
| 2026-02 | Legacy directory created |
| 2026-03 | Remove legacy tools from deployments |
| 2026-06 | Archive entire legacy directory |
| 2026-09 | Delete legacy directory from main branch |

---

**This directory will be removed in September 2026.**

Migrate to v3.0 now: See `../docs/PSTOOLS_MIGRATION.md`
