//! Per-sentence detection, mirrored by `lib/psychowl/ruby_engine/segmentation.rb`.

use std::ops::Range;

use crate::{Filter, Info, engine};

#[cfg(test)]
mod tests;

/// Sentence-ending marks that need a following space ("3.14" is no boundary).
const SENTENCE_MARKS: [char; 4] = ['.', '!', '?', '\u{2026}'];
/// CJK sentence-ending marks, no space needed.
const CLOSING_MARKS: [char; 3] = ['\u{3002}', '\u{FF01}', '\u{FF1F}'];

/// A stretch of text in one language.
#[derive(Debug, Clone, PartialEq)]
pub struct Segment {
    range: Range<usize>,
    info: Info,
}

impl Segment {
    /// Byte range in the original text.
    #[must_use]
    pub fn range(&self) -> Range<usize> {
        self.range.clone()
    }

    #[must_use]
    pub const fn info(&self) -> Info {
        self.info
    }

    /// The segment's slice of `text`, the string it was detected in.
    #[must_use]
    pub fn text<'a>(&self, text: &'a str) -> &'a str {
        &text[self.range.clone()]
    }
}

/// ASCII whitespace and controls, no-break space, ideographic space.
const fn is_space(ch: char) -> bool {
    ch <= ' ' || ch == '\u{00A0}' || ch == '\u{3000}'
}

/// Sentence byte ranges. A sentence ends after a newline, 。！？, or . ! ? …
/// followed by a space; trailing spaces stay with it.
#[must_use]
pub fn sentences(text: &str) -> Vec<Range<usize>> {
    let chars: Vec<(usize, char)> = text.char_indices().collect();
    let byte_at = |index: usize| chars.get(index).map_or(text.len(), |&(byte, _)| byte);

    let mut sentences = Vec::new();
    let mut start = 0;
    let mut index = 0;

    while index < chars.len() {
        let ch = chars[index].1;
        let boundary = if ch == '\n' || CLOSING_MARKS.contains(&ch) {
            index += 1;
            true
        } else if SENTENCE_MARKS.contains(&ch) {
            while index < chars.len() && SENTENCE_MARKS.contains(&chars[index].1) {
                index += 1;
            }
            index == chars.len() || is_space(chars[index].1)
        } else {
            index += 1;
            false
        };

        if !boundary {
            continue;
        }
        while index < chars.len() && is_space(chars[index].1) {
            index += 1;
        }
        sentences.push(byte_at(start)..byte_at(index));
        start = index;
    }

    if start < chars.len() {
        sentences.push(byte_at(start)..text.len());
    }
    sentences
}

/// Runs of same-language sentences. Sentences without a language join the
/// previous run (or the first). Each run is re-detected whole and keeps its
/// first sentence's result if that changes the language.
pub fn segments(text: &str, filter: &Filter) -> Vec<Segment> {
    // (range, first sentence's detection)
    let mut runs: Vec<(Range<usize>, Info)> = Vec::new();
    let mut leading_start: Option<usize> = None;

    for sentence in sentences(text) {
        let detected = engine::detect(&text[sentence.clone()], filter);

        match (detected, runs.last_mut()) {
            (None, Some((range, _))) => range.end = sentence.end,
            (None, None) => {
                leading_start.get_or_insert(sentence.start);
            }
            (Some(info), Some((range, first))) if first.lang() == info.lang() => {
                range.end = sentence.end;
            }
            (Some(info), _) => {
                let start = leading_start.take().unwrap_or(sentence.start);
                runs.push((start..sentence.end, info));
            }
        }
    }

    let mut segments = Vec::with_capacity(runs.len());
    for (range, first) in runs {
        let info = match engine::detect(&text[range.clone()], filter) {
            Some(whole) if whole.lang() == first.lang() => whole,
            _ => first,
        };
        segments.push(Segment { range, info });
    }
    segments
}
