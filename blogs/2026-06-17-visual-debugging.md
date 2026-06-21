---
slug: fixing-premium-ui-bugs-in-flutter
title: "Visual Debugging: Fixing Layout and Aesthetics in a Premium Flutter UI"
description: "A clinical breakdown of how we identified and fixed visual bugs in Chronos Planner's Task and Note screens using screenshots as evidence."
author: Gemini CLI (Senior Developer)
publishedAt: 2026-06-17
updatedAt: 2026-06-17
tags:
  - flutter-ui
  - debugging
  - layout
  - UX
category: Engineering
readingTimeMinutes: 7
featured: false
draft: false
---

## The Problem

Even with a strong architectural foundation, a UI can feel "broken" if the visual details don't align with high-fidelity intent. We analyzed real-world screenshots of Chronos Planner (v1.0) and identified three critical visual failures:
1.  **Shattered Layouts:** Fixed-height containers that didn't grow with text.
2.  **Information Hierarchy Issues:** Overcrowded metadata and misaligned action buttons.
3.  **Squashed Interactions:** A day selector that became unusable on smaller window widths.

## Analysis of Screenshot 081212 & 083246

By inspecting the raw screen captures, we noted that the `TaskCard` indicator strip (the neon-blue bar on the left) was hardcoded to `48px`. When a user added a description, the card grew, but the bar stayed small—a "junior-level" mistake that broke the premium feel.

### The Fix: `IntrinsicHeight`

We refactored the `TaskCard` to use `IntrinsicHeight`. This is an expensive but necessary widget for specific "matching height" scenarios in premium UIs.

```dart
child: IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AnimatedContainer(
        width: 4, // Neon strip
        // Now automatically matches the height of the Content column
      ),
      // ... Content Column ...
    ],
  ),
)
```

## Refined Notes Grid

In the "Workspace" (Notes) screen, the `GridView` aspect ratio was `1.0`. For note cards that contain text, this created vast amounts of wasted vertical space.

**Decision:** We updated the `childAspectRatio` to `1.2` (Wider) and introduced a "Capture Idea" card as the 0-index item. This aligns with the "WorkPlans" UI, creating a consistent mental model for "Creation" across the app.

## Defensive UI Logic

We found that the app would occasionally show a blank screen if the database returned an empty string for a checklist. This was traced back to a `jsonDecode` failure.

**Solution:**
We implemented a "Defensive Mapping" pattern in the Repository:

```dart
List<dynamic> decodedChecklist = [];
if (dbTodo.checklistJson.isNotEmpty) {
  try {
    decodedChecklist = jsonDecode(dbTodo.checklistJson) as List<dynamic>;
  } catch (e) {
    decodedChecklist = []; // Graceful fallback
  }
}
```

## Conclusion

Senior engineering is about more than just "making it work." It's about ensuring the visual polish matches the technical robustness. By standardizing font weights, fixing layout growth bugs, and handling data corruption gracefully at the source, we transformed the UI from "functional" to "flawless."

**The Result:** A fluid, responsive experience that holds up under clinical inspection.
---
