# SafeBruteForce Usage Guide

## Table of Contents

1. [Installation](#installation)
2. [Quick Start](#quick-start)
3. [Pattern Generation Strategies](#pattern-generation-strategies)
4. [Target Configuration](#target-configuration)
5. [Safety Features](#safety-features)
6. [Checkpoint System](#checkpoint-system)
7. [Advanced Usage](#advanced-usage)

## Installation

### Prerequisites

```bash
# Install Erlang/OTP (version 26 or higher)
# On Ubuntu/Debian:
sudo apt-get install erlang

# On macOS:
brew install erlang

# Install Rebar3
curl -O https://s3.amazonaws.com/rebar3/rebar3
chmod +x rebar3
sudo mv rebar3 /usr/local/bin/

# Install LFE
rebar3 new lfe-app myapp
```

### Build SafeBruteForce

```bash
git clone https://github.com/Hyperpolymath/safe-brute-force.git
cd safe-brute-force
rebar3 compile
```

## Quick Start

### Interactive REPL (Recommended)

```bash
rebar3 lfe repl
```

```lisp
;; Start the application
> (sbf:start)

;; Test with a simple function
> (sbf:test_wordlist "priv/wordlists/test-wordlist.txt"
                     (lambda (p) (== p "secret")))

;; Test HTTP endpoint
> (sbf:test_http "http://localhost/login"
                 "admin"
                 "priv/wordlists/common-passwords.txt")
```

### Command Line Interface

```bash
# Basic wordlist test
./sbf_cli wordlist priv/wordlists/test-wordlist.txt http://localhost/login admin

# PIN code test
./sbf_cli pins http://localhost/api/verify

# Charset combinations
./sbf_cli charset "abc" 2 4 http://localhost
```

## Pattern Generation Strategies

### 1. Wordlist Mode

Load patterns from a text file:

```lisp
(let ((pattern-config
       (list (tuple 'type 'wordlist)
             (tuple 'filename "priv/wordlists/common-passwords.txt")))
      (target-config
       (list (tuple 'type 'function)
             (tuple 'function (lambda (p) (== p "target"))))))
  (sbf:run pattern-config target-config))
```

### 2. Wordlist with Mutations

Apply common mutations (leet speak, capitalization, suffixes):

```lisp
(let ((pattern-config
       (list (tuple 'type 'wordlist)
             (tuple 'filename "passwords.txt")
             (tuple 'mutations 'standard))))  ; or 'minimal or 'aggressive
  (sbf:run pattern-config target-config))
```

Mutation levels:
- **minimal**: Original + Capitalized
- **standard**: + numbers (123, 2024) + leet speak
- **aggressive**: All mutations + reverse + combinations

### 3. Charset Combinations

Generate all combinations from a character set:

```lisp
(let ((pattern-config
       (list (tuple 'type 'charset)
             (tuple 'charset "abcdefghijklmnopqrstuvwxyz0123456789")
             (tuple 'min_length 4)
             (tuple 'max_length 6))))
  (sbf:run pattern-config target-config))
```

### 4. Sequential Numbers

```lisp
(let ((pattern-config
       (list (tuple 'type 'sequential)
             (tuple 'start 1000)
             (tuple 'end 9999))))
  (sbf:run pattern-config target-config))
```

### 5. Common Passwords

```lisp
(let ((pattern-config
       (list (tuple 'type 'common))))
  (sbf:run pattern-config target-config))
```

### 6. Custom Function

```lisp
(let ((pattern-config
       (list (tuple 'type 'custom)
             (tuple 'function
                    (lambda ()
                      ;; Generate custom patterns
                      (list "pattern1" "pattern2" "pattern3"))))))
  (sbf:run pattern-config target-config))
```

## Target Configuration

### HTTP/HTTPS Targets

```lisp
(let ((target-config
       (list (tuple 'type 'http)
             (tuple 'url "http://example.com/login")
             (tuple 'method 'post)  ; or 'get
             (tuple 'username "admin")
             (tuple 'username_field "user")
             (tuple 'password_field "pass")
             ;; Success detection
             (tuple 'success_pattern "Welcome")
             ;; Or failure detection
             (tuple 'failure_pattern "Invalid credentials")
             ;; Optional: custom headers
             (tuple 'headers (list (tuple "User-Agent" "Custom")))
             ;; Optional: body format
             (tuple 'body_format 'json))))  ; or 'urlencoded (default)
  (sbf:run pattern-config target-config))
```

### Custom Function Targets

```lisp
(let ((target-config
       (list (tuple 'type 'function)
             (tuple 'function
                    (lambda (pattern)
                      ;; Your validation logic
                      (== pattern "correct"))))))
  (sbf:run pattern-config target-config))
```

### Mock Targets (Testing)

```lisp
(let ((target-config
       (list (tuple 'type 'mock)
             (tuple 'expected "secret123"))))
  (sbf:run pattern-config target-config))
```

## Safety Features

### Automatic Pause

SafeBruteForce automatically pauses every 25 attempts (configurable):

```lisp
;; The system will pause and display:
╔════════════════════════════════════════════════╗
║  🛑 PAUSED - Safety Checkpoint                 ║
║  Completed 25 attempts                         ║
║  Call (sbf:resume) to continue                 ║
║  Call (sbf:stats) to see results               ║
╚════════════════════════════════════════════════╝

;; To continue:
> (sbf:resume)
```

### Manual Control

```lisp
;; Pause at any time
> (sbf:pause)

;; Resume
> (sbf:resume)

;; Check status
> (sbf:status)

;; Get detailed statistics
> (sbf:stats)
```

### Rate Limiting

Configure requests per second:

```erlang
%% In config/sys.config
{safe_brute_force, [
    {rate_limit, 50}  % Max 50 requests per second
]}
```

## Checkpoint System

### Save Checkpoint

```lisp
;; Auto-save with default name
> (sbf:save_checkpoint)

;; Save with custom name
> (sbf:save_checkpoint 'my_session)
```

### Restore Checkpoint

```lisp
;; List available checkpoints
> (sbf:list_checkpoints)

;; Restore from checkpoint
> (sbf:load_checkpoint "my_session_1234567890_5678")
```

### Auto-Checkpoint

Checkpoints are automatically saved every 100 attempts (configurable):

```erlang
%% In config/sys.config
{safe_brute_force, [
    {checkpoint_interval, 100}
]}
```

## Advanced Usage

### Async Execution

```lisp
;; Run asynchronously
> (sbf:run_async pattern-config target-config)
#Pid<0.123.0>

;; Check status while running
> (sbf:status)
```

### Progress Tracking

```lisp
;; Get progress with ETA
(let ((progress (sbf_progress:new 10000)))
  ;; ... process items ...
  (sbf_progress:print progress))

;; Output: [=========>----------] 45.2% (4520/10000) | 120.5/s | ETA: 45s
```

### Custom Logging

```lisp
;; Set log level
(sbf_logger:set_level 'debug)  ; 'debug | 'info | 'warning | 'error

;; Log custom messages
(sbf_logger:info "Starting custom test")
(sbf_logger:success "Pattern found!")
```

### Result Filtering

```lisp
;; After running
(let ((stats (sbf:stats)))
  (let ((successful-patterns (maps:get 'successful_patterns stats)))
    (io:format "Found: ~p~n" (list successful-patterns))))
```

### Custom Pattern Recipes

```lisp
;; PIN codes
(sbf_patterns:pin-codes)  ; All 4-digit PINs

;; Simple passwords
(sbf_patterns:simple-passwords)  ; Alphanumeric 4-6 chars

;; Hex colors
(sbf_patterns:hex-colors)  ; All #RRGGBB colors
```

## Configuration Reference

### Environment Variables

```erlang
{safe_brute_force, [
    {pause_interval, 25},        % Pause every N attempts
    {max_workers, 10},           % Concurrent workers
    {request_timeout, 5000},     % Timeout per request (ms)
    {rate_limit, 100},           % Max requests per second
    {checkpoint_interval, 100},  % Auto-checkpoint frequency
    {checkpoint_dir, "priv/checkpoints"},
    {safety_enabled, true}       % Enable safety pause
]}
```

### Disabling Safety (Not Recommended)

```erlang
%% Only for testing!
{safe_brute_force, [
    {safety_enabled, false}
]}
```

## Examples

See the `examples/` directory for complete examples:

- `http_login_test.lfe` - HTTP form authentication
- `pin_code_test.lfe` - PIN code brute-forcing
- `custom_pattern_test.lfe` - Custom pattern generation

## Troubleshooting

### Application Won't Start

```bash
# Check Erlang version
erl -version

# Rebuild
rebar3 clean
rebar3 compile
```

### Rate Limiting Too Aggressive

```erlang
% Adjust in config/sys.config
{rate_limit, 0}  % Disable rate limiting (use with caution!)
```

### Checkpoints Not Saving

```bash
# Ensure directory exists
mkdir -p priv/checkpoints
chmod 755 priv/checkpoints
```

## Best Practices

1. **Always get authorization** before testing any system
2. **Start with small wordlists** to verify configuration
3. **Use rate limiting** to avoid overwhelming targets
4. **Save checkpoints** for long-running operations
5. **Monitor system resources** during large operations
6. **Review results carefully** using filtering functions
7. **Test on local/mock systems first**

## Getting Help

- Read the [README](../README.md)
- Check [CLAUDE.md](../CLAUDE.md) for AI assistant guidance
- Review [Security Best Practices](SECURITY.md)
- Open an issue on GitHub
