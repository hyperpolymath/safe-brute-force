# SafeBruteForce API Reference

Complete API documentation for SafeBruteForce modules.

## Table of Contents

1. [Main API (sbf)](#main-api-sbf)
2. [State Management (sbf_state)](#state-management-sbf_state)
3. [Pattern Generation (sbf_patterns)](#pattern-generation-sbf_patterns)
4. [Output (sbf_output)](#output-sbf_output)
5. [Checkpoints (sbf_checkpoint)](#checkpoints-sbf_checkpoint)
6. [Progress Tracking (sbf_progress)](#progress-tracking-sbf_progress)
7. [Logging (sbf_logger)](#logging-sbf_logger)

---

## Main API (sbf)

High-level interface for SafeBruteForce operations.

### Application Control

#### `(sbf:start)`
Start the SafeBruteForce application.

**Returns:** `{ok, [started_apps]} | {error, reason}`

**Example:**
```lisp
> (sbf:start)
{ok,[safe_brute_force,lfe,lhttpc,uuid]}
```

#### `(sbf:stop)`
Stop the SafeBruteForce application.

**Returns:** `ok | {error, reason}`

### Brute-Force Operations

#### `(sbf:run pattern-config target-config)`
Run brute-force operation synchronously.

**Parameters:**
- `pattern-config` - Property list for pattern generation
- `target-config` - Property list for target configuration

**Returns:** Final statistics map

**Example:**
```lisp
(sbf:run
  (list (tuple 'type 'wordlist)
        (tuple 'filename "passwords.txt"))
  (list (tuple 'type 'http)
        (tuple 'url "http://localhost/login")))
```

#### `(sbf:run_async pattern-config target-config)`
Run brute-force operation asynchronously.

**Returns:** `#Pid<...>` (process ID)

### Convenience Functions

#### `(sbf:test_http url username wordlist-file)`
Test HTTP endpoint with username and wordlist.

**Parameters:**
- `url` - Target URL string
- `username` - Username string
- `wordlist-file` - Path to wordlist file

**Example:**
```lisp
(sbf:test_http "http://localhost/login" "admin" "passwords.txt")
```

#### `(sbf:test_wordlist wordlist-file test-fn)`
Test patterns from wordlist using custom function.

**Parameters:**
- `wordlist-file` - Path to wordlist
- `test-fn` - Function that takes pattern and returns boolean

#### `(sbf:test_pins test-fn)`
Test all 4-digit PIN codes.

**Parameters:**
- `test-fn` - Function that validates PIN codes

#### `(sbf:test_custom pattern-list test-fn)`
Test custom pattern list.

**Parameters:**
- `pattern-list` - List of patterns to test
- `test-fn` - Validation function

### Control Functions

#### `(sbf:pause)`
Manually pause the operation.

**Returns:** `ok`

#### `(sbf:resume)`
Resume paused operation.

**Returns:** `ok`

#### `(sbf:status)`
Get current status.

**Returns:** Status map with keys:
- `state` - Current state (running/paused/etc.)
- `attempts` - Total attempts
- `successes` - Successful attempts

#### `(sbf:stats)`
Get detailed statistics.

**Returns:** Comprehensive statistics map

### Checkpoint Operations

#### `(sbf:save_checkpoint)`
Save checkpoint with default name.

**Returns:** `{ok, info} | {error, reason}`

#### `(sbf:save_checkpoint session-name)`
Save checkpoint with specific name.

**Returns:** `{ok, info} | {error, reason}`

#### `(sbf:load_checkpoint checkpoint-id)`
Load checkpoint by ID.

**Returns:** `{ok, checkpoint-data} | {error, reason}`

#### `(sbf:list_checkpoints)`
List all checkpoints.

**Returns:** List of checkpoint metadata maps

---

## State Management (sbf_state)

State machine for pause/resume functionality.

### API Functions

#### `(sbf_state:start_link config)`
Start state manager with configuration.

**Parameters:**
- `config` - Property list with:
  - `pause_interval` - Attempts before pause (default: 25)
  - `safety_enabled` - Enable safety pause (default: true)

#### `(sbf_state:attempt pattern result)`
Record an attempt.

**Parameters:**
- `pattern` - The pattern tested
- `result` - `'success` or `'failure`

**Returns:** `{ok, state, count} | {ok, paused, count}`

#### `(sbf_state:get_status)`
Get current status.

**Returns:** Status map

#### `(sbf_state:get_stats)`
Get detailed statistics.

**Returns:** Statistics map with:
- `state` - Current state
- `attempt_count` - Total attempts
- `success_count` - Successful attempts
- `failure_count` - Failed attempts
- `successful_patterns` - List of successful patterns
- `elapsed_seconds` - Time elapsed
- `attempts_per_second` - Rate
- `success_rate_percent` - Success percentage

#### `(sbf_state:reset)`
Reset counters.

**Returns:** `ok`

---

## Pattern Generation (sbf_patterns)

Generate patterns for brute-forcing.

### Generation Functions

#### `(sbf_patterns:charset_combinations charset max-length)`
Generate all combinations from charset up to max-length.

**Parameters:**
- `charset` - String of characters to use
- `max-length` - Maximum pattern length

**Returns:** List of pattern strings

**Example:**
```lisp
> (sbf_patterns:charset_combinations "abc" 2)
["a","b","c","aa","ab","ac","ba","bb","bc","ca","cb","cc"]
```

#### `(sbf_patterns:charset_combinations charset min-length max-length)`
Generate combinations between min and max length.

#### `(sbf_patterns:sequential_numbers start end)`
Generate sequential numbers as strings.

**Example:**
```lisp
> (sbf_patterns:sequential_numbers 1000 1005)
["1000","1001","1002","1003","1004","1005"]
```

#### `(sbf_patterns:wordlist filename)`
Load patterns from file.

**Parameters:**
- `filename` - Path to wordlist file (one pattern per line)

**Returns:** List of patterns

#### `(sbf_patterns:wordlist_with_mutations filename)`
Load wordlist and apply standard mutations.

**Returns:** Expanded list with mutations

#### `(sbf_patterns:common_passwords)`
Get list of common passwords.

**Returns:** List of common password strings

#### `(sbf_patterns:date_patterns year)`
Generate date patterns for a given year.

**Parameters:**
- `year` - Year as integer

**Returns:** List of date pattern strings in various formats

### Utility Functions

#### `(sbf_patterns:estimate_total type config)`
Estimate total patterns for a strategy.

**Parameters:**
- `type` - Pattern type ('charset, 'wordlist, etc.)
- `config` - Configuration for that type

**Returns:** Integer count or 'unknown

#### `(sbf_patterns:permutations list)`
Generate all permutations of a list.

#### `(sbf_patterns:combinations n list)`
Generate all combinations of n elements from list.

### Built-in Recipes

#### `(sbf_patterns:pin-codes)`
All 4-digit PIN codes (10,000 patterns).

#### `(sbf_patterns:simple-passwords)`
Simple alphanumeric passwords 4-6 characters.

#### `(sbf_patterns:hex-colors)`
All possible hex color codes.

---

## Output (sbf_output)

Result formatting and output management.

### Formatting Functions

#### `(sbf_output:format_results results)`
Format results (successes only by default).

#### `(sbf_output:format_results results mode)`
Format results with specific mode.

**Parameters:**
- `results` - List of result tuples
- `mode` - `'successes_only | 'failures_only | 'all | 'summary`

**Returns:** Formatted results

#### `(sbf_output:filter_results results type)`
Filter results by type.

**Parameters:**
- `results` - List of results
- `type` - `'success | 'failure | 'error`

### File Output

#### `(sbf_output:save_results results filename)`
Save results to file.

**Returns:** `{ok, info} | {error, reason}`

### Console Output

#### `(sbf_output:print_summary stats)`
Print comprehensive summary to console.

**Parameters:**
- `stats` - Statistics map from `(sbf:stats)`

#### `(sbf_output:print_progress current total)`
Print progress bar.

**Parameters:**
- `current` - Current count
- `total` - Total count

#### `(sbf_output:print_banner)`
Print SafeBruteForce banner.

### Colorized Output

#### `(sbf_output:print_success message)`
Print success message in green.

#### `(sbf_output:print_error message)`
Print error message in red.

#### `(sbf_output:print_warning message)`
Print warning message in yellow.

#### `(sbf_output:print_info message)`
Print info message in cyan.

---

## Checkpoints (sbf_checkpoint)

Save and restore session state.

### Save Functions

#### `(sbf_checkpoint:save session-name state)`
Save checkpoint with auto-generated ID.

**Returns:** `{ok, info} | {error, reason}`

#### `(sbf_checkpoint:save session-name checkpoint-id state)`
Save checkpoint with specific ID.

### Restore Functions

#### `(sbf_checkpoint:restore checkpoint-id)`
Restore session from checkpoint.

**Returns:** `{ok, checkpoint-data} | {error, reason}`

### Management Functions

#### `(sbf_checkpoint:list_checkpoints)`
List all checkpoints.

#### `(sbf_checkpoint:list_checkpoints session-name)`
List checkpoints for specific session.

#### `(sbf_checkpoint:delete checkpoint-id)`
Delete a checkpoint.

**Returns:** `{ok, info} | {error, reason}`

#### `(sbf_checkpoint:auto_save state)`
Auto-save with timestamp-based ID.

#### `(sbf_checkpoint:get_checkpoint_info checkpoint-id)`
Get metadata without loading full checkpoint.

---

## Progress Tracking (sbf_progress)

Track progress and calculate ETA.

### Core Functions

#### `(sbf_progress:new total)`
Create new progress tracker.

**Parameters:**
- `total` - Total number of items

**Returns:** Progress map

#### `(sbf_progress:update progress current)`
Update progress with current count.

**Returns:** Updated progress map

#### `(sbf_progress:get_eta progress)`
Get estimated time remaining in seconds.

**Returns:** Integer seconds or `'unknown`

#### `(sbf_progress:get_percent progress)`
Get completion percentage.

**Returns:** Float percentage (0.0-100.0)

#### `(sbf_progress:get_rate progress)`
Get current rate (items per second).

**Returns:** Float rate

#### `(sbf_progress:print progress)`
Print progress bar to console.

### Utility Functions

#### `(sbf_progress:format_duration seconds)`
Format duration in human-readable form.

**Returns:** String like "2m 30s" or "1h 15m"

#### `(sbf_progress:get_stats progress)`
Get comprehensive progress statistics.

---

## Logging (sbf_logger)

Structured logging system.

### Logging Functions

#### `(sbf_logger:log level message)`
Log message at specified level.

**Parameters:**
- `level` - `'debug | 'info | 'warning | 'error | 'success | 'failure`
- `message` - Message string

#### `(sbf_logger:log level message metadata)`
Log with metadata.

**Parameters:**
- `metadata` - Map of additional data

#### `(sbf_logger:debug message)`
Log debug message.

#### `(sbf_logger:info message)`
Log info message.

#### `(sbf_logger:warning message)`
Log warning message.

#### `(sbf_logger:error message)`
Log error message.

#### `(sbf_logger:success message)`
Log success message.

#### `(sbf_logger:failure message)`
Log failure message.

### Configuration

#### `(sbf_logger:set_level level)`
Set minimum logging level.

**Parameters:**
- `level` - `'debug | 'info | 'warning | 'error`

#### `(sbf_logger:get_level)`
Get current logging level.

### File Logging

#### `(sbf_logger:log_to_file filename message)`
Append log message to file.

**Returns:** `ok | {error, reason}`

### Specialized Logging

#### `(sbf_logger:log_attempt pattern result metadata)`
Log a brute-force attempt.

#### `(sbf_logger:log_session_start config)`
Log session start.

#### `(sbf_logger:log_session_end stats)`
Log session end with statistics.

#### `(sbf_logger:log_pause)`
Log pause event.

#### `(sbf_logger:log_resume)`
Log resume event.

#### `(sbf_logger:log_checkpoint checkpoint-id)`
Log checkpoint save.

---

## Configuration Reference

### Pattern Config

```lisp
;; Wordlist
(list (tuple 'type 'wordlist)
      (tuple 'filename "path/to/wordlist.txt")
      (tuple 'mutations 'standard))  ; optional: minimal | standard | aggressive

;; Charset
(list (tuple 'type 'charset)
      (tuple 'charset "abcdefgh123456")
      (tuple 'min_length 4)
      (tuple 'max_length 8))

;; Sequential
(list (tuple 'type 'sequential)
      (tuple 'start 1000)
      (tuple 'end 9999))

;; Custom
(list (tuple 'type 'custom)
      (tuple 'function (lambda () (list "pattern1" "pattern2"))))
```

### Target Config

```lisp
;; HTTP
(list (tuple 'type 'http)
      (tuple 'url "http://example.com/login")
      (tuple 'method 'post)  ; or 'get
      (tuple 'username "admin")
      (tuple 'username_field "user")
      (tuple 'password_field "pass")
      (tuple 'success_pattern "Welcome")
      (tuple 'failure_pattern "Invalid")
      (tuple 'body_format 'urlencoded)  ; or 'json
      (tuple 'headers (list (tuple "X-Custom" "value"))))

;; Function
(list (tuple 'type 'function)
      (tuple 'function (lambda (p) (validate p))))

;; Mock
(list (tuple 'type 'mock)
      (tuple 'expected "correct_password"))
```

---

## Error Handling

All functions return tagged tuples:

```lisp
{ok, result}        ; Success
{error, reason}     ; Error with reason
{ok, state, data}   ; Success with state and data
```

Common error reasons:
- `checkpoint_not_found`
- `invalid_checkpoint`
- `stopped`
- `waiting_confirmation`
- `unknown_target_type`
- `unknown_request`

---

## Type Specifications

### Pattern Types
- `'wordlist` - Load from file
- `'charset` - Generate combinations
- `'sequential` - Number sequences
- `'common` - Common passwords
- `'custom` - Custom function

### Target Types
- `'http` - HTTP/HTTPS endpoints
- `'function` - Custom validators
- `'mock` - Testing targets
- `'ssh` - SSH (planned)

### State Machine States
- `'running` - Actively processing
- `'paused` - Manually paused
- `'waiting_confirmation` - Auto-paused, waiting for user
- `'stopped` - Stopped/completed

---

For complete examples, see the `examples/` directory and `docs/USAGE.md`.
