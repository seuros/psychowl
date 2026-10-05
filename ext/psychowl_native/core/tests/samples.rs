//! Every sample in tests/samples/<code>.txt must be detected as <code>.
//! The Ruby test suite checks the same files.

use std::fs;
use std::path::Path;

use psychowl::Lang;

#[test]
fn every_sample_is_detected_as_its_language() {
    let dir = Path::new(env!("CARGO_MANIFEST_DIR")).join("tests/samples");
    let mut checked = 0;

    for lang in Lang::all() {
        let path = dir.join(format!("{}.txt", lang.code()));
        let content = match fs::read_to_string(&path) {
            Ok(content) => content,
            Err(error) => panic!("{} has no samples ({}): {error}", lang.code(), path.display()),
        };

        for (number, sample) in
            content.lines().filter(|line| !line.is_empty() && !line.starts_with('#')).enumerate()
        {
            let detected = psychowl::detect_lang(sample);
            assert_eq!(detected, Some(*lang), "{} sample {number}: {sample}", lang.code());
            checked += 1;
        }
    }

    assert!(checked >= Lang::all().len());
}
