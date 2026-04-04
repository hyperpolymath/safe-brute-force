# TEST-NEEDS.md — CRG Grade B Test Documentation

## Grade B Status: 6 Test Targets

This file documents the six independently runnable test targets required for CRG Grade B compliance.

| Target | Justfile Recipe | Description | Pass Criterion |
|--------|-----------------|-------------|----------------|
| T1 | `just test-lfe` | LFE unit tests via `rebar3 lfe test` | All LFE test assertions pass |
| T2 | `just test-structure` | Structural validation (`tests/validate_structure.sh`) | All required files/dirs present; ≥3 workflows |
| T3 | `just test-compile` | Compilation check via `rebar3 compile` | Exits 0 (no compile errors) |
| T4 | `just test-static` | Static analysis via `rebar3 xref` | Exits 0 or degrades gracefully |
| T5 | `just test-nickel` | Nickel k9 contractile typecheck | `nickel typecheck` exits 0 (skipped if nickel absent) |
| T6 | `just test-examples` | Example LFE syntax validation (`tests/validate_examples.sh`) | 0 syntax errors in `examples/*.lfe` (skipped if erlc absent) |

## Running All Targets

```bash
just test
```

## Individual Targets

```bash
just test-lfe
just test-structure
just test-compile
just test-static
just test-nickel
just test-examples
```

## Notes

- T4 degrades gracefully: `rebar3 xref` exit code is not surfaced as a failure to avoid blocking on environments without complete PLT.
- T5 and T6 degrade gracefully when the required tools (`nickel`, `erlc`) are not installed — they emit `SKIP:` and exit 0.
- T5 strips the `K9!` header from the k9 template file before passing to `nickel typecheck` (the header is a k9 DSL marker, not valid Nickel).
