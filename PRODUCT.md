# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

- **Super Admin**: System-wide platform administrator managing global multi-tenant infrastructure, universities, global security policies, and high-level audit logs.
- **Principal / Director**: Institutional executive head leading campus operations, executive governance, accreditation standards, and institutional performance metrics.
- **Office Admin**: Campus operations staff managing student registrations, fee records, facilities, staff administrative workflows, and institutional paperwork.
- **Head of Department (HOD)**: Departmental leader managing faculty assignments, curriculum scheduling, cohort progress, and departmental performance.
- **Faculty / Class Tutor**: Educators and academic advisors managing daily classes, student coursework, attendance, grading, and direct student mentorship.
- **Student Union**: Elected student body council overseeing campus initiatives, student welfare, event approvals, and student governance.
- **Club Admin**: Student club leaders and organization coordinators managing memberships, campus events, announcements, and budgets.
- **Student**: Undergraduate, postgraduate, and diploma learners accessing courses, schedules, campus activities, club events, grades, and campus services.

## Product Purpose

CampVerse is a comprehensive, multi-tenant campus operating ecosystem and academic enterprise suite. It unifies administrative governance, departmental logistics, academic delivery, student organizations, and campus life into a singular, responsive platform across mobile and desktop.

## Positioning

Unlike fragmented legacy campus portals or disparate learning management point-solutions, CampVerse provides a single hierarchical multi-tenant structure (University -> Institute -> Department -> Cohort) powered by granular role-based access control, modern authentication (Passkeys/WebAuthn, biometric login, multi-factor verification), and role-tailored workspace shells for every member of the academic hierarchy.

## Operating Context

- **Environments**: Cross-platform web browsers on desktop/laptops for dense management and operations, alongside native mobile and tablet apps on iOS and Android for on-the-go student and faculty access.
- **Workflows**: Modern authentication (Passkeys / WebAuthn, Supabase Auth) -> Multi-Factor Verification (TOTP, Email OTP) -> Role Picker & Dynamic Workspace Routing -> Role-Tailored Dashboard Shells (Super Admin, Principal, Office Admin, HOD, Faculty, Student Union, Club Admin, Student).
- **System Architecture**: Flutter front-end client with Riverpod state management and GoRouter, supported by Supabase (PostgreSQL with Row-Level Security), Go and Deno microservices, and Caddy reverse proxy API gateway.

## Capabilities and Constraints

- **Multi-Tenant Hierarchy**: Structured multi-tier data model from universities down to departments, faculty, clubs, and student cohorts.
- **Robust Multi-Role Security**: 8 distinct PostgreSQL-enforced roles (`super_admin`, `principal`, `office_admin`, `student_union`, `hod`, `faculty`, `club_admin`, `student`) with dynamic role-switching capabilities for multi-role users.
- **Modern Authentication & MFA**: Support for WebAuthn/Passkeys, biometric authentication, email magic links/passwords, and TOTP/Email OTP verification.
- **Audit Logging & Governance**: Immutable audit logs capturing administrative operations and security events.
- **Adaptive Multiplatform Experience**: Seamless responsive layout adapting between dense desktop web tables/dashboards and compact mobile touch navigation.
- **Constraints**: Strict zero-leakage Row-Level Security (RLS) enforcement at the database layer; high performance requirements across native and web Flutter builds.

## Brand Commitments

- **Name**: CampVerse
- **Visual Identity**: Modern, clean, authoritative yet vibrant academic identity with distinct, bespoke dual-mode role-based color coding (designed with editorial restraint, eliminating generic AI-palette saturated cliches):
  - Super Admin: Obsidian Mulberry (`#581C87` Light / `#C084FC` Dark)
  - Principal: Oxford Navy (`#1E3A8A` Light / `#93C5FD` Dark)
  - Office Admin: Deep Mineral Slate (`#334155` Light / `#94A3B8` Dark)
  - Head of Department (HOD): Aegean Cobalt (`#1D4ED8` Light / `#60A5FA` Dark)
  - Faculty: Evergreen Pine (`#065F46` Light / `#34D399` Dark)
  - Student Union: Burnt Terracotta (`#9A3412` Light / `#FB923C` Dark)
  - Club Admin: Velvet Crimson (`#9F1239` Light / `#FB7185` Dark)
  - Student: Caspian Cerulean (`#0369A1` Light / `#38BDF8` Dark)
- **Design System**: Material Design 3 foundation with Google Fonts typography (Outfit display + Inter body), default light theme with dark mode toggle, and glassmorphic accents.

## Evidence on Hand

- Database migrations with complete relational schema, RLS policies, enums, and triggers (`supabase/migrations/`).
- Auth helper functions and seed scripts for initial super admin and institute data (`services/deno_core/scripts/seed_super_admin.ts`).
- Production-ready Flutter client codebase (`campverse_client/lib/`) with role-specific shells, authentication flows, theme definitions, and router guards.

## Product Principles

- **Role-Centric Clarity**: Every user lands in an interface tailored specifically to their tasks, eliminating extraneous noise while keeping vital tools one tap away.
- **Security-First Architecture**: End-to-end security enforced from hardware biometric passkeys and MFA down to database-level RLS policies.
- **Adaptive Multi-Platform Fluidity**: Zero friction transition between high-density desktop management dashboards and intuitive mobile interfaces.
- **Institutional Integrity**: Complete traceability, transparent organizational hierarchies, and verifiable audit trails.

## Accessibility & Inclusion

- Adherence to WCAG AA contrast ratios across all role-themed color schemes and light/dark modes.
- Full keyboard navigability for desktop web administrative screens.
- Screen reader accessibility and dynamic font scaling support across mobile and web Flutter targets.
