use super::*;

fn unpack(trigram: Trigram) -> String {
    let mask = (1 << 21) - 1;
    [trigram >> 42, (trigram >> 21) & mask, trigram & mask]
        .iter()
        .filter_map(|&code_point| u32::try_from(code_point).ok().and_then(char::from_u32))
        .collect()
}

fn trigrams_of(text: &str) -> Vec<String> {
    let mut trigrams: Vec<String> =
        positions(text).keys().map(|&trigram| unpack(trigram)).collect();
    trigrams.sort();
    trigrams
}

#[test]
fn trigrams_skip_word_boundaries() {
    assert_eq!(trigrams_of("ab, c"), vec![" ab", " c ", "ab "]);
}

#[test]
fn trigrams_are_ranked_by_count_then_descending_trigram() {
    let positions = positions("aa aa ab");
    assert_eq!(positions[&pack('a', 'a', ' ')], 0);
    assert_eq!(positions[&pack('a', ' ', 'a')], 1);
    assert_eq!(positions[&pack(' ', 'a', 'a')], 2);
    assert_eq!(positions[&pack('a', 'b', ' ')], 3);
    assert_eq!(positions[&pack(' ', 'a', 'b')], 4);
}

#[test]
fn packing_keeps_character_order() {
    assert!(pack('a', 'b', 'c') < pack('a', 'b', 'd'));
    assert!(pack('a', 'z', 'z') < pack('b', ' ', ' '));
    assert_eq!(unpack(pack('ж', ' ', '語')), "ж 語");
}

#[test]
fn distance_is_bounded() {
    let profile = [pack('x', 'y', 'z'); 300];
    let positions = positions("hello world");
    assert!(distance(&profile, &positions) <= MAX_TOTAL_DISTANCE);
}
