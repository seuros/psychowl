# psychowl

It knows what language you speak. It knows you skipped your lesson.

```rust
use psychowl::{Detector, Lang, Script};

let speech = "El presidente dijo que la economía va muy bien. \
              Los precios todavía no se han enterado.";
let info = psychowl::detect(speech).unwrap();
assert_eq!(info.lang(), Lang::Spa);
assert_eq!(info.script(), Script::Latin);
assert!(info.is_reliable()); // more than the economy

// Restrict the candidates: Portuguese is not allowed, Spanish is closest
let detector = Detector::with_allowlist(vec![Lang::Eng, Lang::Spa]);
let promise = "O presidente prometeu que desta vez a obra termina no prazo.";
assert_eq!(detector.detect_lang(promise), Some(Lang::Spa));

// Ranked candidates
let ranked = Detector::new().candidates(promise); // por, spa, ita, ...

// Mixed-language summit transcripts, per sentence
let summit = "Nobody detects languages better than me, believe me. \
              Traversez la rue, je vous trouverai un travail.";
for segment in Detector::new().segments(summit) {
    println!("{} {}", segment.info().lang(), segment.text(summit)); // eng ..., fra ...
}

// Characters per script, indexed like Script::all()
let counts = psychowl::script_counts("Это не война, это специальная военная операция.");
```

`Lang` and `Script` are generated at build time from the plain-text tables in
`data/`, which are shared with the [psychowl Ruby gem](https://github.com/seuros/psychowl).
The gem runs the same algorithm in pure Ruby or through this crate, with
identical results.

Lowercasing is per character (no context-dependent final sigma), to match
Ruby's `String#downcase`.

## Credits

Algorithm and initial profiles ported from
[whatlang](https://github.com/greyblake/whatlang-rs) (MIT), see `data/LICENSE-whatlang`.

## License

MIT
