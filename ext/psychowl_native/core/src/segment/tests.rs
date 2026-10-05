use super::*;
use crate::Lang;

fn pieces(text: &str) -> Vec<&str> {
    sentences(text).into_iter().map(|range| &text[range]).collect()
}

#[test]
fn splits_on_marks_followed_by_space() {
    assert_eq!(
        pieces("Hello there. How are you?! Fine… 3.14 is pi\nNew line。日本語！ok"),
        vec![
            "Hello there. ",
            "How are you?! ",
            "Fine… ",
            "3.14 is pi\n",
            "New line。",
            "日本語！",
            "ok"
        ]
    );
}

#[test]
fn empty_text_has_no_sentences() {
    assert_eq!(sentences(""), [] as [std::ops::Range<usize>; 0]);
}

#[test]
fn merges_runs_and_attaches_numbers() {
    let text = "Hello, this is an English sentence about cats. \
                Ceci est une phrase en français sur les chats. 12345. \
                Und das ist ein deutscher Satz über Katzen.";
    let found: Vec<(Lang, &str)> = segments(text, &Filter::All)
        .iter()
        .map(|segment| (segment.info().lang(), segment.text(text)))
        .collect();

    assert_eq!(
        found,
        vec![
            (Lang::Eng, "Hello, this is an English sentence about cats. "),
            (Lang::Fra, "Ceci est une phrase en français sur les chats. 12345. "),
            (Lang::Deu, "Und das ist ein deutscher Satz über Katzen."),
        ]
    );
}

#[test]
fn unsupported_script_keeps_the_first_sentence_result() {
    let text = "Hello there my friend. \
                Μετά τη διάλυση της Δεύτερης \
                Τριανδρίας ο Οκταβιανός.";
    let segments = segments(text, &Filter::All);
    assert_eq!(segments.len(), 1);
    assert_eq!(segments[0].info().lang(), Lang::Eng);
    assert_eq!(segments[0].range(), 0..text.len());
}
