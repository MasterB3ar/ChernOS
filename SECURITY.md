# Security Policy

This document explains how to report security vulnerabilities in **ChernOS** and how disclosures are handled.

## Supported versions

Security fixes are provided for:
- The **latest tagged release**
- The **current `main`/default branch** (when applicable)

If you're using an older build, please try to reproduce the issue on the latest release first.

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security-sensitive reports.

Preferred reporting method:
1. Use **GitHub Security Advisories** for the repository (a private report to maintainers).

If that is not possible:
- Send a private message to the project maintainer(s) via GitHub, or
- If you must file an issue to get attention, **omit exploit details**, include only a high-level description, and clearly mark it as **SECURITY**.

Include as much of the following as you can:
- Affected version(s) / commit SHA
- What component is affected (ISO build, UI, Electron suite, plugins, persistence, etc.)
- Impact (what an attacker can do)
- Reproduction steps or proof-of-concept (private only)
- Any logs / screenshots that help confirm the issue

## What to expect

- **Acknowledgement:** typically within 7 days
- **Status updates:** as the investigation progresses
- **Fix & release:** timeline depends on severity and complexity

## Coordinated disclosure

Please allow time for the issue to be validated and fixed before public disclosure.
Once a fix is available, the maintainers may:
- Publish release notes describing the vulnerability at a high level
- Credit the reporter (optional, with your permission)

Thank you for helping keep ChernOS safer.
