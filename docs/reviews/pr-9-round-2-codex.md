Codex review: round 2 formal PR review.

# Review: PR #9 textsize geometry and qrcode state leak

Date: 2026-07-29
Reviewed: PR #9 at f3e4f486f06011ed52cf77b50040ec6e7455e7aa
Round: 2
Label applied: approved-by-codex-agent

## What Is Correct

The round-1 blocker is resolved. The lift is now based on `0.75em`, which covers the tallest printable ASCII Courier glyph reachable through the `standardEnd()` human-text path. I verified Code39 values `A$B` and `A/B` and Code128 value `a|b`; at 40 point the `0.75em` top lands at the bar bottom rather than through it.

The fixed maximum is the right choice for this module. The geometry stays stable for a batch regardless of data, and the cost of extra whitespace for shorter glyphs is preferable to data-dependent barcode height. A per-value measurement would also be a larger change in a package that currently uses fixed package-global geometry.

The reachable high-byte Code128 case does not invalidate the ceiling. `Barcode::Code128` rejects ordinary high-byte text such as `chr(193)`, while accepting its special control-token bytes `0xf4..0xff`. Those bytes can reach `prText` because this module prints `$value` verbatim, but the WinAnsi glyphs for those byte positions in the Courier AFM I checked are below `0.75em`. The taller accented Courier glyphs exist in the AFM, but I did not find a `standardEnd()` barcode path that accepts those bytes as value text.

The updated regression test now covers the missing Code39 punctuation case. Its dollar-sign assertion fails under the old `0.622` ceiling and passes with the new `0.75` ceiling. The digits-only clearance assertion was also corrected from "identical" to "does not shrink", which matches the new worst-case lift.

The zero-margin `|` case at the default text size is acceptable for this PR. It is pre-existing behavior, and the new lift preserves that default-size clearance instead of making it worse as `textsize` grows. Adding new margin at the default size would change the compatibility property this PR is deliberately preserving.

I also rechecked the round-1 items: the `$qrcode` reset remains correctly ordered, `$textLift` is reset in `init()`, and the `$height` shadowing fix still keeps overflow background strips aligned with the drawn background height.

## Blockers

None.

## What Needs Attention

None.

## Bloat / Non-Functional

None. The fix is a small constant and test adjustment, and it avoids a per-value measurement path that would add complexity and change output geometry by data.

## Recommendations

Keep the documented framing that the lift preserves default-size clearance and does not create new margin. If a later change wants to display Code128 function-code tokens differently from their raw high-byte placeholders, that should be a separate behavior decision because it would affect human-readable text, not the bar-clearance fix.

## Bottom Line

Approve. The blocker from round 1 is fixed, the edge cases raised for round 2 are either covered by the `0.75em` ceiling or outside the accepted displayed value path, and the compatibility checks remain intact.
