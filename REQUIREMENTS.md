# Software Requirements Specification (SRS)
## Hotel Booking System — Authentication Enhancement
**Project:** abooking.site — Social Login & KYC Verification
**Client:** Vincent (Sheng Wen)
**Prepared by:** Kotchamon (Team)
**Date:** 2026-03-20
**Version:** 1.0

---

## 1. Project Overview

The client operates an existing hotel room booking website. This project extends the authentication system to support third-party social login, syncs user profile data from the identity provider, and introduces a KYC (Know Your Customer) passport verification workflow with an admin review interface.

---

## 2. Scope

This document covers:
- Social (OAuth/OpenID) login integration
- Profile data synchronisation from identity provider
- Passport-based KYC cross-check and manual admin verification
- SSL certificate installation
- Constraints on server management and deployment process

Out of scope for this phase:
- KYC using ID types other than passport
- Additional identity providers beyond the one selected

---

## 3. Stakeholders

| Role | Name | Responsibility |
|------|------|----------------|
| Client | Vincent (Sheng Wen) | Requirements owner, final approver |
| Development Team | Kotchamon + Team | Design, development, testing, deployment |

---

## 4. Functional Requirements

### FR-1: Social / Third-Party Login

| ID | Requirement |
|----|-------------|
| FR-1.1 | The login screen SHALL provide an option for users to authenticate using a supported third-party identity provider (e.g., Google, Facebook). |
| FR-1.2 | Exactly one (1) identity provider SHALL be supported in this phase. The specific provider shall be agreed upon with the client before implementation. |
| FR-1.3 | The authentication flow SHALL use a standard protocol (OAuth 2.0 / OpenID Connect). |
| FR-1.4 | Existing username/password login SHALL remain fully functional and unaffected. |
| FR-1.5 | A new user who signs up via social login SHALL have an account created automatically in the system. |
| FR-1.6 | A returning user who previously signed up with the same email via social login SHALL be recognised and logged in to their existing account. |

---

### FR-2: Profile Data Synchronisation from Identity Provider

| ID | Requirement |
|----|-------------|
| FR-2.1 | Upon social login or social sign-up, the system SHALL request and retrieve the following fields from the identity provider (where available): full name, date of birth, and profile photo. |
| FR-2.2 | Retrieved profile data SHALL be stored against the user's account in the database. |
| FR-2.3 | If a user already exists and their profile fields are empty, the retrieved data SHALL populate those fields. |
| FR-2.4 | The system SHALL handle cases where the identity provider does not return certain fields gracefully (i.e., missing fields shall not cause errors). |

---

### FR-3: KYC — Passport Verification & Cross-Check

| ID | Requirement |
|----|-------------|
| FR-3.1 | The system SHALL support passport-only KYC submission. No other ID types are in scope for this phase. |
| FR-3.2 | When a user authenticates via social login, the system SHALL cross-check the profile data fetched from the identity provider (name, date of birth, photo) against the KYC data stored in the system for that user. |
| FR-3.3 | If the cross-check detects an inconsistency between identity-provider data and KYC data, the system SHALL automatically flag the user's account for manual admin verification. |
| FR-3.4 | A flagged account SHALL have its booking capability withheld (suspended) until an admin completes manual review and clears the flag. |
| FR-3.5 | The user SHALL be informed (via on-screen message) that their account is under review and that bookings are temporarily unavailable. |

---

### FR-4: Admin — Manual Verification Page

| ID | Requirement |
|----|-------------|
| FR-4.1 | The admin interface SHALL include a dedicated "KYC Verification" page (or section) listing all flagged user accounts. |
| FR-4.2 | For each flagged account, the page SHALL display: user identity, the KYC passport data, the identity-provider profile data, and the specific field(s) causing the mismatch. |
| FR-4.3 | The admin SHALL be able to approve (clear the flag and allow booking) or reject (keep the flag, optionally with a note) each flagged account. |
| FR-4.4 | All admin verification actions SHALL be logged with a timestamp and the admin's username. |

---

### FR-5: SSL / HTTPS

| ID | Requirement |
|----|-------------|
| FR-5.1 | The web server SHALL be secured with a valid SSL certificate before the social login feature is deployed to production. |
| FR-5.2 | A free 3-month certificate from a provider such as ZeroSSL SHALL be obtained and configured. |
| FR-5.3 | All HTTP traffic SHALL be redirected to HTTPS. |
| FR-5.4 | SSL configuration SHALL be applied as part of the technical implementation if it is a prerequisite for the OAuth redirect flow (which it typically is). |

---

## 5. Non-Functional Requirements

| ID | Category | Requirement |
|----|----------|-------------|
| NFR-1 | Security | OAuth tokens and session credentials SHALL NOT be stored in plain text. |
| NFR-2 | Security | Server credentials and database passwords SHALL NOT be committed to version control or shared with any third party. |
| NFR-3 | Security | The implementation SHALL not introduce new SQL injection, XSS, or CSRF vulnerabilities. |
| NFR-4 | Reliability | The system SHALL degrade gracefully if the identity provider is unavailable (fall back to standard login with a user-facing message). |
| NFR-5 | Maintainability | All new code SHALL be tested in a local environment before deployment to the production server. |
| NFR-6 | Availability | Any planned deployment to the live server SHALL be announced on the website and to the client in advance. |
| NFR-7 | Data | A private backup of the server data SHALL be taken before any changes are applied to the production server. |

---

## 6. Constraints

| ID | Constraint |
|----|------------|
| CON-1 | No additional services may be installed on the server without written client approval. |
| CON-2 | No graphical/desktop interface may be installed on the server (RAM limitation). |
| CON-3 | No server configuration changes may be made without a written request to the client. |
| CON-4 | Server passwords SHALL NOT be changed. |
| CON-5 | Testing SHALL be performed in a local environment first; the production server is not a test environment. |
| CON-6 | The existing database is relational and PHP-based. The team shall reverse-engineer the schema from the existing PHP source code to understand the data model before making any changes. |
| CON-7 | The database root credentials are embedded in the PHP source code and must be discovered through code review. |

---

## 7. Assumptions

- The chosen identity provider supports OAuth 2.0 / OpenID Connect and provides name, date of birth, and photo in its user profile API scope.
- The existing database schema has a users table with fields suitable for storing or extending with social-login identifiers (or such fields will be added via a migration).
- The existing website is PHP-based and can be extended without a full rewrite.
- PHPMyAdmin is available for database inspection at `[domain]/phpmyadmin`.

---

## 8. Out of Scope

- KYC for ID types other than passport
- More than one third-party identity provider
- Any mobile application
- Changes to the core hotel booking or room management logic

---

## 9. Definitions

| Term | Definition |
|------|------------|
| OAuth 2.0 | Industry-standard protocol for authorisation, used here for social login |
| OpenID Connect (OIDC) | Identity layer on top of OAuth 2.0 that provides user profile information |
| KYC | Know Your Customer — the process of verifying a user's identity against official documentation |
| Identity Provider (IdP) | A third-party service (e.g., Google) that authenticates users and provides profile data |
| Flag | A status set on a user account indicating it requires manual admin review |

---

## 10. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-03-20 | Kotchamon | Initial draft based on client email (Mar 10 & Mar 20, 2026) |
