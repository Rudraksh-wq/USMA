# USMA Accessibility & Localization Guide

This document outlines the accessibility (a11y) and localization standards implemented across USMA (Unified Scholarship Mobile Application) for MoTA ST students.

## 1. Standards & Compliance
- **WCAG 2.1 AA Compliance:**
  - Color contrast ratio ≥ 4.5:1 for normal body text and ≥ 3:1 for large headers and actionable buttons.
  - All interactive tap targets (buttons, list items, icons) maintain minimum dimensions of **48x48 dp** per Material Design 3 and Android Accessibility guidelines.
  - Semantic widgets (`Semantics`, `Tooltip`, `accessibilityLabel`) used across actionable icons, FABs, and badges.

## 2. Dynamic Text Scaling
- Layouts are designed to not break under **200% text scale factor** (`MediaQuery.textScaleFactor = 2.0`).
- Text containers allow multi-line wrapping and avoid hard-coded fixed container heights on label rows.

## 3. Supported Languages & Tribal Dialect Scaffolding
- **Constitutional Languages:**
  - English (`en`) — Default
  - Hindi (`hi`)
  - Odia (`or`)
- **Tribal Language & Script Scaffolding:**
  - **Santali (`sat`)**: Rendered in **Ol Chiki script** (ᱚᱞ ᱪᱤᱠᱤ), providing native mother-tongue access for Santhal tribal communities across Odisha, Jharkhand, and West Bengal.
  - **Gondi (`gon`)**: Devnagari script representation with community review notices.
  - **Bhili (`bhb`)**: Devnagari script representation for Western Indian ST students (Rajasthan, Gujarat, Madhya Pradesh, Maharashtra).

## 4. Unreviewed Tag Policy
All community and tribal dialect translations carry an explicitly marked `(Unreviewed)` or `(Draft)` status until validated by MoTA-appointed state nodal linguists and tribal research institutes (TRIs).

## 5. Screen Reader & TalkBack Testing
- Navigation labels announce destinations clearly.
- Status badges announce both the state and status category (e.g., "Verification Status: Institute Verified").
- Currency figures announce full Indian Rupee text (e.g., "Eighteen Thousand Rupees via Direct Benefit Transfer").
