---
name: tssa-mobile-ui
description: Design or revise SPM Mobile Flutter interfaces with clear Material 3 hierarchy, accessible motion, and TSSA report boundaries. Use for the app shell, learner, guardian, tutor, coordinator, and admin screens; avoid generic dashboard styling and unsupported product claims.
---

# SPM Mobile interface guidance

Use this skill when changing user-facing Flutter screens in SPM Mobile.

## Product context

- The app combines the HCMUT tutoring workflows with a proposed Tutor Support System for Autism (TSSA). The report's HCMUT screen mockups are conceptual web references, not current mobile screens or proof of TSSA behavior.
- Treat TSSA as education and tutor coordination. Do not frame it as diagnosis, clinical assessment, or treatment.
- Build from the current role, API contract, and persisted data. The report's proposed workflows, targets, and model behavior are not implemented or measured unless the repository provides that evidence.
- Keep learning goals and support preferences learner/family chosen and shared only for an explained purpose. A coordinator reviews matching; a learner or family can choose, decline, or ask for another shortlist.

## Visual conventions

- Follow the app's Material 3 theme and shared components. Retain the established `#0329E9` brand primary unless the user asks for a rebrand.
- Use a calm, readable surface palette, clear type hierarchy, consistent spacing, and visible focus, selection, loading, empty, success, and error states.
- Give each screen a clear primary task. Group related information deliberately; avoid repeating anonymous cards, decorative gradients, invented metrics, and controls that do not perform a supported action.
- Use short Vietnamese labels. Explain technical terms where a learner or family must act on them.
- Respect text scaling, screen-reader semantics, keyboard/focus order, contrast, and comfortable touch targets. Do not rely on color alone for status.

## Motion and sound

- Use brief motion only to clarify a state or navigation change. Prefer a single restrained fade or small translation; avoid looping, bouncing, parallax, and staggered motion over long lists.
- Honor both the platform's reduced-motion request and the saved `reduceMotion` preference through `MediaQuery.disableAnimations`.
- Keep essential status feedback visible without animation. Never autoplay audio or recording; add controls only when a supported media feature exists.

## Before changing a screen

Inspect its role mapping, repository/provider, and existing tests or contracts. Preserve permission checks, privacy boundaries, and user-owned draft behavior. If the report describes a future workflow without an API, label it clearly as a proposal or leave the action unavailable instead of simulating a completed operation.
