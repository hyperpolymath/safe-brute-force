# Security Best Practices

## Legal and Ethical Considerations

### Authorization is Mandatory

**⚠️ CRITICAL: You must have explicit written authorization before testing any system.**

SafeBruteForce is designed for:
- ✅ Authorized penetration testing engagements
- ✅ CTF (Capture The Flag) competitions
- ✅ Security research on systems you own
- ✅ Educational demonstrations in controlled environments
- ✅ Password policy validation for your own organization

SafeBruteForce must NEVER be used for:
- ❌ Unauthorized access to third-party systems
- ❌ Credential stuffing or account takeover attacks
- ❌ Testing systems without written permission
- ❌ Circumventing security controls maliciously
- ❌ Any activity that violates laws or regulations

### Legal Frameworks

Be aware of applicable laws:
- **CFAA (USA)**: Computer Fraud and Abuse Act
- **GDPR (EU)**: Data protection regulations
- **DMCA (USA)**: Anti-circumvention provisions
- **Local laws**: Vary by jurisdiction

**Violation of these laws can result in criminal prosecution and civil liability.**

## Responsible Testing Practices

### 1. Documentation and Authorization

Before starting any test:

```markdown
[ ] Obtain written authorization from system owner
[ ] Document scope of testing (URLs, accounts, timeframes)
[ ] Establish emergency contact procedures
[ ] Define acceptable impact levels
[ ] Get sign-off from legal/compliance team
[ ] Review and accept terms of service
```

### 2. Scope Limitation

```lisp
;; Example: Limit testing to specific endpoint
(let ((target-config
       (list (tuple 'type 'http)
             (tuple 'url "http://test.example.com/authorized-test-endpoint")
             ;; NOT: http://example.com/* (too broad)
             )))
  (sbf:run pattern-config target-config))
```

### 3. Rate Limiting

Always configure appropriate rate limits:

```erlang
%% Conservative rate limiting
{safe_brute_force, [
    {rate_limit, 10},          % Max 10 requests per second
    {request_timeout, 5000},   % 5 second timeout
    {max_workers, 3}           % Limited concurrency
]}
```

### 4. Time Windows

Conduct testing during agreed-upon windows:

```bash
# Example: Only test between 2-4 AM
# Use cron or manual scheduling
0 2 * * * /path/to/sbf_cli wordlist passwords.txt http://test.example.com
```

### 5. Monitoring and Logging

Maintain comprehensive logs:

```lisp
;; Enable detailed logging
(sbf_logger:set_level 'info)

;; Log to file
(sbf_logger:log_to_file "logs/test-session-2025-01-15.log"
                        "Starting authorized test")
```

## Technical Security Measures

### Defense Against Misuse

#### 1. Mandatory Safety Pause

The built-in safety pause cannot be disabled in production:

```erlang
%% This setting should ALWAYS be true in production
{safety_enabled, true}
```

#### 2. Authorization Verification

The CLI includes authorization checks:

```bash
$ ./sbf_cli wordlist passwords.txt http://example.com
⚠️  AUTHORIZATION CHECK ⚠️
You must have written authorization to test this system.
Do you have authorization to test this system? (yes/no):
```

#### 3. User Agent Identification

HTTP requests identify themselves:

```erlang
%% Default User-Agent header
{"User-Agent", "SafeBruteForce/0.1.0 (Authorized Testing)"}
```

This allows system administrators to:
- Identify brute-force attempts
- Distinguish authorized tests from attacks
- Apply appropriate rate limiting

### Protecting Your Own Systems

If you're a system administrator, protect against brute-force attacks:

#### 1. Rate Limiting

```nginx
# Nginx example
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;

location /login {
    limit_req zone=login burst=3 nodelay;
}
```

#### 2. Account Lockout

```python
# Example: Lock account after 5 failed attempts
failed_attempts = get_failed_attempts(username)
if failed_attempts >= 5:
    lock_account(username, duration=timedelta(minutes=15))
```

#### 3. CAPTCHA

Implement CAPTCHA after multiple failures:

```javascript
if (failedAttempts >= 3) {
    requireCaptcha = true;
}
```

#### 4. Multi-Factor Authentication

Require MFA for sensitive accounts:
- Time-based OTP (TOTP)
- SMS verification
- Hardware tokens (YubiKey, etc.)

#### 5. Monitoring and Alerting

```python
# Alert on suspicious patterns
if (failed_attempts > 10 and time_window < 60):
    send_alert("Possible brute-force attack detected")
```

## Data Protection

### 1. Credential Storage

**NEVER store discovered credentials in plain text:**

```lisp
;; BAD: Don't do this
(defun save_found_password (password)
  (file:write_file "found_passwords.txt" password))

;; GOOD: Use secure reporting
(defun report_vulnerability (pattern metadata)
  (let ((report (map 'timestamp (erlang:system_time 'second)
                     'pattern_type "redacted"
                     'metadata metadata)))
    (sbf_logger:log 'success "Vulnerability confirmed" report)))
```

### 2. Result Handling

```lisp
;; Filter sensitive data from logs
(defun sanitize_results (results)
  (lists:map
   (lambda ((tuple pattern result data))
     (tuple "***REDACTED***" result (map 'success 'true)))
   results))
```

### 3. Checkpoint Security

Checkpoints may contain sensitive data:

```bash
# Protect checkpoint directory
chmod 700 priv/checkpoints

# Encrypt sensitive checkpoints
gpg -c priv/checkpoints/session_*.checkpoint

# Delete after use
rm -P priv/checkpoints/*.checkpoint
```

## Incident Response

### If You Discover a Vulnerability

1. **Stop testing immediately** upon finding an actual vulnerability
2. **Document the finding** without exploiting further
3. **Follow responsible disclosure**:
   - Contact the system owner privately
   - Provide reasonable time to patch (typically 90 days)
   - Do not publicly disclose until patched
4. **Report through proper channels**:
   - security@organization.com
   - Bug bounty programs (HackerOne, Bugcrowd)
   - CERT/CC for critical infrastructure

### If Unauthorized Testing is Detected

If you accidentally test an unauthorized system:

1. **Stop immediately**
2. **Contact the system owner** and explain the mistake
3. **Provide logs** if requested
4. **Delete all collected data**
5. **Document the incident** for your records

## Compliance and Governance

### Penetration Testing Agreement Template

```markdown
# Penetration Testing Agreement

**Client**: [Organization Name]
**Tester**: [Your Name/Company]
**Date**: [YYYY-MM-DD]

## Scope
- Target Systems: [Specific URLs, IP ranges, applications]
- Testing Methods: Brute-force authentication testing
- Timeframe: [Start Date] to [End Date]
- Authorized Hours: [e.g., 2:00 AM - 4:00 AM UTC]

## Limitations
- Maximum request rate: [e.g., 10 requests/second]
- Excluded systems: [List any off-limits systems]
- Data restrictions: [e.g., no data exfiltration]

## Responsibilities
- Tester will: [List obligations]
- Client will: [List obligations]

## Emergency Contact
- Name: [Contact]
- Phone: [Number]
- Email: [Address]

**Signatures**
Client: _________________ Date: _______
Tester: _________________ Date: _______
```

### Audit Trail

Maintain comprehensive records:

```lisp
;; Log all activities
(defun audit_log (action details)
  (let ((entry (map 'timestamp (erlang:system_time 'second)
                    'action action
                    'details details
                    'user (whoami))))
    (sbf_logger:log_to_file "audit.log"
                            (format_audit_entry entry))))
```

## Ethical Guidelines

### The SafeBruteForce Code of Ethics

1. **Authorization First**: Never test without permission
2. **Minimize Impact**: Use rate limiting and timeboxing
3. **Responsible Disclosure**: Report vulnerabilities privately
4. **Data Protection**: Handle discovered credentials securely
5. **Continuous Compliance**: Stay updated on laws and regulations
6. **Professional Standards**: Follow industry best practices (OWASP, NIST)
7. **Transparency**: Clearly identify your testing activity
8. **Accountability**: Maintain audit trails and documentation

## Resources

### Legal and Compliance
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [ISO 27001 Information Security](https://www.iso.org/isoiec-27001-information-security.html)

### Responsible Disclosure
- [Bugcrowd Disclosure Guidelines](https://www.bugcrowd.com/resources/glossary/responsible-disclosure/)
- [HackerOne Disclosure Guidelines](https://www.hackerone.com/disclosure-guidelines)

### Penetration Testing Standards
- [PTES (Penetration Testing Execution Standard)](http://www.pentest-standard.org/)
- [OSSTMM (Open Source Security Testing Methodology Manual)](https://www.isecom.org/OSSTMM.3.pdf)

## Contact

For security concerns about SafeBruteForce itself:
- Email: security@[your-domain]
- PGP Key: [Key ID]
- Responsible Disclosure Policy: [URL]

---

**Remember: With great power comes great responsibility. Use SafeBruteForce ethically and legally.**
