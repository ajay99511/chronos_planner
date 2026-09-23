# 0007 — An i18n seam without localising

**Status:** Accepted

**Decision:** `AppStrings` holds user-facing text whose **grammar** depends on
data — plurals, counts spliced into sentences, assembled clauses. Fixed
single-token labels stay at their call sites. No `.arb` files, no second locale.

**Context:** `design-judgment.md` lists i18n under *"defer, but leave a seam — do
not build; do place the boundary so the future change is local."* The app declares
one supported locale and there is no committed second one, so extracting all ~170
literals in `lib/ui` would be building it rather than seaming it.

What *is* expensive to retrofit is grammar compiled into the widget tree, because
it is invisible: `overlap${count == 1 ? '' : 's'}` reads as ordinary string
interpolation, and `stack-appendices.md` §3 is explicit that translated fragments
must never be concatenated. Those cases now sit behind functions that own the
whole sentence.

**Alternatives:**

- **Extract every literal now** — the audit's own acceptance criterion, and
  stricter than the standard it cited. ~170 call sites and a large lookup table for
  an app with one locale.
- **Extract nothing until a second locale is committed** — cheapest today, but it
  leaves the plural ternaries in place, which is precisely the part that is hard to
  find later.
- **Adopt `flutter_localizations` + ARB immediately** — the tooling is already a
  dependency, but generated lookups for a single language is ceremony with no
  reader.

**Consequences:**

- Easy: each message is one function with tests for singular and plural, so adding
  a locale means replacing bodies, not hunting call sites.
- Hard: two conventions coexist — grammar-bearing text goes through `AppStrings`,
  fixed labels do not. The boundary is defensible but has to be explained, which is
  what this record is for.
- Reversing / completing: mechanical. Move the remaining literals into the same
  class; no call-site restructuring needed.
