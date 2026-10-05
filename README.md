# psychowl

It knows what language you speak.

Language and script detection for Ruby and Rust. psychowl follows the
[Matryoshka](https://github.com/seuros/matryoshka) FFI Hybrid pattern:

- a **pure Ruby engine** that runs everywhere (CRuby, JRuby, TruffleRuby),
- the same algorithm in **Rust** (the `psychowl` crate), loaded as a native
  extension when available, 20 to 500 times faster,
- one set of **plain-text language tables** both engines read, and a parity
  test suite holding them to bit-identical results.

```ruby
require "psychowl"

info = Psychowl.detect("¿Dónde está la biblioteca? Estoy buscando un libro.")
info.lang.code     # => "spa"
info.lang.locale   # => :es
info.script.name   # => "Latin"
info.confidence    # => 1.0
info.reliable?     # => true
```

## Installation

```ruby
gem "psychowl"
```

Precompiled native gems are built for Linux (glibc and musl, x86_64 and
aarch64) and macOS (arm64, x86_64). On FreeBSD (tested in CI on 14 and 15)
and everywhere else the extension compiles from source if Cargo is
installed; otherwise psychowl quietly uses its Ruby engine. Windows gets the
Ruby engine only.

```ruby
Psychowl.backend # => :native or :ruby
```

Set `DISABLE_PSYCHOWL_NATIVE=1` (or `DISABLE_MATRYOSHKA_NATIVE=1`) to force
the Ruby engine.

## Usage

```ruby
Psychowl.detect_lang("Das ist ein sehr guter Satz auf Deutsch.") # => #<Psychowl::Lang deu (German)>
Psychowl.detect_script("Привет, мир")                            # => #<Psychowl::Script Cyrillic>

# Restrict the candidates (ISO 639-3 or 639-1 codes, or Lang objects)
Psychowl.detect("Eu gostaria de reservar uma mesa", allowlist: %i[en es])
Psychowl.detect("Eu gostaria de reservar uma mesa", denylist: [:por])

# Reuse a configured detector (frozen, thread-safe)
detector = Psychowl::Detector.new(allowlist: %i[en fr de])
detector.detect_lang("Bonjour tout le monde")

# Every candidate with its score, best first
Psychowl.candidates("Eu gostaria de reservar uma mesa", limit: 3)
# => [[#<Psychowl::Lang por (Portuguese)>, 0.73], [#<Psychowl::Lang spa (Spanish)>, 0.69], ...]

# Mixed-language text, per sentence, with character ranges
Psychowl.segments("Hello, this is English. Ceci est une phrase en français.").map { [_1.lang.code, _1.range] }
# => [["eng", 0...24], ["fra", 24...56]]

# Many texts at once (spread over all cores with the native engine)
Psychowl.detect_many(comments.map(&:body))

# Writing systems in a text
Psychowl.scripts("Hello мир") # => {#<Psychowl::Script Latin> => 0.625, #<Psychowl::Script Cyrillic> => 0.375}

# Pattern matching
case Psychowl.detect(text)
in {lang: {code: "eng"}, reliable: true} then :english
in nil then :unknown
end
```

Invalid input raises: `TypeError` for non-strings, `EncodingError` for bytes
that are not valid UTF-8 (other encodings are converted, binary strings are
accepted when they hold valid UTF-8), `ArgumentError` for unsupported
language codes.

### Short texts

Detection works on character trigrams, so it needs some text. A couple of
words is a guess ("Hello" comes out as Italian with a confidence of 0.08).
Check `reliable?` or `confidence` before trusting a result, or restrict the
candidates with an allowlist.

## Rails

The `language:` validator loads automatically in Rails apps (elsewhere:
`require "psychowl/active_model"`).

```ruby
class Post < ApplicationRecord
  validates :body, language: { in: %i[en fr] }
  validates :title, language: { not_in: :ru, reliable: true }, allow_blank: true
  validates :bio, language: { in: :en, minimum_confidence: 0.5 }
end
```

Error keys are `:language_undetected`, `:language_not_allowed` and
`:language_uncertain`, each with a `%{language}` interpolation; English
messages ship with the gem.

PostgreSQL full-text search configuration for a language:

```ruby
config = Psychowl.detect(post.body)&.lang&.pg_regconfig || "simple" # => "english"
Post.where("to_tsvector(?::regconfig, body) @@ plainto_tsquery(?::regconfig, ?)", config, config, query)
```

## CLI

```console
$ echo "¿Dónde está la biblioteca?" | psychowl
spa	Spanish	Latin	1.00	reliable
$ psychowl --candidates 3 post.txt
$ psychowl --lines --json comments.txt     # one result per line, batch
$ psychowl --segments --allow en,fr mixed.txt
$ psychowl --scripts tweet.txt
$ psychowl --languages
```

Exit status: 0 when a language was found, 1 when not, 2 on bad input.

## Supported languages

Languages are added in waves; adding one is a data change, not a code change
(see [`data/README.md`](ext/psychowl_native/core/data/README.md)).

| Wave | Languages |
|---|---|
| 1 (0.1) | Arabic, English, French, German, Italian, Japanese, Mandarin, Portuguese, Russian, Spanish |
| 2 | Korean, Hindi, Turkish, Dutch, Polish, Ukrainian, Indonesian, Vietnamese |
| 3 | the rest of whatlang's 70 |
| 4 | new languages trained from our own corpora |

Script detection covers 25 writing systems already. A text in a script with
no supported language yet (Greek, Korean...) has a script but no language.
Text in an unsupported language written in a supported script gets the
closest supported language, usually with a low confidence.

## Rust

The engine is a standalone crate, see
[`ext/psychowl_native/core`](ext/psychowl_native/core/README.md).

## Development

```console
bundle install
rake test:all        # cargo test, then the suite on both engines (incl. parity)
rake test:ruby       # pure Ruby engine only
rake lint            # cargo fmt --check + clippy
rake "psychowl:train[eng]"   # rebuild a profile from corpus/eng.txt
ruby bench/engines.rb        # Ruby vs Rust timings
```

## Credits

The algorithm and the initial language profiles are ported from
[whatlang](https://github.com/greyblake/whatlang-rs) by Sergey Potapov and
contributors (MIT); see
[`LICENSE-whatlang`](ext/psychowl_native/core/data/LICENSE-whatlang).

## License

MIT
