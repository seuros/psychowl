use crate::{Lang, Script, Segment, engine, segment};

#[cfg(test)]
mod tests;

/// Confidence above which a detection is considered reliable.
const RELIABLE_CONFIDENCE: f64 = 0.9;

/// Which languages a [`Detector`] may answer with.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub enum Filter {
    /// Every supported language.
    #[default]
    All,
    /// Only these languages.
    Allow(Vec<Lang>),
    /// Every supported language except these.
    Deny(Vec<Lang>),
}

impl Filter {
    #[must_use]
    pub fn is_allowed(&self, lang: Lang) -> bool {
        match self {
            Self::All => true,
            Self::Allow(langs) => langs.contains(&lang),
            Self::Deny(langs) => !langs.contains(&lang),
        }
    }
}

/// Outcome of a detection.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Info {
    lang: Lang,
    script: Script,
    confidence: f64,
}

impl Info {
    #[must_use]
    pub const fn new(lang: Lang, script: Script, confidence: f64) -> Self {
        Self { lang, script, confidence }
    }

    #[must_use]
    pub const fn lang(&self) -> Lang {
        self.lang
    }

    #[must_use]
    pub const fn script(&self) -> Script {
        self.script
    }

    /// 0.0 to 1.0: how far the winner is ahead of the runner-up.
    #[must_use]
    pub const fn confidence(&self) -> f64 {
        self.confidence
    }

    #[must_use]
    pub const fn is_reliable(&self) -> bool {
        self.confidence > RELIABLE_CONFIDENCE
    }
}

/// Detects languages, optionally restricted by a [`Filter`].
///
/// ```
/// use psychowl::{Detector, Lang};
///
/// // Portuguese is not on the list, so the closest allowed language wins.
/// let detector = Detector::with_allowlist(vec![Lang::Eng, Lang::Spa]);
/// let promise = "O presidente prometeu que desta vez a obra termina no prazo.";
/// assert_eq!(detector.detect_lang(promise), Some(Lang::Spa));
/// ```
#[derive(Debug, Clone, Default)]
pub struct Detector {
    filter: Filter,
}

impl Detector {
    #[must_use]
    pub const fn new() -> Self {
        Self { filter: Filter::All }
    }

    #[must_use]
    pub const fn with_filter(filter: Filter) -> Self {
        Self { filter }
    }

    #[must_use]
    pub const fn with_allowlist(langs: Vec<Lang>) -> Self {
        Self::with_filter(Filter::Allow(langs))
    }

    #[must_use]
    pub const fn with_denylist(langs: Vec<Lang>) -> Self {
        Self::with_filter(Filter::Deny(langs))
    }

    #[must_use]
    pub const fn filter(&self) -> &Filter {
        &self.filter
    }

    #[must_use]
    pub fn detect(&self, text: &str) -> Option<Info> {
        engine::detect(text, &self.filter)
    }

    #[must_use]
    pub fn detect_lang(&self, text: &str) -> Option<Lang> {
        self.detect(text).map(|info| info.lang())
    }

    /// Scripts ignore the filter.
    #[must_use]
    pub fn detect_script(&self, text: &str) -> Option<Script> {
        crate::detect_script(text)
    }

    /// Every candidate language of the text's script with its score, best
    /// first. Scores are relative to each other, not probabilities.
    #[must_use]
    pub fn candidates(&self, text: &str) -> Vec<(Lang, f64)> {
        engine::candidates(text, &self.filter)
    }

    /// Splits `text` into sentences and groups consecutive sentences of the
    /// same language. See [`Segment`].
    #[must_use]
    pub fn segments(&self, text: &str) -> Vec<Segment> {
        segment::segments(text, &self.filter)
    }
}
