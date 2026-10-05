# psychowl

It knows what language you speak: natural language and script detection.

```rust
use psychowl::{Detector, Lang, Script};

let info = psychowl::detect("¿Dónde está la biblioteca? Estoy buscando un libro.").unwrap();
assert_eq!(info.lang(), Lang::Spa);
assert_eq!(info.script(), Script::Latin);
assert!(info.is_reliable());

// Restrict the candidates
let detector = Detector::with_allowlist(vec![Lang::Eng, Lang::Spa]);
assert_eq!(detector.detect_lang("Eu gostaria de reservar uma mesa"), Some(Lang::Spa));

// Ranked candidates, mixed-language segments, script counts
let ranked = Detector::new().candidates("Eu gostaria de reservar uma mesa");
let text = "Hello, this is English. Ceci est une phrase en français.";
for segment in Detector::new().segments(text) {
    println!("{} {}", segment.info().lang(), segment.text(text));
}
let counts = psychowl::script_counts("Hello мир"); // indexed like Script::all()
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
