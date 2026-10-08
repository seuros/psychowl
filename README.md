# psychowl

It knows what language you speak. It knows you skipped your lesson.

Language and script detection for Ruby and Rust. psychowl follows the
[Matryoshka](https://github.com/seuros/matryoshka) FFI Hybrid pattern:

- a **pure Ruby engine** that runs everywhere (CRuby, JRuby 10.1+, TruffleRuby 40+),
- the same algorithm in **Rust** (the `psychowl` crate), loaded as a native
  extension when available, 20 to 500 times faster,
- one set of **plain-text language tables** both engines read, and a parity
  test suite holding them to bit-identical results.

```ruby
require "psychowl"

info = Psychowl.detect("El presidente dijo que la economía va muy bien. Los precios todavía no se han enterado.")
info.lang.code     # => "spa"
info.lang.locale   # => :es
info.script.name   # => "Latin"
info.confidence    # => 1.0  (more than the economy gets)
info.reliable?     # => true
```

## The owl has heard things

Every line below is detected correctly, at full confidence, by both engines.
Heads of state make the best test data: they talk a lot and say nothing.

| | Text | Roughly |
|---|---|---|
| eng | Nobody detects languages better than me, believe me. Tremendous trigrams, the best trigrams, everybody says so. | The best trigrams. Everybody says so. |
| spa | El presidente dijo que la economía va muy bien. Los precios todavía no se han enterado. | The president said the economy is doing great. Prices haven't heard yet. |
| fra | Traversez la rue, je vous trouverai un travail, a dit le président avant de repartir en jet privé. | "Cross the street, I'll find you a job," said the president, boarding his private jet. |
| deu | Die Deutsche Bahn ist heute pünktlich. Wir ermitteln. | Deutsche Bahn is on time today. We are investigating. |
| ita | Il presidente ha promesso che il ponte sarà finito entro le prossime elezioni. Quali elezioni non lo ha detto. | The bridge will be done by the next election. He didn't say which one. |
| por | O presidente prometeu que desta vez a obra termina no prazo. A obra começou em mil novecentos e oitenta e dois. | This time the construction finishes on schedule. It started in 1982. |
| rus | Это не война, это специальная военная операция. | It's not a war, it's a special military operation. |
| ara | فاز الرئيس في الانتخابات بنسبة تسعة وتسعين في المئة. مرة أخرى. | The president won the election with 99%. Again. |
| cmn | 小熊维尼今天又被禁止了。 | Winnie the Pooh was banned again today. |
| jpn | 首相は「前向きに検討します」と言いました。 | The prime minister said he will "consider it positively". |
| kor | 대통령은 부동산 가격이 안정되었다고 말했다. 집값은 그 말을 듣지 못했다. | The president said housing prices have stabilized. Housing prices didn't hear him. |
| hin | नेताजी ने वादा किया कि इस बार बिजली नहीं जाएगी। फिर बिजली चली गई। | The politician promised the power won't go out this time. Then the power went out. |
| tur | Bakan, ekonominin uçuşa geçtiğini söyledi. Kimse paraşüt dağıtmadı. | The minister said the economy has taken off. Nobody handed out parachutes. |
| nld | De regering is gevallen. Dat is al de derde keer deze maand, en het is pas dinsdag. | The government has fallen. Third time this month, and it's only Tuesday. |
| pol | Prezydent obiecał, że pociąg przyjedzie punktualnie. Pociąg nie został o tym poinformowany. | The president promised the train will be on time. Nobody told the train. |
| ukr | Сова нагадує: урок не пройдено. Вона вже їде до тебе. | The owl reminds you: lesson not done. It is already on its way to you. |
| ind | Pejabat itu bilang jalan tol akan selesai tahun depan. Dia mengatakan hal yang sama sepuluh tahun lalu. | The official says the toll road is done next year. He said the same ten years ago. |
| vie | Ông quan chức hứa sẽ sửa đường ngay tuần sau. Tuần sau đó đã kéo dài ba năm. | The official promised to fix the road next week. That week has lasted three years. |

## Installation

Requires Ruby 4.0 or newer.

```ruby
gem "psychowl"
```

Precompiled native gems ship for Linux (x86_64 and aarch64; glibc 2.34+ such
as Debian 13, Ubuntu 26.04, RHEL 10, Fedora, Arch or Omarchy, plus musl for
Alpine), macOS 13+ (arm64, x86_64) and FreeBSD 15.1 (amd64). No Rust, no
compiler, nothing to build.
Windows, JRuby and TruffleRuby get the pure Ruby gem: same results, just
slower. Where a shipped native extension can't load (glibc older than 2.34,
Alpine without `libgcc`), psychowl warns and uses its Ruby engine.

```ruby
Psychowl.backend # => :native or :ruby
```

Set `DISABLE_PSYCHOWL_NATIVE=1` (or `DISABLE_MATRYOSHKA_NATIVE=1`) to force
the Ruby engine.

## Usage

```ruby
Psychowl.detect_lang("Die Deutsche Bahn ist heute pünktlich. Wir ermitteln.")
# => #<Psychowl::Lang deu (German)>

Psychowl.detect_script("Это не война, это специальная военная операция.")
# => #<Psychowl::Script Cyrillic>  (the owl calls it what it is)

promise = "O presidente prometeu que desta vez a obra termina no prazo."

# Restrict the candidates (ISO 639-3 or 639-1 codes, or Lang objects)
Psychowl.detect_lang(promise, allowlist: %i[en es]) # => #<Psychowl::Lang spa (Spanish)>
Psychowl.detect_lang(promise, denylist: [:por])     # => #<Psychowl::Lang spa (Spanish)>

# Reuse a configured detector (frozen, thread-safe, unlike the coalition)
detector = Psychowl::Detector.new(allowlist: %i[en fr de])
detector.detect_lang("Traversez la rue, je vous trouverai un travail, a dit le président.")
# => #<Psychowl::Lang fra (French)>

# Every candidate with its score, best first
Psychowl.candidates(promise, limit: 3)
# => [[#<Psychowl::Lang por (Portuguese)>, 0.71], [#<Psychowl::Lang spa (Spanish)>, 0.67], [#<Psychowl::Lang ita (Italian)>, 0.66]]

# Mixed-language text, per sentence, with character ranges (summit transcripts)
summit = "Nobody detects languages better than me, believe me. Traversez la rue, je vous trouverai un travail."
Psychowl.segments(summit).map { [_1.lang.code, _1.range] }
# => [["eng", 0...53], ["fra", 53...100]]

# Many texts at once (spread over all cores with the native engine)
Psychowl.detect_many(press_releases.map(&:body))

# Writing systems in a text
Psychowl.scripts("Error 404: смысл жизни not found")
# => {#<Psychowl::Script Latin> => 0.565, #<Psychowl::Script Cyrillic> => 0.435}

# Pattern matching
case Psychowl.detect(speech)
in {lang: {code: "eng"}, reliable: true} then :tremendous
in {reliable: false} then :fake_news
in nil then :no_comment
end
```

Invalid input raises: `TypeError` for non-strings, `EncodingError` for bytes
that are not valid UTF-8 (other encodings are converted, binary strings are
accepted when they hold valid UTF-8), `ArgumentError` for unsupported
language codes.

### Short texts

Detection works on character trigrams, so it needs some text. A couple of
words is a guess: "Hello" comes out as Italian with a confidence of 0.08,
and the owl stands by it. Check `reliable?` or `confidence` before trusting a
result, or restrict the candidates with an allowlist. Same rule as campaign
promises.

## Rails

The `language:` validator loads automatically in Rails apps (elsewhere:
`require "psychowl/active_model"`).

```ruby
class CampaignPromise < ApplicationRecord
  validates :text, language: { in: %i[en es] }
  validates :fine_print, language: { reliable: true }, allow_blank: true
  validates :excuse, language: { minimum_confidence: 0.5 } # "we will consider it positively" is not an excuse
end
```

Error keys are `:language_undetected`, `:language_not_allowed` and
`:language_uncertain`, each with a `%{language}` interpolation; English
messages ship with the gem.

PostgreSQL full-text search configuration for a language:

```ruby
config = Psychowl.detect(speech.transcript)&.lang&.pg_regconfig || "simple" # => "german"
Speech.where("to_tsvector(?::regconfig, transcript) @@ plainto_tsquery(?::regconfig, ?)", config, config, "pünktlich")
# => [] (as expected)
```

## CLI

```console
$ echo "Nobody detects languages better than me, believe me." | psychowl
eng	English	Latin	0.89	unreliable
$ psychowl --candidates 3 campaign_promises.txt
$ psychowl --lines --json press_conference.txt   # one result per line, batch
$ psychowl --segments --allow en,fr summit_transcript.txt
$ psychowl --scripts leaked_memo.txt
$ psychowl --languages
```

Exit status: 0 when a language was found, 1 when not, 2 on bad input.

## Supported languages

Languages are added in waves; adding one is a data change, not a code change
(see [`data/README.md`](ext/psychowl_native/core/data/README.md)).

| Wave | Languages |
|---|---|
| 1 (0.1) | Arabic, English, French, German, Italian, Japanese, Mandarin, Portuguese, Russian, Spanish |
| 2 (0.1) | Dutch, Hindi, Indonesian, Korean, Polish, Turkish, Ukrainian, Vietnamese |
| 3 | the rest of whatlang's 70 |
| 4 | new languages trained from our own corpora |

Script detection covers 25 writing systems already. A text in a script with
no supported language yet (Greek, Thai...) has a script but no language.
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
