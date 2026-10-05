//! The detection algorithm. Mirrors `lib/psychowl/ruby_engine.rb` step by
//! step: both engines must return identical results for identical input.

use std::cmp::Ordering;

use rustc_hash::FxHashMap;

use crate::{ALPHABETS, Filter, Info, Lang, Script, trigram};

#[cfg(test)]
mod tests;

/// Where the text stands once its script is known.
enum Outcome {
    /// No letters, or no allowed language for the script.
    Nothing,
    /// Settled without scoring: one allowed language, or the Han rule.
    Decided(Info),
    /// Several allowed languages, scored best first.
    Scored { script: Script, scores: Vec<(Lang, f64)>, trigram_count: usize },
}

fn evaluate(text: &str, filter: &Filter) -> Outcome {
    let counts = script_counts(text);
    let Some(script) = main_script(&counts) else {
        return Outcome::Nothing;
    };
    if script == Script::Han {
        return detect_han(&counts, filter).map_or(Outcome::Nothing, Outcome::Decided);
    }

    let languages = allowed(script.langs(), filter);
    match languages.as_slice() {
        [] => Outcome::Nothing,
        &[only] => Outcome::Decided(Info::new(only, script, 1.0)),
        _ => {
            let (scores, trigram_count) = language_scores(text, &languages);
            Outcome::Scored { script, scores, trigram_count }
        }
    }
}

pub fn detect(text: &str, filter: &Filter) -> Option<Info> {
    match evaluate(text, filter) {
        Outcome::Nothing => None,
        Outcome::Decided(info) => Some(info),
        Outcome::Scored { script, scores, trigram_count } => {
            let (best, best_score) = scores[0];
            let runner_up_score = scores[1].1;
            let confidence = confidence(best_score, runner_up_score, trigram_count);
            Some(Info::new(best, script, confidence))
        }
    }
}

pub fn candidates(text: &str, filter: &Filter) -> Vec<(Lang, f64)> {
    match evaluate(text, filter) {
        Outcome::Nothing => Vec::new(),
        Outcome::Decided(info) => vec![(info.lang(), info.confidence())],
        Outcome::Scored { scores, .. } => scores,
    }
}

/// Number of characters per script, indexed like `Script::all()`.
pub fn script_counts(text: &str) -> Vec<usize> {
    let mut counts = vec![0; Script::all().len()];
    for ch in text.chars() {
        if let Some(script) = Script::of_char(ch) {
            counts[script.index()] += 1;
        }
    }
    counts
}

/// The script with the most characters; ties go to the lower index.
pub fn main_script(counts: &[usize]) -> Option<Script> {
    let mut best: Option<usize> = None;
    for (index, &count) in counts.iter().enumerate() {
        if count > 0 && best.is_none_or(|best_index| count > counts[best_index]) {
            best = Some(index);
        }
    }
    best.and_then(Script::from_index)
}

fn allowed(languages: &[Lang], filter: &Filter) -> Vec<Lang> {
    let mut result = Vec::new();
    for &lang in languages {
        if filter.is_allowed(lang) {
            result.push(lang);
        }
    }
    result
}

/// Han characters are shared by Chinese and Japanese; kana tips it to Japanese.
#[expect(clippy::cast_precision_loss, reason = "character counts are far below 2^52")]
fn detect_han(counts: &[usize], filter: &Filter) -> Option<Info> {
    let languages = allowed(Script::Han.langs(), filter);
    let mandarin = languages.contains(&Lang::Cmn);
    let japanese = languages.contains(&Lang::Jpn);

    match (mandarin, japanese) {
        (false, false) => return None,
        (true, false) => return Some(Info::new(Lang::Cmn, Script::Han, 1.0)),
        (false, true) => return Some(Info::new(Lang::Jpn, Script::Han, 1.0)),
        (true, true) => {}
    }

    let han = counts[Script::Han.index()];
    let kana = counts[Script::Hiragana.index()] + counts[Script::Katakana.index()];
    let kana_ratio = kana as f64 / (han + kana) as f64;

    let (lang, confidence) = if kana_ratio > 0.2 {
        (Lang::Jpn, 1.0)
    } else if kana_ratio > 0.05 {
        (Lang::Jpn, 0.5)
    } else if kana_ratio > 0.02 {
        (Lang::Cmn, 0.5)
    } else {
        (Lang::Cmn, 1.0)
    };
    Some(Info::new(lang, Script::Han, confidence))
}

/// Blends alphabet and trigram scores: short texts lean on the alphabet,
/// longer ones on trigrams. Returns scores (best first) and the trigram count.
#[expect(
    clippy::suboptimal_flops,
    reason = "a fused multiply-add rounds differently from the Ruby engine's multiply then add"
)]
fn language_scores(text: &str, languages: &[Lang]) -> (Vec<(Lang, f64)>, usize) {
    let lowercase = lowercase(text);
    let (alphabet_scores, char_count) = alphabet_scores(&lowercase, languages);
    let (trigram_scores, trigram_count) = trigram::scores(&lowercase, languages);

    let alphabet_weight = alphabet_weight(char_count);
    let trigram_weight = 1.0 - alphabet_weight;

    let mut scores = Vec::with_capacity(languages.len());
    for (index, &lang) in languages.iter().enumerate() {
        let score =
            (alphabet_scores[index] * alphabet_weight) + (trigram_scores[index] * trigram_weight);
        scores.push((lang, score));
    }

    // Highest score first; ties go to the lower language index.
    scores.sort_by(|(lang_a, score_a), (lang_b, score_b)| {
        score_b.partial_cmp(score_a).unwrap_or(Ordering::Equal).then_with(|| lang_a.cmp(lang_b))
    });
    (scores, trigram_count)
}

/// 2/3 for an empty text, falling to 1/3 at 100 letters and beyond.
#[expect(clippy::cast_precision_loss, reason = "character counts are far below 2^52")]
fn alphabet_weight(char_count: usize) -> f64 {
    (-(char_count as f64 / 300.0) + (2.0 / 3.0)).clamp(1.0 / 3.0, 2.0 / 3.0)
}

/// Character-by-character lowercasing, like Ruby's `String#downcase` (no
/// context-dependent final sigma).
fn lowercase(text: &str) -> String {
    let mut result = String::with_capacity(text.len());
    for ch in text.chars() {
        result.extend(ch.to_lowercase());
    }
    result
}

/// ASCII controls, spaces, digits and punctuation carry no language information.
pub const fn is_stop_char(ch: char) -> bool {
    matches!(ch, '\u{0000}'..='\u{0040}' | '\u{005B}'..='\u{0060}' | '\u{007B}'..='\u{007E}')
}

/// Share of letters that belong to each language's alphabet; a letter
/// outside the alphabet counts against the language.
#[expect(clippy::cast_precision_loss, reason = "character counts are far below 2^52")]
fn alphabet_scores(lowercase: &str, languages: &[Lang]) -> (Vec<f64>, usize) {
    let has_alphabet = languages.iter().any(|&lang| alphabet(lang).is_some());
    if !has_alphabet {
        return (vec![1.0; languages.len()], 1);
    }

    // One pass over the text; each alphabet then sums its letters.
    let mut char_count = 0;
    let mut frequencies: FxHashMap<char, usize> = FxHashMap::default();
    for ch in lowercase.chars() {
        if !is_stop_char(ch) {
            char_count += 1;
            *frequencies.entry(ch).or_insert(0) += 1;
        }
    }

    let mut scores = Vec::with_capacity(languages.len());
    for &lang in languages {
        let mut hits = 0;
        for letter in alphabet(lang).unwrap_or_default() {
            hits += frequencies.get(letter).copied().unwrap_or(0);
        }
        let raw = (2 * hits).saturating_sub(char_count);
        scores.push(raw as f64 / char_count as f64);
    }
    (scores, char_count)
}

const fn alphabet(lang: Lang) -> Option<&'static [char]> {
    ALPHABETS[lang.index()]
}

/// How far the best score is ahead of the runner-up, scaled by how much
/// evidence (trigrams) there was.
#[expect(clippy::cast_precision_loss, reason = "trigram counts are far below 2^52")]
fn confidence(best: f64, runner_up: f64, count: usize) -> f64 {
    if best == 0.0 {
        return 0.0;
    }
    if runner_up == 0.0 {
        return best;
    }

    let confident_rate = (3.0 / count as f64) + 0.015;
    let rate = (best - runner_up) / runner_up;
    if rate > confident_rate { 1.0 } else { rate / confident_rate }
}
