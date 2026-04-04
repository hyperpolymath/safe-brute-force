# CLAUDE.md - AI Assistant Guide for SafeBruteForce

## Project Overview

**SafeBruteForce** is a controlled, ethical brute-force utility designed for authorized security testing and penetration testing engagements. Unlike traditional brute-force tools that flood systems recklessly, this project prioritizes safety, user control, and system preservation.

### Key Principles

1. **Safety First**: Automatic pauses every 25 attempts requiring user confirmation
2. **Ethical Use Only**: Designed exclusively for authorized security testing, CTF challenges, and systems you own
3. **Controlled Execution**: Pausable, resumable, and trackable brute-force operations
4. **Clean Output**: Filtered results instead of millions of verbose log lines

## Technology Stack

- **Language**: LFE (Lisp Flavored Erlang)
- **Runtime**: Erlang/OTP (v26+)
- **Build Tool**: Rebar3
- **Paradigm**: Concurrent, stateful, functional programming

## Architecture (Planned)

### Core Components

1. **Pause Mechanism**: State machine that halts execution every 25 attempts
2. **Pattern Generators**: Customizable permutation/combination strategies
3. **Result Aggregation**: Success/failure tracking with clean output filtering
4. **Checkpoint System**: Save/restore capability for long-running operations
5. **Concurrent Engine**: Leverages Erlang's actor model for parallel attempts

### Expected File Structure

```
safe-brute-force/
├── src/
│   ├── sbf.lfe              # Main entry point
│   ├── sbf_state.lfe        # State management
│   ├── sbf_patterns.lfe     # Permutation generators
│   ├── sbf_executor.lfe     # Execution engine
│   └── sbf_output.lfe       # Result aggregation
├── test/
│   └── sbf_tests.lfe        # Unit tests
├── config/
│   └── sys.config           # Application configuration
├── rebar.config             # Build configuration
└── README.md
```

## Ethical Considerations

### When to Assist

✅ **APPROVED USE CASES**:
- Authorized penetration testing with written permission
- CTF (Capture The Flag) competitions
- Security research on owned systems
- Educational demonstrations with test environments
- Password strength validation on user's own accounts

### When to Refuse

❌ **FORBIDDEN USE CASES**:
- Unauthorized access attempts on third-party systems
- Credential stuffing or account takeover attacks
- DoS/DDoS-style mass requests
- Circumventing rate limits on production systems
- Any illegal or unethical hacking activities

### Assistance Guidelines

When helping users with this project:

1. **Always verify context**: Ask about authorization and intended use case
2. **Emphasize safety features**: Ensure pause mechanisms are enabled
3. **Encourage responsible testing**: Recommend rate limiting and respectful requests
4. **Document assumptions**: Help users track which combinations have been tested
5. **Promote best practices**: Suggest logging, checkpoints, and graceful termination

## Development Status

**Current Phase**: Initial Setup

The repository currently contains:
- README.md with project vision
- LICENSE (MIT)
- .gitignore

**Next Steps for Implementation**:
1. Set up Rebar3 project structure
2. Implement core LFE modules
3. Build pause/resume state machine
4. Create pattern generation strategies
5. Add result filtering and output formatting
6. Implement checkpoint/restore functionality
7. Write comprehensive tests

## How to Help Users

### Common Assistance Scenarios

#### 1. Project Setup
Help users:
- Install Erlang/OTP and LFE
- Configure Rebar3
- Set up project structure
- Initialize test framework

#### 2. Pattern Generation
Assist with:
- Designing permutation strategies (charset combinations, wordlist mutations)
- Implementing custom generators in LFE
- Optimizing pattern generation for efficiency

#### 3. State Management
Guide on:
- Building the pause mechanism (GenServer/gen_statem patterns)
- Checkpoint serialization
- Resume from saved state

#### 4. Concurrency
Advise on:
- Concurrent worker pools
- Rate limiting strategies
- Supervision trees
- Error handling and retry logic

#### 5. Output Filtering
Help with:
- Result aggregation logic
- Success/failure detection patterns
- Clean console output formatting

## LFE/Erlang Quick Reference

### Key Concepts
- **Processes**: Lightweight actors (not OS threads)
- **Message Passing**: Asynchronous communication between processes
- **Supervision**: OTP behaviors for fault tolerance
- **Pattern Matching**: Core to Erlang/LFE syntax
- **Immutability**: No variable reassignment

### Useful Patterns for This Project

```lisp
;; Example state machine pattern
(defmodule sbf-state
  (behaviour gen_statem)
  (export (start_link 0) (callback_mode 0)))

;; Example pattern generator
(defun generate-combinations (charset length)
  ;; Returns lazy sequence of permutations
  )

;; Example pause check
(defun should-pause? (attempt-count)
  (== (rem attempt-count 25) 0))
```

## Testing Guidance

When helping with tests:
- Ensure tests use safe, local-only targets
- Create mock endpoints for brute-force testing
- Verify pause mechanism activates correctly
- Test checkpoint/resume functionality
- Validate output filtering accuracy

## Security Notes

This tool is designed for **defensive security**:
- Help organizations test their own systems
- Validate password policies
- Demonstrate authentication vulnerabilities
- Educational purposes in controlled environments

**Never assist with**:
- Bypassing authentication on unauthorized systems
- Circumventing security controls maliciously
- Mass credential testing without permission

## Resources

- [LFE Documentation](https://lfe.io/)
- [Erlang OTP Design Principles](https://www.erlang.org/doc/design_principles/users_guide.html)
- [Rebar3 Documentation](https://rebar3.org/)
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)

## Support and Contributions

When users want to contribute:
1. Ensure they understand ethical implications
2. Review code for safety mechanisms
3. Test with local/authorized systems only
4. Document permutation strategies clearly
5. Maintain the "🛡️ Safety First" principle

---

**Remember**: This is a tool for authorized security testing. Always verify the user has permission before assisting with any brute-force implementation.
