# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 1.x     | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in CropVision, please report it responsibly. **Do NOT open a public GitHub issue.**

### How to Report

1. **Email**: Send a detailed report to **cropvision-team@users.noreply.github.com**
2. **Subject**: `[SECURITY] Brief description of the vulnerability`
3. **Include**:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)
   - Your contact information for follow-up

### What to Expect

- **Acknowledgment**: We will acknowledge receipt within **48 hours**
- **Assessment**: Initial assessment within **5 business days**
- **Resolution**: We aim to resolve critical vulnerabilities within **30 days**
- **Disclosure**: We will coordinate disclosure timing with you

### Scope

The following are in scope for security reports:

| Component | In Scope |
|-----------|----------|
| Supabase RLS policies | ✅ |
| API authentication & authorization | ✅ |
| Edge function endpoints | ✅ |
| Data privacy (farmer data) | ✅ |
| Mobile app data storage | ✅ |
| Model inference manipulation | ✅ |
| Environment variable exposure | ✅ |

### Out of Scope

- Vulnerabilities in third-party dependencies (report to the respective project)
- Issues requiring physical access to a device
- Social engineering attacks
- Denial of service attacks

### Safe Harbor

We support responsible disclosure. If you report in good faith and follow these guidelines, we will not pursue legal action against you.

## Security Best Practices for Contributors

- **Never** commit API keys, credentials, or secrets to the repository
- Use `.env` files for sensitive configuration (see `.env.example`)
- Ensure all database tables have Row-Level Security (RLS) enabled
- Validate and sanitize all user inputs
- Use parameterized queries — never string-concatenate SQL
- Keep dependencies updated to their latest secure versions

## Known Security Considerations

### Farmer Data Privacy

CropVision processes agricultural data including:
- GPS coordinates of farm plots
- Crop health photographs
- Diagnosis history

All data is protected by:
- Supabase Row-Level Security (user-scoped access)
- Encrypted connections (TLS/SSL)
- No plaintext credential storage on-device
