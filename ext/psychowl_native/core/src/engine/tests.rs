use super::*;

#[test]
fn confidence_edges() {
    assert_eq!(confidence(0.0, 0.0, 10), 0.0);
    assert_eq!(confidence(0.4, 0.0, 10), 0.4);
    assert_eq!(confidence(0.9, 0.1, 10), 1.0);
    assert!(confidence(0.5, 0.49, 10) < 0.1);
}

#[test]
fn script_ties_go_to_the_lower_index() {
    assert_eq!(main_script(&script_counts("ab вы")), Some(Script::Latin));
    assert_eq!(main_script(&script_counts("123")), None);
}

#[test]
fn lowercase_has_no_final_sigma() {
    assert_eq!(lowercase("ΣΟΦΟΣ"), "σοφοσ");
}
