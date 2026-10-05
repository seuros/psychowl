//! Natural language and script detection. It knows what language you speak.
//! It knows you skipped your lesson.
//!
//! ```
//! use psychowl::{Lang, Script};
//!
//! let speech = "El presidente dijo que la economía va muy bien. \
//!               Los precios todavía no se han enterado.";
//! let info = psychowl::detect(speech).unwrap();
//! assert_eq!(info.lang(), Lang::Spa);
//! assert_eq!(info.script(), Script::Latin);
//! assert!(info.is_reliable()); // more than the economy
//! ```
//!
//! The language data is plain text under `data/`, compiled in by `build.rs` and
//! shared with the `psychowl` Ruby gem.

mod detector;
mod engine;
mod lang;
mod script;
mod segment;
mod trigram;

pub use detector::{Detector, Filter, Info};
pub use lang::UnknownLang;
pub use segment::{Segment, sentences};

include!(concat!(env!("OUT_DIR"), "/tables.rs"));

/// Compiles the README examples as doctests, so they cannot drift.
#[cfg(doctest)]
#[doc = include_str!("../README.md")]
struct ReadmeDoctests;

pub(crate) struct LanguageRow {
    pub(crate) lang: Lang,
    pub(crate) code: &'static str,
    pub(crate) iso639_1: &'static str,
    pub(crate) eng_name: &'static str,
    pub(crate) name: &'static str,
}

pub(crate) struct ScriptRow {
    pub(crate) name: &'static str,
    pub(crate) langs: &'static [Lang],
}

/// Detects the language and script of `text`, among all supported languages.
#[must_use]
pub fn detect(text: &str) -> Option<Info> {
    Detector::new().detect(text)
}

/// Detects only the language of `text`.
#[must_use]
pub fn detect_lang(text: &str) -> Option<Lang> {
    Detector::new().detect_lang(text)
}

/// Detects the dominant writing system of `text`.
#[must_use]
pub fn detect_script(text: &str) -> Option<Script> {
    engine::main_script(&engine::script_counts(text))
}

/// Number of characters of each script in `text`, indexed like `Script::all()`.
#[must_use]
pub fn script_counts(text: &str) -> Vec<usize> {
    engine::script_counts(text)
}
