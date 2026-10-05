use super::*;

#[test]
fn indices_follow_the_data_file() {
    for (index, lang) in Lang::all().iter().enumerate() {
        assert_eq!(lang.index(), index);
        assert_eq!(Lang::from_index(index), Some(*lang));
    }
    assert_eq!(Lang::from_index(Lang::all().len()), None);
}

#[test]
fn lookup_by_either_code() {
    assert_eq!(Lang::from_code("deu"), Some(Lang::Deu));
    assert_eq!(Lang::from_code("DE"), Some(Lang::Deu));
    assert_eq!(Lang::from_code("klingon"), None);
    assert_eq!("spa".parse::<Lang>(), Ok(Lang::Spa));
    assert_eq!("tlh".parse::<Lang>(), Err(UnknownLang("tlh".into())));
}

#[test]
fn attributes() {
    assert_eq!(Lang::Deu.code(), "deu");
    assert_eq!(Lang::Deu.iso639_1(), "de");
    assert_eq!(Lang::Deu.name(), "Deutsch");
    assert_eq!(Lang::Deu.eng_name(), "German");
    assert_eq!(Lang::Deu.to_string(), "deu");
}
