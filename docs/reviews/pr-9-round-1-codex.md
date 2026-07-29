# Review: PR #9 textsize geometry and qrcode state leak

Date: 2026-07-29
Reviewed: PR #9 at f1cd888c3e09785799b99aefbda4b35f48617822
Round: 1
Label applied: changes-requested

## What Is Correct

The `$qrcode` reset is correctly ordered. `QRcode()` now calls `init()` before setting `$qrcode = 1`, and `init()` clears the flag for the next public barcode call. I verified same-process QR-to-linear sequences for Code39, EAN13, EAN8, UPCA, UPCE, ITF, and NW7: after the QR text baseline, the later barcode used the expected linear/EAN/UPC placement and still emitted bar operators. `init()` does not read `$qrcode`, so nothing between the `require` and the reset depends on the old ordering.

The `$height` shadowing fix is correct. Removing `my` in `general2()` makes the file-scoped `$height` match the background height that `standardEnd()` later uses for overflow side strips, including the `prolong` branch.

The `$textLift` state is reset in `init()` and set unconditionally by `standardEnd()` before its shared `general2()` call. I did not find a public path that reaches `general2()` with stale lift: the EAN/UPC direct callers all call `init()` first, and the standard linear callers go through `standardEnd()`.

## Blockers

1. `Barcode.pm:21` and `Barcode.pm:173` still under-lift bars for legal Code39 text containing `/` or `$`.

   The lift is based on `$DIGIT_HEIGHT_EM = 0.622`, but Code39 accepts non-digit text and prints the original value under the bars. On this system's Courier-compatible AFM, `/` reaches 0.665 em and `$` reaches 0.652 em above the baseline. That makes the new clearance formula go negative again for valid values at larger text sizes.

   I verified this against the PR branch with `PDF::Reuse::Barcode::Code39(value => 'A/B', textsize => $size)`: at 20pt clearance is 0.420, at 28pt it is 0.076, at 30pt it is -0.010, and at 40pt it is -0.440. So the stated fix for "any non-default textsize" is incomplete; the digit-only regression test stays green while valid barcode text can still overprint the bars.

   Use the maximum above-baseline height for every character a standardEnd-backed symbology can render, or compute the required lift from the actual `$value` characters. Add a regression with a valid Code39 value containing `/` at a size where the current patch fails, such as `textsize => 30` or `40`.

## What Needs Attention

The added tests cover the digit case well, but the geometry assertion in `t/textsize.t:110` uses only `value => '123456789'`. That is why it misses the blocker above. The test should include at least one legal non-digit Code39 character whose glyph bbox exceeds the digit height.

## Bloat / Non-Functional

None. The patch is small and stays within the existing shared-state structure of this module.

## Recommendations

Keep the `init()` reset pattern for `$qrcode` and `$textLift`; it matches the module's existing package-global design. For the text lift, either rename the constant to reflect the actual maximum glyph height and set it high enough for Code39's printable alphabet, or derive the max from `$value` so QR and other future text-bearing paths do not rely on a misleading digit-only assumption.

## Bottom Line

Request changes. The QR state leak and height shadowing fixes look sound, but the text geometry fix is load-bearing and still fails for valid Code39 values with taller punctuation at larger `textsize`.
