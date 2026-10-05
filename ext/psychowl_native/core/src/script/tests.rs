use super::*;

#[test]
fn of_char() {
    assert_eq!(Script::of_char('a'), Some(Script::Latin));
    assert_eq!(Script::of_char('é'), Some(Script::Latin));
    assert_eq!(Script::of_char('ж'), Some(Script::Cyrillic));
    assert_eq!(Script::of_char('の'), Some(Script::Hiragana));
    assert_eq!(Script::of_char('語'), Some(Script::Han));
    assert_eq!(Script::of_char('1'), None);
    assert_eq!(Script::of_char('😀'), None);
}

#[test]
fn cyrillic_letters_inside_the_phonetic_block() {
    assert_eq!(Script::of_char('\u{1D2B}'), Some(Script::Cyrillic));
    assert_eq!(Script::of_char('\u{1D2A}'), Some(Script::Latin));
    assert_eq!(Script::of_char('\u{1D2C}'), Some(Script::Latin));
}

#[test]
fn indices_follow_the_data_file() {
    assert_eq!(Script::all().len(), 25);
    for (index, script) in Script::all().iter().enumerate() {
        assert_eq!(script.index(), index);
        assert_eq!(Script::from_index(index), Some(*script));
    }
}

#[test]
fn langs() {
    assert_eq!(Script::Han.langs(), &[Lang::Cmn, Lang::Jpn]);
    assert_eq!(Script::Greek.langs(), []);
}
