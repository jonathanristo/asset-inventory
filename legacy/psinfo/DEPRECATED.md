# ⚠️ DEPRECATED: PSInfo / PSTools

## This Directory Contains Deprecated Tools

**Status:** ❌ **DEPRECATED - DO NOT USE**

---

## Why Is This Deprecated?

1. **External Dependency** - Requires PSInfo.exe
2. **Security Concerns** - Flagged by antivirus
3. **Native Alternative** - PowerShell has all features
4. **Text Output** - Hard to parse vs structured objects

---

## What Should You Use Instead?

### ✅ Replacement: Asset Inventory v3.0

**Instead of:**
```bash
psinfo \\COMPUTER01
```

**Use:**
```powershell
Get-ComputerInventory -ComputerName COMPUTER01
```

---

## Complete Feature Comparison

| Feature | PSInfo | v3.0 Module |
|---------|--------|-------------|
| Computer info | ✅ | ✅ |
| No dependencies | ❌ | ✅ |
| Structured output | ❌ | ✅ |
| Network scanning | ❌ | ✅ |
| Parallel processing | ❌ | ✅ |

---

See: `../../docs/PSTOOLS_MIGRATION.md` for complete migration guide.

**This directory will be removed in June 2026.**
