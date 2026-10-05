use std::fmt;

use crate::{ALL_SCRIPTS, ASCII_SCRIPTS, Lang, SCRIPT_RANGES, SCRIPTS, Script, ScriptRow};

#[cfg(test)]
mod tests;

impl Script {
    /// Every known script, in detection priority order.
    #[must_use]
    pub const fn all() -> &'static [Self] {
        ALL_SCRIPTS
    }

    /// The script at `index` in [`Script::all`].
    #[must_use]
    pub const fn from_index(index: usize) -> Option<Self> {
        if index < ALL_SCRIPTS.len() { Some(ALL_SCRIPTS[index]) } else { None }
    }

    /// Position in [`Script::all`]. Lower wins ties.
    #[must_use]
    pub const fn index(self) -> usize {
        self as usize
    }

    const fn row(self) -> &'static ScriptRow {
        &SCRIPTS[self.index()]
    }

    /// e.g. `"Cyrillic"`.
    #[must_use]
    pub const fn name(self) -> &'static str {
        self.row().name
    }

    /// Supported languages written in this script.
    #[must_use]
    pub const fn langs(self) -> &'static [Lang] {
        self.row().langs
    }

    /// The script `ch` belongs to, if any.
    #[must_use]
    pub fn of_char(ch: char) -> Option<Self> {
        if ch.is_ascii() {
            return ASCII_SCRIPTS[ch as usize];
        }
        let code_point = u32::from(ch);
        let position = SCRIPT_RANGES.partition_point(|&(_, high, _)| high < code_point);
        if let Some(&(low, _, script)) = SCRIPT_RANGES.get(position)
            && low <= code_point
        {
            Some(script)
        } else {
            None
        }
    }
}

impl fmt::Display for Script {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.name())
    }
}
