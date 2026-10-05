use std::fmt;
use std::str::FromStr;

use crate::{ALL_LANGS, LANGUAGES, Lang, LanguageRow};

#[cfg(test)]
mod tests;

impl Lang {
    /// Every supported language, sorted by ISO 639-3 code.
    #[must_use]
    pub const fn all() -> &'static [Self] {
        ALL_LANGS
    }

    /// Looks a language up by ISO 639-3 (`"deu"`) or ISO 639-1 (`"de"`) code,
    /// case-insensitively.
    #[must_use]
    pub fn from_code(code: &str) -> Option<Self> {
        let code = code.to_ascii_lowercase();
        LANGUAGES.iter().find(|row| row.code == code || row.iso639_1 == code).map(|row| row.lang)
    }

    /// The language at `index` in [`Lang::all`].
    #[must_use]
    pub const fn from_index(index: usize) -> Option<Self> {
        if index < ALL_LANGS.len() { Some(ALL_LANGS[index]) } else { None }
    }

    /// Position in [`Lang::all`].
    #[must_use]
    pub const fn index(self) -> usize {
        self as usize
    }

    const fn row(self) -> &'static LanguageRow {
        &LANGUAGES[self.index()]
    }

    /// ISO 639-3 code, e.g. `"deu"`.
    #[must_use]
    pub const fn code(self) -> &'static str {
        self.row().code
    }

    /// ISO 639-1 code, e.g. `"de"`.
    #[must_use]
    pub const fn iso639_1(self) -> &'static str {
        self.row().iso639_1
    }

    /// Name in the language itself, e.g. `"Deutsch"`.
    #[must_use]
    pub const fn name(self) -> &'static str {
        self.row().name
    }

    /// English name, e.g. `"German"`.
    #[must_use]
    pub const fn eng_name(self) -> &'static str {
        self.row().eng_name
    }
}

impl fmt::Display for Lang {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.code())
    }
}

/// Error returned when parsing an unsupported language code.
#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
#[error("unsupported language: {0}")]
pub struct UnknownLang(pub String);

impl FromStr for Lang {
    type Err = UnknownLang;

    fn from_str(code: &str) -> Result<Self, Self::Err> {
        Self::from_code(code).ok_or_else(|| UnknownLang(code.to_owned()))
    }
}
