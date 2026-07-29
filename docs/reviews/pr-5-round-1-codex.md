Codex review:

# Review: PR #5 configurable barcode textsize

Date: 2026-07-29
Reviewed: PR #5 (`feature/configurable-textsize`) at `d0a62e6f1b5fe830641e02710aa635af4338d5cc`
Round: 1
Label applied: changes-requested

## What Is Correct

The public API shape is small and scoped: `textsize` is added to `%default`, so existing per-barcode parameter filtering accepts it without changing every symbology wrapper. `init()` rebuilds `%default` on each barcode call, so this specific option does not persist between calls.

The width calculation in `standardEnd()` is consistent with the existing Courier font choice. The old `length($value) * 6` path is reproduced at the default because the new formula is `length($value) * 10 * 0.6`. This also keeps the coordinate math in barcode-local user space, which is the right place for both normal barcodes and QRcode after `general1()` has established the size/xsize/ysize transform.

The `q ... Q` wrapper on the new rectangle is correct for graphics-state scoping. `rg`, the rectangle path, and fill operation are contained inside a saved graphics state, so the fill color cannot leak into later barcode/text operators.

The decision not to make EAN/UPC honor `textsize` is defensible because those code paths place multiple text fragments at fixed coordinates rather than using `standardEnd()` centering.

## Blockers

1. `Barcode.pm:151` adds the overflow background after `general2()` has already painted the barcode. In `standardEnd()`, `general2()` emits the original background and then emits the bars/modules before returning. The new branch then emits:

   ```perl
   prAdd(sprintf("q %s rg %s 0 %s %s re f* Q\n",
                 $default{'background'},
                 -$extra, $textLength, $height));
   ```

   For any overflow case, that rectangle starts before zero and has width `$textLength`, so it necessarily covers the full barcode span from `0` through `$length`. Because it is filled after the bars/modules, it paints over the barcode itself, not just the newly exposed side area. This is a release-blocking rendering defect for exactly the new large-text path. The fix should either draw the expanded background before the barcode is painted or draw only the left/right extension rectangles after the barcode has been painted.

2. `Barcode.pm:151` also ignores `drawbackground => 0`. Existing POD says `drawbackground` disables the module's prepared background and uses the current background. The overflow branch unconditionally draws a background rectangle whenever `textsize > 10` and the text is wider than `$length`, so a caller that explicitly disabled background drawing still gets a new filled rectangle. This is a boundary/API behavior regression and should be gated on `drawbackground` or otherwise documented and intentionally designed.

## What Needs Attention

The `$textsize > 10` gate is defensible as a compatibility gate, but the literal should not be duplicated as a policy constant in the new API path. Since `10` is now the default declared in `%default`, comparing against that same default value through a named lexical or package constant would make the compatibility rule less fragile. As written, a future default change would silently desynchronize the default and the overflow policy.

For `textsize => 10.5`, the current behavior is coherent: if the text becomes wider than the barcode, the overflow path runs because the caller asked for a larger-than-default rendered size. For a smaller size with a very long value, the overflow path does not run. That matches the stated byte-compatibility rationale, but the POD currently says text wider than the barcode is widened without mentioning that this is only true when `textsize` is above the default. Either make the behavior match the POD or document the compatibility exception.

There is no `textsize` validation. This module already accepts numeric rendering parameters directly and does little boundary validation, so a full validation framework would be out of proportion. However, because `textsize` is new permanent API and is passed directly into PDF text state, one narrow check for positive numeric size would be warranted. `textsize => 0`, negative values, or a non-numeric string can produce invalid, invisible, mirrored, or warning-prone PDF operators. This is a public caller boundary, not merely internal trusted state.

The `$height` used by the overflow rectangle is especially fragile in the non-QR branch. `general2()` uses a lexical `my $height = 38` for normal barcodes, while the package `$height` remains `37` unless QR or other state changed it. That makes the new rectangle height differ from the original normal-barcode background height, and after any earlier QRcode call the package `$height` may retain QR dimensions because `$qrcode` is also not reset by `init()`. This shadowing is pre-existing, but the new overflow branch makes the package `$height` load-bearing for visible output.

`$default{'background'}` is interpolated directly into a PDF content stream. That matches existing behavior in `general2()`, so it is not a new injection surface, but the overflow path should preserve existing behavior by not using `background` for QRcode unless that is intentional. QR backgrounds currently use `graybackground` and grayscale `g`, while the new QR overflow rectangle uses RGB `background` and `rg`, which can make QR text overflow use a different background color from the QR box.

## Bloat / Non-Functional

None. The implementation is small and appropriately scoped, but the added background behavior needs to be corrected because it is load-bearing rendering logic.

## Recommendations

Move the overflow background decision earlier than barcode painting, or emit only side-extension rectangles after barcode painting. Preserve `drawbackground => 0`.

Use a single named default for text size, then compare the compatibility gate against that default instead of a second literal `10`.

Add focused tests that inspect operator order for an overflowing barcode: the extended background must not appear after the bar/module drawing in a way that covers `0..$length`. Add a `drawbackground => 0, textsize => large` case to assert no overflow background is emitted when backgrounds are disabled.

Clarify the POD around overflow widening: either it applies only when `textsize` is above the default, or the code should implement it for all text sizes in a backward-compatible way that does not change default output.

## Bottom Line

Revise before release. The `textsize` API itself is useful and the default-width math is sound, but the overflow branch currently paints a filled rectangle over the already-rendered barcode and ignores `drawbackground => 0`. Because this is load-bearing content-stream behavior for a new 0.10 API, those rendering semantics need another round before approval.

## Local Verification

Ran `git diff --check origin/master...HEAD`: passed.

Ran `PERL5LIB=../PDF-Reuse/lib perl -c Barcode.pm`: syntax OK, with pre-existing one-use package variable warnings for GD::Barcode error strings.

Ran `PERL5LIB=../PDF-Reuse/lib:blib/lib perl -c t/textsize.t`: syntax OK.

Attempted `make test`; it could not complete in this local environment because `PDF::Reuse` and then `GD::Barcode` dependencies were not installed. Retried with sibling `../PDF-Reuse/lib` on `PERL5LIB`, which resolved `PDF::Reuse`; `GD::Barcode` remained missing locally.
