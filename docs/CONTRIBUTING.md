# Contributing to SafeBruteForce

Thank you for your interest in contributing to SafeBruteForce! This document provides guidelines for contributing to the project.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Setup](#development-setup)
4. [How to Contribute](#how-to-contribute)
5. [Coding Standards](#coding-standards)
6. [Testing](#testing)
7. [Documentation](#documentation)
8. [Security Considerations](#security-considerations)

## Code of Conduct

### Ethical Requirements

All contributors must:

- ✅ Understand this is a **defensive security tool**
- ✅ Commit to **ethical use only**
- ✅ Follow **responsible disclosure** practices
- ✅ Respect **authorization requirements**
- ✅ Maintain the **"Safety First"** principle

### What We Won't Accept

We will reject contributions that:

- ❌ Remove or bypass safety mechanisms
- ❌ Encourage unauthorized access
- ❌ Implement DoS/DDoS capabilities
- ❌ Enable mass credential stuffing
- ❌ Violate ethical hacking principles

## Getting Started

### Prerequisites

- Erlang/OTP 26+
- Rebar3
- LFE (Lisp Flavored Erlang)
- Git
- Basic understanding of:
  - Functional programming
  - Erlang/OTP design principles
  - Brute-force techniques
  - Security testing ethics

### First Contribution

Good first issues for newcomers:

1. **Documentation improvements**
   - Fix typos
   - Add examples
   - Improve clarity

2. **Pattern generators**
   - Add new wordlist mutation strategies
   - Implement date/time patterns
   - Create industry-specific patterns

3. **Output formatting**
   - Improve console output
   - Add export formats (JSON, CSV)
   - Enhanced progress bars

4. **Test coverage**
   - Add unit tests
   - Write integration tests
   - Test edge cases

## Development Setup

### Clone and Build

```bash
# Fork the repository first on GitHub
git clone https://github.com/YOUR_USERNAME/safe-brute-force.git
cd safe-brute-force

# Add upstream remote
git remote add upstream https://github.com/Hyperpolymath/safe-brute-force.git

# Install dependencies and build
rebar3 compile

# Run tests
rebar3 lfe test
```

### Development Workflow

```bash
# Create a feature branch
git checkout -b feature/your-feature-name

# Make changes
# ... edit files ...

# Run tests
rebar3 lfe test

# Commit with meaningful message
git commit -m "Add: description of your changes"

# Push to your fork
git push origin feature/your-feature-name

# Open Pull Request on GitHub
```

### Interactive Development

```bash
# Start REPL for interactive testing
rebar3 lfe repl

# Load your changes
> (c "src/your_module.lfe")

# Test functions
> (your_module:your_function args)
```

## How to Contribute

### Reporting Bugs

Use GitHub Issues with the following template:

```markdown
**Bug Description**
Clear description of the bug

**To Reproduce**
Steps to reproduce:
1. Start application with config X
2. Run command Y
3. Observe error Z

**Expected Behavior**
What you expected to happen

**Environment**
- OS: [e.g., Ubuntu 22.04]
- Erlang Version: [e.g., OTP 26]
- LFE Version: [e.g., 2.1.5]
- SafeBruteForce Version: [e.g., 0.1.0]

**Additional Context**
Logs, screenshots, etc.
```

### Suggesting Enhancements

```markdown
**Feature Description**
Clear description of the feature

**Use Case**
Why this feature is needed

**Proposed Implementation**
How you would implement it

**Ethical Considerations**
How does this maintain safety/ethical use?

**Alternatives Considered**
Other approaches you've thought about
```

### Pull Requests

#### PR Checklist

- [ ] Code follows LFE style guide
- [ ] All tests pass (`rebar3 lfe test`)
- [ ] New code has tests
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Commit messages are clear
- [ ] Safety mechanisms preserved
- [ ] No sensitive data in commits

#### PR Template

```markdown
## Description
What does this PR do?

## Motivation
Why is this change needed?

## Changes
- List of changes
- Another change

## Testing
How was this tested?

## Checklist
- [ ] Tests pass
- [ ] Documentation updated
- [ ] Safety mechanisms intact

## Related Issues
Closes #123
```

## Coding Standards

### LFE Style Guide

#### Module Structure

```lisp
;;;; Module Title
;;;; Brief description

(defmodule module_name
  (export
   ;; Public API
   (public_function_1 1)
   (public_function_2 2))
  ;; Private functions not exported
  )

;;; ============================================================
;;; API Functions
;;; ============================================================

(defun public_function_1 (arg)
  "Docstring describing function"
  ;; Implementation
  )

;;; ============================================================
;;; Internal Functions
;;; ============================================================

(defun internal_helper (arg1 arg2)
  "Internal helper function"
  ;; Implementation
  )
```

#### Naming Conventions

```lisp
;; Functions: lowercase with hyphens
(defun calculate-checksum (data) ...)

;; Private functions: prefix with dash
(defun -internal-helper (data) ...)

;; Predicates: end with ?
(defun valid-pattern? (pattern) ...)

;; Constants: uppercase
(defun max-retries () 5)

;; Pattern matching
(defun process-result
  (('success data) ...)
  (('failure reason) ...)
  (('error error) ...))
```

#### Comments and Documentation

```lisp
;; Single line comments for code explanation

;;; Section dividers for major sections

;;;; Module-level comments at top

(defun documented-function (arg1 arg2)
  "This is a docstring explaining what the function does.

   Args:
     arg1 - Description of arg1
     arg2 - Description of arg2

   Returns:
     Description of return value"
  ;; Implementation
  )
```

### Error Handling

```lisp
;; Always return tagged tuples
(defun safe-operation (input)
  (try
    (let ((result (risky-operation input)))
      (tuple 'ok result))
    (catch
      ((tuple 'error reason)
       (tuple 'error reason))
      ((tuple type error)
       (tuple 'error (tuple type error))))))

;; Use pattern matching for results
(case (safe-operation data)
  ((tuple 'ok result)
   (handle-success result))
  ((tuple 'error reason)
   (handle-error reason)))
```

### Testing Standards

```lisp
;;;; Module Tests

(defmodule module_tests
  (export all))

(include-lib "eunit/include/eunit.hrl")

(defun simple_test ()
  "Test basic functionality"
  (let ((result (module:function arg)))
    (eunit:assert_equal expected result)))

(defun edge_case_test ()
  "Test edge cases"
  (eunit:assert (module:predicate? edge-input)))

(defun error_handling_test ()
  "Test error conditions"
  (case (module:risky-function bad-input)
    ((tuple 'error _) 'ok)
    (_ (eunit:assert_failed "Should have returned error"))))
```

## Testing

### Running Tests

```bash
# All tests
rebar3 lfe test

# Specific module
rebar3 lfe test --module=sbf_patterns_tests

# With coverage
rebar3 lfe test --cover
```

### Test Requirements

Every new feature must include:

1. **Unit tests** - Test individual functions
2. **Integration tests** - Test component interactions
3. **Edge case tests** - Test boundary conditions
4. **Error tests** - Test error handling

### Test Safety

Tests must:
- Use mock/local targets only
- Not make external network calls (unless mocked)
- Not test against real systems
- Include safety pause verification

```lisp
(defun safety_pause_test ()
  "Verify safety pause triggers correctly"
  (let ((config (list (tuple 'pause_interval 5)
                     (tuple 'safety_enabled 'true))))
    ;; Test pause triggers at correct interval
    ;; ...
    ))
```

## Documentation

### Required Documentation

When adding features, update:

1. **Code comments** - Inline documentation
2. **Docstrings** - Function documentation
3. **README.md** - If feature is user-facing
4. **docs/USAGE.md** - Usage examples
5. **CHANGELOG.md** - Version history
6. **CLAUDE.md** - AI assistant guidance (if architecture changes)

### Documentation Style

```markdown
# Feature Name

## Overview
Brief description of feature

## Usage
```lisp
(example:code "here")
```

## Parameters
- `param1` - Description
- `param2` - Description

## Returns
Description of return value

## Examples
```lisp
;; Example 1: Basic usage
(example:basic)

;; Example 2: Advanced usage
(example:advanced options)
```

## Notes
Any important notes or warnings
```

## Security Considerations

### Security Review Checklist

All PRs must pass security review:

- [ ] No hardcoded credentials
- [ ] Input validation implemented
- [ ] Rate limiting respected
- [ ] Safety pause mechanism intact
- [ ] No sensitive data in logs
- [ ] Authorization checks present
- [ ] Error messages don't leak info
- [ ] Dependencies are trusted

### Responsible Disclosure

If you discover a security vulnerability:

1. **DO NOT** create a public issue
2. Email security@[domain] with details
3. Allow reasonable time for fix
4. Follow coordinated disclosure

### Safety Mechanism Policy

**Never submit PRs that:**
- Disable safety pause by default
- Remove authorization checks
- Bypass rate limiting
- Enable mass/distributed attacks
- Implement evasion techniques

## Getting Help

### Resources

- **Documentation**: Read `docs/` directory
- **Examples**: Check `examples/` directory
- **Tests**: Look at existing tests for patterns
- **CLAUDE.md**: Guidance for understanding architecture

### Communication

- **GitHub Issues**: Bug reports and feature requests
- **Pull Requests**: Code discussions
- **Discussions**: General questions and ideas

### Maintainer Contact

- Create an issue for project-related questions
- Email for security concerns
- Tag `@maintainer` in discussions

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Credited in release notes
- Acknowledged in README.md

Thank you for helping make SafeBruteForce better! 🛡️
