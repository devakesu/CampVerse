# Design System: CampVerse

<!-- impeccable:design-schema 1 -->

## Design Philosophy & Identity

CampVerse is an authoritative, modern, and aesthetic academic enterprise operating system. The interface balances high-density administrative productivity with sleek, intuitive mobile campus workflows, designed with editorial restraint and avoiding generic AI saturated palettes.

## Default Theme & Adaptive Architecture

* **Default Theme**: **Light Theme** (clean academic slate paper with high-contrast obsidian slate typography).
* **Dark Mode**: Fully supported with luminous, low-glare dual-mode tokens.

| Device Class | Viewport Breakpoint | Primary Navigation | Header & Actions |
| :--- | :--- | :--- | :--- |
| **Mobile** (iOS / Android) | `< 768px` | Floating Glass Bottom Bar (`BackdropFilter`) | Compact Top App Bar + Drawer Sidebar |
| **Desktop** (Web, Windows, Linux, macOS) | `≥ 768px` | Permanent Left Sidebar (Collapsible) | Sleek Top Bar with Search, Actions & Role Switcher |

---

## Semantic Color System

### Base & Surface Colors

| Token | Light Theme (Default) | Dark Theme | Purpose |
| :--- | :--- | :--- | :--- |
| `background` | `#F8FAFC` (Slate 50 Canvas) | `#0B0F19` (Charcoal Ink) | Main canvas background |
| `surface` | `#FFFFFF` (Pure Crisp White) | `#111827` (Rich Obsidian Slate) | Card, modal, panel surfaces |
| `surfaceElevated` | `#F1F5F9` (Slate 100) | `#1E293B` (Elevated Slate) | Elevated containers & inputs |
| `surfaceBorder` | `#E2E8F0` (Slate 200) | `#283548` (Boundary Slate) | Crisp visible boundary lines |
| `glassBackground` | `rgba(255, 255, 255, 0.95)` | `rgba(17, 24, 39, 0.85)` | Frosted glass surfaces |
| `glassBorder` | `rgba(203, 213, 225, 0.5)` | `rgba(255, 255, 255, 0.15)` | Subtle glass highlight borders |

### Typography & Text Colors

| Token | Light Theme (Default) | Dark Theme | Contrast Ratio |
| :--- | :--- | :--- | :--- |
| `textPrimary` | `#0F172A` (Obsidian Slate 900) | `#F8FAFC` (Slate 50) | $\ge 12:1$ (AAA High contrast) |
| `textSecondary` | `#475569` (Slate 600) | `#CBD5E1` (Slate 300) | $\ge 6.5:1$ (AA+ Accessible body) |
| `textMuted` | `#64748B` (Slate 500) | `#94A3B8` (Slate 400) | $\ge 4.6:1$ (Placeholder & caption) |

### Brand & Functional Colors

| Role | Light Theme (Default) | Dark Theme | Purpose |
| :--- | :--- | :--- | :--- |
| `primary` | `#1D4ED8` (Royal Cobalt) | `#6366F1` (Luminous Indigo) | Primary brand action color |
| `accent` | `#0284C7` (Caspian Cerulean) | `#38BDF8` (Electric Sky) | Secondary interactive highlights |
| `success` | `#059669` (Pine Emerald) | `#10B981` (Vibrant Mint) | Positive statuses & success chips |
| `warning` | `#D97706` (Amber Ochre) | `#F59E0B` (Warm Amber) | Attention alerts & pending reviews |
| `error` | `#DC2626` (Rose Crimson) | `#EF4444` (Coral Red) | Destructive actions & errors |
| `info` | `#2563EB` (Aegean Blue) | `#3B82F6` (Electric Blue) | Informational badges & notices |

### 8 Bespoke Campus Role Badges (Dual-Mode Parity)

| Role | Light Theme (`Hex`) | Dark Theme (`Hex`) | Visual Metaphor & Character |
| :--- | :--- | :--- | :--- |
| **Super Admin** | `#581C87` (Obsidian Mulberry) | `#C084FC` (Royal Amethyst) | Platform governance, executive sovereignty |
| **Principal** | `#1E3A8A` (Oxford Midnight Navy) | `#93C5FD` (Glacier Periwinkle) | Institutional authority, collegiate seal |
| **Office Admin** | `#334155` (Deep Mineral Slate) | `#94A3B8` (Cool Quartz) | Operational rigor, campus logistics |
| **HOD** | `#1D4ED8` (Aegean Cobalt) | `#60A5FA` (Celestial Sky) | Academic chair, curriculum leadership |
| **Faculty** | `#065F46` (Evergreen Forest) | `#34D399` (Luminous Mint Sage) | Pedagogy, academic growth & mentorship |
| **Student Union** | `#9A3412` (Burnt Terracotta) | `#FB923C` (Warm Apricot Sunset) | Democratic student voice & advocacy |
| **Club Admin** | `#9F1239` (Velvet Crimson) | `#FB7185` (Coral Blossom) | Campus culture, arts & vibrant community |
| **Student** | `#0369A1` (Caspian Cerulean) | `#38BDF8` (Electric Cerulean) | Learner workspace, curiosity & discovery |

---

## Typography Scale

* **Display & Headings**: Google Fonts `Outfit` (`FontWeight.w700` / `w800`, `letterSpacing: -0.5px`)
* **Body, Inputs & Data**: Google Fonts `Inter` (`FontWeight.w400` / `w500` / `w600`)

---

## Anti-AI-Cliche Directives

* **Zero generic gradient mush**: Only use crisp, single-hue accents and subtle elevation tints.
* **Zero unreadable transparency**: Always maintain at least $0.90$ opacity on frosted surfaces with backdrop blur.
* **Zero generic 3-card templates**: Structure layouts according to role-specific tasks and data density.
* **Zero emojis in UI navigation**: Use vector Material Icons with consistent 20-24dp scale.
