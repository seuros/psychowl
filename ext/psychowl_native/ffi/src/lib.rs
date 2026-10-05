//! Ruby bindings for the psychowl crate. Only primitives cross: languages and
//! scripts as indices into `Lang::all()` / `Script::all()`, which the Ruby
//! side reads from the same files. Each function mirrors a `Psychowl::Engine`
//! method.
#![expect(
    clippy::needless_pass_by_value,
    reason = "magnus converts Ruby arguments into owned values; every function takes them"
)]

use std::ops::Range;

use magnus::{Error, Ruby, function};
use psychowl::{Detector, Filter, Info, Lang, Script};
use rayon::prelude::*;

const FILTER_ALL: i64 = 0;
const FILTER_ALLOW: i64 = 1;
const FILTER_DENY: i64 = 2;

/// `[language, script, confidence]` as seen by Ruby.
type Detection = (usize, usize, f64);

/// `[start, end, language, script, confidence]`, character offsets.
type SegmentRow = (usize, usize, usize, usize, f64);

const fn to_detection(info: Info) -> Detection {
    (info.lang().index(), info.script().index(), info.confidence())
}

fn arg_error(ruby: &Ruby, message: String) -> Error {
    Error::new(ruby.exception_arg_error(), message)
}

fn build_detector(
    ruby: &Ruby,
    filter_mode: i64,
    filter_langs: Vec<usize>,
) -> Result<Detector, Error> {
    let mut langs = Vec::with_capacity(filter_langs.len());
    for index in filter_langs {
        let Some(lang) = Lang::from_index(index) else {
            return Err(arg_error(ruby, format!("unknown language index: {index}")));
        };
        langs.push(lang);
    }

    let filter = match filter_mode {
        FILTER_ALL => Filter::All,
        FILTER_ALLOW => Filter::Allow(langs),
        FILTER_DENY => Filter::Deny(langs),
        other => {
            return Err(arg_error(ruby, format!("unknown filter mode: {other}")));
        }
    };
    Ok(Detector::with_filter(filter))
}

fn detect(
    ruby: &Ruby,
    text: String,
    filter_mode: i64,
    filter_langs: Vec<usize>,
) -> Result<Option<Detection>, Error> {
    let detector = build_detector(ruby, filter_mode, filter_langs)?;
    Ok(detector.detect(&text).map(to_detection))
}

fn candidates(
    ruby: &Ruby,
    text: String,
    filter_mode: i64,
    filter_langs: Vec<usize>,
) -> Result<Vec<(usize, f64)>, Error> {
    let detector = build_detector(ruby, filter_mode, filter_langs)?;
    let mut result = Vec::new();
    for (lang, score) in detector.candidates(&text) {
        result.push((lang.index(), score));
    }
    Ok(result)
}

/// Character offsets for byte offsets in one string, found by binary search.
struct CharOffsets {
    starts: Vec<usize>,
}

impl CharOffsets {
    fn new(text: &str) -> Self {
        Self { starts: text.char_indices().map(|(byte, _)| byte).collect() }
    }

    fn char_index(&self, byte: usize) -> usize {
        self.starts.partition_point(|&start| start < byte)
    }

    fn char_range(&self, bytes: Range<usize>) -> (usize, usize) {
        (self.char_index(bytes.start), self.char_index(bytes.end))
    }
}

/// One [`SegmentRow`] per segment.
fn segments(
    ruby: &Ruby,
    text: String,
    filter_mode: i64,
    filter_langs: Vec<usize>,
) -> Result<Vec<SegmentRow>, Error> {
    let detector = build_detector(ruby, filter_mode, filter_langs)?;
    let offsets = CharOffsets::new(&text);
    let mut result = Vec::new();
    for segment in detector.segments(&text) {
        let (start, end) = offsets.char_range(segment.range());
        let info = segment.info();
        result.push((start, end, info.lang().index(), info.script().index(), info.confidence()));
    }
    Ok(result)
}

/// `[start, end]` per sentence, character offsets.
fn sentences(text: String) -> Vec<(usize, usize)> {
    let offsets = CharOffsets::new(&text);
    psychowl::sentences(&text).into_iter().map(|range| offsets.char_range(range)).collect()
}

/// Detects many texts at once, spread over all CPU cores.
fn detect_many(
    ruby: &Ruby,
    texts: Vec<String>,
    filter_mode: i64,
    filter_langs: Vec<usize>,
) -> Result<Vec<Option<Detection>>, Error> {
    let detector = build_detector(ruby, filter_mode, filter_langs)?;
    let results = texts.par_iter().map(|text| detector.detect(text).map(to_detection)).collect();
    Ok(results)
}

fn detect_script(text: String) -> Option<usize> {
    psychowl::detect_script(&text).map(Script::index)
}

fn script_counts(text: String) -> Vec<usize> {
    psychowl::script_counts(&text)
}

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("PsychowlNative")?;
    module.define_module_function("detect", function!(detect, 3))?;
    module.define_module_function("candidates", function!(candidates, 3))?;
    module.define_module_function("detect_many", function!(detect_many, 3))?;
    module.define_module_function("detect_script", function!(detect_script, 1))?;
    module.define_module_function("segments", function!(segments, 3))?;
    module.define_module_function("sentences", function!(sentences, 1))?;
    module.define_module_function("script_counts", function!(script_counts, 1))?;
    Ok(())
}
