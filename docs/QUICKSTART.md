# SafeBruteForce Quick Start Guide

Get up and running with SafeBruteForce in 5 minutes.

## Prerequisites

Install Erlang/OTP 26+ and Rebar3:

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install erlang rebar3

# macOS
brew install erlang rebar3

# Verify installation
erl -version
rebar3 version
```

## Installation

```bash
# Clone the repository
git clone https://github.com/Hyperpolymath/safe-brute-force.git
cd safe-brute-force

# Compile the project
rebar3 compile

# Run tests to verify installation
rebar3 lfe test
```

## Your First Brute-Force Test

### Example 1: Simple Function Test

Start the interactive REPL:

```bash
rebar3 lfe repl
```

```lisp
;; Start the application
> (sbf:start)

;; Test a simple validation function
> (let ((correct-password "secret123")
        (test-fn (lambda (password)
                  (== password correct-password))))
    (sbf:test_wordlist "priv/wordlists/test-wordlist.txt" test-fn))

;; You'll see:
;; [SafeBruteForce] Generated N patterns
;; [SafeBruteForce] Batch size: 25
;; [SafeBruteForce] ⚠️  Pause every 25 attempts (safety enabled)
;;
;; After 25 attempts, it will pause:
;; ╔════════════════════════════════════════════════╗
;; ║  🛑 PAUSED - Safety Checkpoint                 ║
;; ║  Completed 25 attempts                         ║
;; ║  Call (sbf:resume) to continue                 ║
;; ╚════════════════════════════════════════════════╝

;; To continue:
> (sbf:resume)

;; Check results at any time:
> (sbf:stats)
```

### Example 2: PIN Code Test

Test all 4-digit PIN codes (with a mock validator):

```lisp
> (sbf:start)

;; Create a PIN validator (this is just an example - replace with real logic)
> (let ((secret-pin "1234")
        (validator (lambda (pin) (== pin secret-pin))))
    (sbf:test_pins validator))

;; This will test all 10,000 PINs, pausing every 25 attempts
```

### Example 3: HTTP Login Test (Requires Running Server)

```lisp
> (sbf:start)

;; Test against a local web application
;; IMPORTANT: Only test systems you own or have permission to test!
> (sbf:test_http
    "http://localhost:8080/login"  ; Your test server URL
    "admin"                         ; Username to test
    "priv/wordlists/common-passwords.txt")  ; Wordlist file

;; The tool will:
;; 1. Load passwords from the wordlist
;; 2. Try each password against the HTTP endpoint
;; 3. Pause every 25 attempts for your confirmation
;; 4. Report successful credentials
```

## Using the CLI

Make the CLI executable:

```bash
chmod +x sbf_cli
```

### Test with Wordlist

```bash
./sbf_cli wordlist priv/wordlists/common-passwords.txt \
  http://localhost:8080/login admin
```

The CLI will:
1. Prompt for authorization confirmation
2. Load the wordlist
3. Begin testing
4. Pause every 25 attempts

### Test PIN Codes

```bash
./sbf_cli pins http://localhost:8080/verify
```

### Generate Charset Combinations

```bash
./sbf_cli charset "abc123" 4 6 http://localhost:8080/api
```

## Understanding the Output

### During Execution

```
[SafeBruteForce] Generated 60 patterns
[SafeBruteForce] Batch size: 25
[SafeBruteForce] ⚠️  Pause every 25 attempts (safety enabled)

[=========>---------] 45.0% (27/60) | 12.5/s | ETA: 3s

[SUCCESS] Pattern: secret123 -> SUCCESS
```

### At Pause

```
╔════════════════════════════════════════════════╗
║  🛑 PAUSED - Safety Checkpoint                 ║
║  Completed 25 attempts                         ║
║  Call (sbf:resume) to continue                 ║
║  Call (sbf:stats) to see results               ║
╚════════════════════════════════════════════════╝
```

### Final Summary

```
╔════════════════════════════════════════════════════╗
║       SafeBruteForce - Session Summary            ║
╠════════════════════════════════════════════════════╣
║ State:           stopped                          ║
║ Total Attempts:  60                               ║
║ Successes:       1                                ║
║ Failures:        59                               ║
║ Elapsed Time:    5 seconds                        ║
║ Attempts/sec:    12.0                             ║
║ Success Rate:    1.67%                            ║
╚════════════════════════════════════════════════════╝

Successful Patterns:
  ✓ secret123
```

## Common Commands

### REPL Commands

```lisp
;; Start application
(sbf:start)

;; Pause execution
(sbf:pause)

;; Resume execution
(sbf:resume)

;; Check status
(sbf:status)

;; Get detailed statistics
(sbf:stats)

;; Save checkpoint
(sbf:save_checkpoint 'my_session)

;; List checkpoints
(sbf:list_checkpoints)

;; Load checkpoint
(sbf:load_checkpoint "checkpoint_id")

;; Stop application
(sbf:stop)
```

## Creating Custom Tests

### Custom Pattern Generator

```lisp
;; Generate year-based passwords
(let ((pattern-generator
       (lambda ()
         (lists:map
          (lambda (year)
            (++ "Password" (integer_to_list year)))
          (lists:seq 2020 2025))))
      (test-fn (lambda (p) (validate-password p)))
      (pattern-config
       (list (tuple 'type 'custom)
             (tuple 'function pattern-generator)))
      (target-config
       (list (tuple 'type 'function)
             (tuple 'function test-fn))))
  (sbf:run pattern-config target-config))
```

### Custom HTTP Test

```lisp
(let ((pattern-config
       (list (tuple 'type 'wordlist)
             (tuple 'filename "passwords.txt")
             (tuple 'mutations 'standard)))
      (target-config
       (list (tuple 'type 'http)
             (tuple 'url "http://testsite.local/api/login")
             (tuple 'method 'post)
             (tuple 'username "testuser")
             (tuple 'username_field "email")
             (tuple 'password_field "password")
             (tuple 'body_format 'json)
             (tuple 'success_pattern "\"authenticated\":true")
             (tuple 'headers (list (tuple "Content-Type" "application/json"))))))
  (sbf:run pattern-config target-config))
```

## Configuration

Customize behavior by editing `config/sys.config`:

```erlang
{safe_brute_force, [
    {pause_interval, 25},        % Change pause frequency
    {max_workers, 10},           % Concurrent workers
    {request_timeout, 5000},     % Request timeout (ms)
    {rate_limit, 100},           % Max requests per second
    {checkpoint_interval, 100},  % Auto-checkpoint frequency
    {safety_enabled, true}       % NEVER disable in production!
]}
```

## Safety Features

SafeBruteForce includes mandatory safety features:

1. **Automatic Pause**: Stops every 25 attempts by default
2. **User Confirmation**: You must explicitly resume
3. **Rate Limiting**: Prevents overwhelming target systems
4. **Authorization Checks**: CLI prompts for confirmation
5. **Audit Logging**: All actions are logged

## Best Practices

1. **Always get authorization** before testing any system
2. **Start with small wordlists** to verify configuration
3. **Use rate limiting** to be respectful to systems
4. **Save checkpoints** for long operations
5. **Test locally first** before testing remote systems

## Troubleshooting

### Application won't start

```bash
# Check Erlang version
erl -version  # Should be 26+

# Clean and rebuild
rebar3 clean
rebar3 compile
```

### Tests failing

```bash
# Run verbose tests
rebar3 lfe test --verbose

# Check for missing dependencies
rebar3 get-deps
rebar3 compile
```

### Permission denied on sbf_cli

```bash
# Make executable
chmod +x sbf_cli
```

### Checkpoints not saving

```bash
# Ensure directory exists
mkdir -p priv/checkpoints
chmod 755 priv/checkpoints
```

## Next Steps

- Read the [Full Usage Guide](USAGE.md)
- Review [Security Best Practices](SECURITY.md)
- Check [API Reference](API_REFERENCE.md)
- Explore example code in `examples/`
- Review [Contributing Guidelines](CONTRIBUTING.md)

## Getting Help

- **Documentation**: Check the `docs/` directory
- **Examples**: See `examples/` for complete code
- **Issues**: Report bugs on GitHub
- **Security**: See SECURITY.md for responsible disclosure

---

**Remember**: SafeBruteForce is for authorized testing only. Always ensure you have explicit permission before testing any system.
