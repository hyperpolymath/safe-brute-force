# Reproducible Builds Status and Roadmap

## Current Status: PARTIAL ⚠️

SafeBruteForce has basic reproducible build infrastructure but not yet **bit-for-bit** reproducibility.

### What We Have ✅

1. **Dependency Locking**
   - `rebar.lock` - pins exact dependency versions
   - All dependencies fetched from known sources
   - Version pinning in `rebar.config`

2. **Nix Flake**
   - `flake.nix` - declares build environment
   - Nix provides hermetic builds
   - Locked nixpkgs version
   - Development shell with fixed tool versions

3. **Build Tools Versioned**
   - Erlang/OTP 26.2 (specified)
   - Rebar3 3.22.1 (specified)
   - LFE 2.1.5 (target)

### What's Missing ❌

1. **BEAM File Non-Determinism**
   ```
   Issue: Erlang BEAM compiler embeds:
   - Compilation timestamps
   - Build machine info
   - Non-deterministic ordering

   Solution: Use ERL_COMPILER_OPTIONS with deterministic flag
   Status: NOT YET IMPLEMENTED
   ```

2. **LFE Dependency Not Fully Locked**
   ```
   Issue: flake.nix has placeholder SHA256
   Solution: Calculate actual hash or use nixpkgs LFE
   Status: TODO
   ```

3. **No Reproducibility Verification**
   ```
   Issue: No CI job that rebuilds and compares artifacts
   Solution: Add "reproducible-check" CI job
   Status: NOT YET IMPLEMENTED
   ```

4. **No Published Checksums**
   ```
   Issue: Releases don't include SHA256SUMS file
   Solution: Generate and sign checksums on release
   Status: NOT YET IMPLEMENTED
   ```

## Achieving 100% Reproducibility

### Phase 1: Fix Erlang Compilation (Quick Win)

**Add to rebar.config:**
```erlang
{erl_opts, [
    debug_info,
    deterministic,  % Remove timestamps and paths
    {source, "."}   % Relative paths only
]}.

{erlc_compiler, [
    {source_ext, ".erl"},
    {out_dir, "ebin"}
]}.
```

**Add to build process:**
```bash
export SOURCE_DATE_EPOCH=1705334400  # Fixed timestamp
export ERL_COMPILER_OPTIONS="[deterministic]"
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
```

**Estimated Effort**: 2-4 hours
**Achievement**: 80% reproducibility

### Phase 2: Nix Hardening (Medium Effort)

**Fix flake.nix:**
1. Calculate real SHA256 for LFE:
   ```bash
   nix-prefetch-git https://github.com/lfe/lfe --rev v2.1.5
   ```

2. Add to build phase:
   ```nix
   # Make builds deterministic
   export SOURCE_DATE_EPOCH=1
   export LANG=C.UTF-8
   export BUILD_ID=""
   ```

3. Remove non-deterministic elements:
   - Strip build paths from artifacts
   - Use `strip-nondeterminism` tool
   - Ensure consistent file ordering

**Estimated Effort**: 4-8 hours
**Achievement**: 90% reproducibility

### Phase 3: Verification Infrastructure (High Effort)

**Add CI job (.gitlab-ci.yml):**
```yaml
reproducible-verify:
  stage: test
  script:
    - echo "Build 1..."
    - nix build .#default --rebuild
    - sha256sum result > build1.sum

    - echo "Build 2 (clean)..."
    - nix build .#default --rebuild
    - sha256sum result > build2.sum

    - echo "Comparing..."
    - diff build1.sum build2.sum || (echo "NOT REPRODUCIBLE!" && exit 1)
    - echo "✓ Builds are reproducible!"
```

**Add release checksums:**
```yaml
release:checksums:
  stage: deploy
  script:
    - sha256sum _build/prod/rel/*.tar.gz > SHA256SUMS
    - gpg --detach-sign --armor SHA256SUMS
  artifacts:
    paths:
      - SHA256SUMS
      - SHA256SUMS.asc
```

**Estimated Effort**: 8-12 hours
**Achievement**: 95% reproducibility

### Phase 4: Multi-Builder Verification (Gold Standard)

**Independent builders verify:**
```bash
# Builder A
nix build github:Hyperpolymath/safe-brute-force
sha256sum result

# Builder B (different machine)
nix build github:Hyperpolymath/safe-brute-force
sha256sum result

# Compare hashes - should match!
```

**Publish attestations:**
- reproducible-builds.org integration
- Public verification by third parties
- Transparency log of build hashes

**Estimated Effort**: 16-24 hours
**Achievement**: 100% reproducibility (Gold Level)

## Why This Matters for RSR

Reproducible builds ensure:
1. ✅ **Security**: Verify no malicious code injection
2. ✅ **Trust**: Anyone can verify artifacts
3. ✅ **Auditability**: Trace source → binary
4. ✅ **Long-term**: Rebuild exact same artifact years later

## Comparison with rhodium-minimal

The rhodium-minimal example achieves 100% because:
- **Rust** has deterministic compilation by default
- Cargo.lock provides perfect dependency pinning
- Fewer runtime dependencies than Erlang/BEAM
- Simpler build process

For LFE/Erlang to match:
- Need `deterministic` compiler flag
- Need SOURCE_DATE_EPOCH
- Need to strip non-deterministic metadata
- Need verification infrastructure

## Current RSR Level Impact

**Bronze Level**: ✅ Dependency locking sufficient
**Silver Level**: ⚠️ Need basic reproducibility (80%+)
**Gold Level**: ❌ Need verified reproducibility (100%)

## Recommendation

**Short-term** (for Silver Level):
1. Add `deterministic` to erl_opts (2 hours)
2. Fix flake.nix SHA256 (1 hour)
3. Add SOURCE_DATE_EPOCH (1 hour)
→ **Achieves 80-90% reproducibility**

**Long-term** (for Gold Level):
1. Add verification CI job (8 hours)
2. Publish checksums on release (4 hours)
3. Multi-builder verification (12 hours)
→ **Achieves 100% reproducibility**

## Current Priority

Focus on **Dialyzer type specs** FIRST (bigger impact on code quality),
then tackle reproducible builds for Silver/Gold levels.

---

**Status**: Partial (60%)
**Path to Silver**: 80% (achievable in 4-6 hours)
**Path to Gold**: 100% (achievable in 24-32 hours)
