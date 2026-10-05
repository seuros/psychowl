# psychowl language data

Plain-text tables shared by both engines: the Rust crate compiles them in
(`build.rs`), the pure Ruby engine reads them at load time. Both must give
identical results, so these files are the single source of truth.

Lines starting with `#` are comments. Fields are tab-separated.

| File | Content |
|---|---|
| `languages.tsv` | `code`, `iso639_1`, `eng_name`, `name`. Sorted by code; line order is the language index. |
| `scripts.tsv` | `name`, `languages` (comma-separated codes, `-` for none), `ranges` (hex code points, inclusive, disjoint across scripts). Line order is the script index and the tie-break priority. |
| `alphabets.tsv` | `code`, `letters`: lowercase letters a language commonly uses. Needed for languages sharing a script. |
| `trigrams/<code>.txt` | The language's 300 most frequent character trigrams, most frequent first, one per line. `_` stands for a word boundary (space). Needed for languages sharing a script. |

## Adding a language

1. Add its row to `languages.tsv` (keep it sorted).
2. Add its code to its script(s) in `scripts.tsv`.
3. If the script has other languages: add `alphabets.tsv` letters and a
   `trigrams/<code>.txt` profile (`rake psychowl:train[code]` builds one from
   `corpus/<code>.txt`).
4. Add samples to `core/tests/samples/<code>.txt`; both test suites pick
   them up.

## Provenance

The initial profiles, alphabets and script ranges were ported from
[whatlang](https://github.com/greyblake/whatlang-rs) 0.18.0 with
`tools/import_whatlang.rb`; see `LICENSE-whatlang` (MIT). Changes from the
original: the Latin range no longer overlaps the Cyrillic letters U+1D2B and
U+1D78, and Mandarin is named by its Unicode script name, Han.
