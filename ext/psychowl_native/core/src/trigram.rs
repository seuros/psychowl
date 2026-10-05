//! Trigram model, mirrored by `lib/psychowl/ruby_engine/trigrams.rb`.

use rustc_hash::FxHashMap;

use crate::engine::is_stop_char;
use crate::{Lang, TRIGRAMS};

#[cfg(test)]
mod tests;

/// A profile trigram missing from the text costs this much distance.
const MAX_TRIGRAM_DISTANCE: usize = 300;
const MAX_TOTAL_DISTANCE: usize = MAX_TRIGRAM_DISTANCE * MAX_TRIGRAM_DISTANCE;
/// Only the most frequent trigrams of the text are compared.
const TEXT_TRIGRAMS_SIZE: usize = 600;

/// A trigram packed into one integer: three 21-bit chars, first char in the
/// highest bits, so integer order equals character order. `build.rs` packs
/// the profiles the same way.
type Trigram = u64;

fn pack(first: char, second: char, third: char) -> Trigram {
    (u64::from(first) << 42) | (u64::from(second) << 21) | u64::from(third)
}

const fn profile(lang: Lang) -> Option<&'static [Trigram]> {
    TRIGRAMS[lang.index()]
}

/// Similarity between the text's trigram ranking and each language profile,
/// plus the number of distinct trigrams in the text.
#[expect(clippy::cast_precision_loss, reason = "distances are at most 180 000")]
pub fn scores(lowercase: &str, languages: &[Lang]) -> (Vec<f64>, usize) {
    let positions = positions(lowercase);
    let max_distance = positions.len() * MAX_TRIGRAM_DISTANCE;

    let mut scores = Vec::with_capacity(languages.len());
    for &lang in languages {
        let score = profile(lang).map_or(0.0, |trigrams| {
            // Never saturates: the distance is at most `max_distance`.
            let similarity = max_distance.saturating_sub(distance(trigrams, &positions));
            similarity as f64 / max_distance as f64
        });
        scores.push(score);
    }
    (scores, positions.len())
}

/// trigram => rank: the text's most frequent trigrams, most frequent first
/// (ties broken by the trigram itself, descending).
fn positions(lowercase: &str) -> FxHashMap<Trigram, usize> {
    let mut ranked: Vec<(usize, Trigram)> =
        count(lowercase).into_iter().map(|(trigram, count)| (count, trigram)).collect();
    ranked.sort_unstable_by(|a, b| b.cmp(a));

    let mut positions = FxHashMap::default();
    for (rank, (_count, trigram)) in ranked.into_iter().take(TEXT_TRIGRAMS_SIZE).enumerate() {
        positions.insert(trigram, rank);
    }
    positions
}

/// trigram => occurrences. Punctuation and digits act as spaces; trigrams
/// that are only word boundary are skipped.
fn count(lowercase: &str) -> FxHashMap<Trigram, usize> {
    let mut counts: FxHashMap<Trigram, usize> = FxHashMap::default();
    let mut first = ' ';
    let mut second: Option<char> = None;

    let chars = lowercase.chars().map(|ch| if is_stop_char(ch) { ' ' } else { ch });
    for third in chars.chain(std::iter::once(' ')) {
        let Some(middle) = second else {
            second = Some(third);
            continue;
        };
        let at_boundary = middle == ' ' && (first == ' ' || third == ' ');
        if !at_boundary {
            *counts.entry(pack(first, middle, third)).or_insert(0) += 1;
        }
        first = middle;
        second = Some(third);
    }
    counts
}

fn distance(profile: &[Trigram], positions: &FxHashMap<Trigram, usize>) -> usize {
    let mut total = 0;
    for (index, trigram) in profile.iter().enumerate() {
        total += positions
            .get(trigram)
            .map_or(MAX_TRIGRAM_DISTANCE, |&position| position.abs_diff(index));
    }

    // A short text cannot hold every profile trigram; do not count those.
    let unique = positions.len();
    if unique < MAX_TRIGRAM_DISTANCE {
        total = total.saturating_sub((MAX_TRIGRAM_DISTANCE - unique) * MAX_TRIGRAM_DISTANCE);
    }
    total.min(MAX_TOTAL_DISTANCE)
}
