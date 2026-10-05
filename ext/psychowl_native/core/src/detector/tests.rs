use super::*;

const PORTUGUESE: &str =
    "Eu gostaria de reservar uma mesa para duas pessoas amanhã à noite, por favor.";
const JAPANESE: &str = "日本語を勉強するのは難しいですが、\
                        とても楽しいです。";

#[test]
fn allowlist_restricts_candidates() {
    let detector = Detector::with_allowlist(vec![Lang::Spa, Lang::Eng]);
    assert_eq!(detector.detect_lang(PORTUGUESE), Some(Lang::Spa));
}

#[test]
fn denylist_excludes_languages() {
    let detector = Detector::with_denylist(vec![Lang::Por]);
    assert_eq!(detector.detect_lang(PORTUGUESE), Some(Lang::Spa));
}

#[test]
fn single_allowed_language_is_certain() {
    let info = Detector::with_allowlist(vec![Lang::Eng]).detect(PORTUGUESE);
    assert_eq!(info.map(|info| (info.lang(), info.confidence())), Some((Lang::Eng, 1.0)));
}

#[test]
fn filter_applies_to_single_language_scripts() {
    let detector = Detector::with_allowlist(vec![Lang::Eng, Lang::Fra]);
    assert_eq!(detector.detect("Летом мы ездили на море"), None);
}

#[test]
fn han_follows_the_filter() {
    let chinese = "学习一门新的语言";
    assert_eq!(Detector::with_allowlist(vec![Lang::Jpn]).detect_lang(chinese), Some(Lang::Jpn));
    assert_eq!(Detector::with_denylist(vec![Lang::Cmn, Lang::Jpn]).detect(chinese), None);
    assert_eq!(Detector::with_denylist(vec![Lang::Cmn]).detect_lang(JAPANESE), Some(Lang::Jpn));
}

#[test]
fn candidates_are_sorted_best_first() {
    let candidates = Detector::new().candidates(PORTUGUESE);
    assert_eq!(candidates[0].0, Lang::Por);
    assert!(candidates.is_sorted_by(|a, b| a.1 >= b.1));
}

#[test]
fn reliability() {
    assert!(Info::new(Lang::Eng, Script::Latin, 0.95).is_reliable());
    assert!(!Info::new(Lang::Eng, Script::Latin, 0.9).is_reliable());
}
