# Changelog

All notable changes to SafeBruteForce will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-15

### Added

#### Core Features
- **State Management**: gen_statem-based state machine for pause/resume functionality
- **Pattern Generation**: Multiple strategies (wordlist, charset, sequential, custom)
- **Execution Engine**: Concurrent worker pool with gen_server
- **Result Aggregation**: Filtered output and statistics tracking
- **Checkpoint System**: Save/restore capability for long-running operations
- **Safety Mechanisms**: Automatic pause every 25 attempts with user confirmation

#### Modules
- `sbf.lfe` - Main API and entry point
- `sbf_app.lfe` - OTP application behavior
- `sbf_sup.lfe` - Supervision tree
- `sbf_state.lfe` - State machine (gen_statem)
- `sbf_executor.lfe` - Execution engine (gen_server)
- `sbf_patterns.lfe` - Pattern generation strategies
- `sbf_output.lfe` - Result formatting and filtering
- `sbf_checkpoint.lfe` - Checkpoint save/restore
- `sbf_logger.lfe` - Structured logging
- `sbf_progress.lfe` - Progress tracking with ETA
- `sbf_rate_limiter.lfe` - Token bucket rate limiting

#### Pattern Strategies
- Wordlist loading from files
- Wordlist mutations (leet speak, capitalization, suffixes)
- Charset combinations with configurable length
- Sequential number generation
- Common password lists
- Date pattern generation
- Custom pattern functions
- Keyboard pattern generator

#### Target Support
- HTTP/HTTPS endpoints (POST/GET)
- Custom validation functions
- Mock targets for testing
- JSON and URL-encoded body formats
- Custom headers support
- Success/failure pattern matching

#### Safety Features
- Automatic pause every N attempts (configurable, default 25)
- Manual pause/resume controls
- Rate limiting (token bucket algorithm)
- Authorization verification in CLI
- Audit logging
- User agent identification

#### CLI and Interface
- Interactive REPL support
- Command-line interface (sbf_cli)
- Authorization prompts
- Progress bars
- Colorized output
- Comprehensive help system

#### Documentation
- Comprehensive README with examples
- Usage guide (docs/USAGE.md)
- Security best practices (docs/SECURITY.md)
- Contributing guidelines (docs/CONTRIBUTING.md)
- CLAUDE.md for AI assistant guidance
- Inline code documentation
- Example code in examples/ directory

#### Testing
- Unit tests for all core modules
- State machine lifecycle tests
- Pattern generation tests
- Executor tests with mock targets
- Checkpoint save/restore tests
- Safety mechanism tests
- Integration tests

#### Examples
- HTTP login testing (examples/http_login_test.lfe)
- PIN code brute-forcing (examples/pin_code_test.lfe)
- Custom pattern generation (examples/custom_pattern_test.lfe)

#### Utilities
- Progress tracking with ETA calculation
- Structured logging with multiple levels
- Result export to files
- Checkpoint management
- Statistics dashboard
- Duration formatting
- Timestamp formatting

#### Wordlists
- Common passwords (60+ entries)
- Test wordlist for development
- Located in priv/wordlists/

#### Configuration
- Rebar3 project configuration
- OTP application configuration
- VM arguments for production
- Configurable pause interval
- Configurable rate limits
- Configurable worker pool size
- Configurable timeouts

### Security
- Safety mechanisms cannot be fully disabled
- Authorization checks in CLI
- Audit logging for accountability
- Responsible disclosure guidelines
- Clear ethical use documentation
- Rate limiting by default

### Developer Experience
- Full LFE/Erlang source code
- Comprehensive test suite
- Example applications
- Documentation for contributors
- Coding standards guide
- Interactive REPL development

## [Unreleased]

### Planned for v0.2.0
- SSH brute-force module
- FTP support
- Database connection testing
- Distributed worker support
- Web UI dashboard
- Enhanced reporting (PDF, HTML)
- Performance optimizations
- Additional pattern strategies
- More target protocol support

### Future Considerations
- Machine learning pattern generation
- Cloud integration (AWS, GCP, Azure)
- SIEM integration
- Custom plugin system
- Advanced analytics
- Real-time collaboration features
- Mobile app support

---

**Note**: This project follows ethical security testing principles. All features are designed for authorized testing only.
