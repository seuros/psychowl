# Changelog

## 0.1.0 (unreleased)

First release, for Ruby 4.0+ (CRuby, JRuby 10.1+, TruffleRuby 40+): 18 languages
and 25 scripts. Wave 1: Arabic, English, French, German, Italian, Japanese,
Mandarin, Portuguese, Russian, Spanish. Wave 2: Dutch, Hindi, Indonesian,
Korean, Polish, Turkish, Ukrainian, Vietnamese.

- Pure Ruby engine plus the `psychowl` Rust crate, loaded as an optional
  native extension; a parity suite keeps both bit-identical.
- `detect`, `detect_lang`, `detect_script`, `candidates`, `segments`,
  `detect_many`, `scripts`; allowlists and denylists that also apply to
  single-language scripts and Han.
- `Lang` with ISO 639-3/639-1 codes, `#locale` and `#pg_regconfig`.
- ActiveModel `language:` validator, `psychowl` CLI.
- Language tables as plain text, a whatlang importer and a trigram profile
  trainer.
