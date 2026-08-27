# Security Policy

> **Maintainer:** Ajay Elika ([@ajay99511](https://github.com/ajay99511)) — ajayelika99511@gmail.com

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security problems.**

Report vulnerabilities privately through GitHub Security Advisories:

1. Go to the **Security** tab of this repository.
2. Click **Report a vulnerability** (GitHub Private Vulnerability Reporting).
3. Fill in the advisory form with the details below.

### What to include

- A description of the vulnerability and its impact.
- Steps to reproduce (a minimal proof-of-concept if possible).
- Affected version(s) / commit, OS, and platform.
- Any relevant logs, stack traces, or screenshots.

### What to expect

- **Acknowledgement:** within **3 business days**.
- **Initial assessment:** within **7 business days**, including whether the
  report is accepted, needs more information, or is declined (with reasoning).
- **Fix & disclosure:** we aim to ship a fix for accepted, valid reports within
  **90 days**. We will coordinate a disclosure timeline with you and credit you
  in the release notes unless you prefer to remain anonymous.

## Scope

Chronos Planner is a **desktop-first** time-management application. Areas of
particular interest:

- Local data exposure or insecure file handling of task/schedule data.
- Path traversal or injection via crafted input (task names, descriptions).
- Insecure inter-process communication or exported interfaces.

Out of scope: issues that require physical access to an unlocked machine, and
reports against unsupported versions.
