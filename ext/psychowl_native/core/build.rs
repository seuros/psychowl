//! Generates the `Lang`/`Script` enums and lookup tables from `data/`, the
//! files the Ruby engine reads too. Bad data fails the build.

use std::env;
use std::fmt::{self, Write as _};
use std::fs;
use std::path::{Path, PathBuf};

struct Language {
    code: String,
    iso639_1: String,
    eng_name: String,
    name: String,
}

struct ScriptRow {
    name: String,
    languages: Vec<String>,
    ranges: Vec<(u32, u32)>,
}

fn main() {
    let manifest_dir = env_path("CARGO_MANIFEST_DIR");
    let data = manifest_dir.join("data");
    println!("cargo:rerun-if-changed={}", data.display());

    let mut out = String::new();
    if let Err(error) = generate(&mut out, &data) {
        panic!("cannot generate tables.rs: {error}");
    }

    let path = env_path("OUT_DIR").join("tables.rs");
    fs::write(&path, out)
        .unwrap_or_else(|error| panic!("cannot write {}: {error}", path.display()));
}

fn env_path(name: &str) -> PathBuf {
    env::var(name).map_or_else(|error| panic!("{name}: {error}"), PathBuf::from)
}

fn generate(out: &mut String, data: &Path) -> fmt::Result {
    let languages = read_languages(data);
    let scripts = read_scripts(data);
    let alphabets = read_alphabets(data);
    let trigrams = read_trigrams(data, &languages);

    write_lang_enum(out, &languages)?;
    write_script_enum(out, &scripts, &languages)?;
    write_script_ranges(out, &scripts)?;
    write_alphabets(out, &alphabets, &languages)?;
    write_trigrams(out, &trigrams, &languages)
}

fn read_file(path: &Path) -> String {
    fs::read_to_string(path)
        .unwrap_or_else(|error| panic!("cannot read {}: {error}", path.display()))
}

/// Non-comment, non-empty lines split on tabs.
fn rows(path: &Path) -> Vec<Vec<String>> {
    let mut rows = Vec::new();
    for line in read_file(path).lines() {
        if line.is_empty() || line.starts_with('#') {
            continue;
        }
        rows.push(line.split('\t').map(str::to_owned).collect());
    }
    rows
}

fn read_languages(data: &Path) -> Vec<Language> {
    let mut languages = Vec::new();
    for row in rows(&data.join("languages.tsv")) {
        let [code, iso639_1, eng_name, name] = row.as_slice() else {
            panic!("languages.tsv: expected 4 fields in {row:?}");
        };
        languages.push(Language {
            code: code.clone(),
            iso639_1: iso639_1.clone(),
            eng_name: eng_name.clone(),
            name: name.clone(),
        });
    }
    languages
}

fn read_scripts(data: &Path) -> Vec<ScriptRow> {
    let mut scripts = Vec::new();
    for row in rows(&data.join("scripts.tsv")) {
        let [name, codes, hex_ranges] = row.as_slice() else {
            panic!("scripts.tsv: expected 3 fields in {row:?}");
        };
        let languages =
            if codes == "-" { Vec::new() } else { codes.split(',').map(str::to_owned).collect() };
        let mut ranges = Vec::new();
        for range in hex_ranges.split(',') {
            let (low, high) = range.split_once('-').unwrap_or((range, range));
            ranges.push((hex(low), hex(high)));
        }
        scripts.push(ScriptRow { name: name.clone(), languages, ranges });
    }
    scripts
}

fn hex(value: &str) -> u32 {
    u32::from_str_radix(value, 16)
        .unwrap_or_else(|error| panic!("scripts.tsv: bad code point {value}: {error}"))
}

fn read_alphabets(data: &Path) -> Vec<(String, Vec<char>)> {
    let mut alphabets = Vec::new();
    for row in rows(&data.join("alphabets.tsv")) {
        let [code, letters] = row.as_slice() else {
            panic!("alphabets.tsv: expected 2 fields in {row:?}");
        };
        let mut letters: Vec<char> = letters.chars().collect();
        letters.sort_unstable();
        letters.dedup();
        alphabets.push((code.clone(), letters));
    }
    alphabets
}

fn read_trigrams(data: &Path, languages: &[Language]) -> Vec<(String, Vec<[char; 3]>)> {
    let dir = data.join("trigrams");
    let entries = fs::read_dir(&dir).unwrap_or_else(|error| panic!("{}: {error}", dir.display()));
    for entry in entries.flatten() {
        let path = entry.path();
        let code = path.file_stem().and_then(|stem| stem.to_str()).unwrap_or_default();
        assert!(
            languages.iter().any(|language| language.code == code),
            "{}: no such language in languages.tsv",
            path.display()
        );
    }

    let mut profiles = Vec::new();
    for language in languages {
        let path = dir.join(format!("{}.txt", language.code));
        if !path.exists() {
            continue;
        }
        let mut trigrams = Vec::new();
        for line in read_file(&path).lines() {
            if line.starts_with('#') {
                continue;
            }
            let chars: Vec<char> = line.chars().map(|c| if c == '_' { ' ' } else { c }).collect();
            let &[first, second, third] = chars.as_slice() else {
                panic!("{}: not a trigram: {line:?}", path.display());
            };
            trigrams.push([first, second, third]);
        }
        profiles.push((language.code.clone(), trigrams));
    }
    profiles
}

/// `eng` -> `Eng`
fn variant(code: &str) -> String {
    let mut chars = code.chars();
    chars.next().map_or_else(String::new, |first| first.to_uppercase().chain(chars).collect())
}

/// Three 21-bit chars in one integer, first char in the highest bits, so
/// integer order equals character order. Must match `trigram::pack`.
fn pack(trigram: [char; 3]) -> u64 {
    (u64::from(trigram[0]) << 42) | (u64::from(trigram[1]) << 21) | u64::from(trigram[2])
}

/// `0x1EE00` -> `0x1_EE00`: hex digits in groups of four.
fn hex_literal(value: u64) -> String {
    let digits = format!("{value:X}");
    let mut groups = Vec::new();
    let mut end = digits.len();
    while end > 4 {
        groups.push(&digits[end - 4..end]);
        end -= 4;
    }
    groups.push(&digits[..end]);
    groups.reverse();
    format!("0x{}", groups.join("_"))
}

fn char_literal(ch: char) -> String {
    format!("'\\u{{{:X}}}'", u32::from(ch))
}

fn write_lang_enum(out: &mut String, languages: &[Language]) -> fmt::Result {
    out.push_str("/// A supported language, identified by its ISO 639-3 code.\n");
    out.push_str("#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]\n");
    out.push_str("#[non_exhaustive]\npub enum Lang {\n");
    for language in languages {
        writeln!(out, "    /// {} ({})", language.eng_name, language.name)?;
        writeln!(out, "    {},", variant(&language.code))?;
    }
    out.push_str("}\n\n");

    out.push_str("pub(crate) const LANGUAGES: &[LanguageRow] = &[\n");
    for language in languages {
        writeln!(
            out,
            "    LanguageRow {{ lang: Lang::{}, code: {:?}, iso639_1: {:?}, \
             eng_name: {:?}, name: {:?} }},",
            variant(&language.code),
            language.code,
            language.iso639_1,
            language.eng_name,
            language.name
        )?;
    }
    out.push_str("];\n\n");

    out.push_str("pub(crate) const ALL_LANGS: &[Lang] = &[");
    for language in languages {
        write!(out, "Lang::{}, ", variant(&language.code))?;
    }
    out.push_str("];\n\n");
    Ok(())
}

fn write_script_enum(
    out: &mut String,
    scripts: &[ScriptRow],
    languages: &[Language],
) -> fmt::Result {
    out.push_str("/// A writing system.\n");
    out.push_str("#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]\n");
    out.push_str("#[non_exhaustive]\npub enum Script {\n");
    for script in scripts {
        writeln!(out, "    {},", script.name)?;
    }
    out.push_str("}\n\n");

    out.push_str("pub(crate) const SCRIPTS: &[ScriptRow] = &[\n");
    for script in scripts {
        let mut langs = Vec::new();
        for code in &script.languages {
            assert!(
                languages.iter().any(|language| &language.code == code),
                "scripts.tsv: {} lists unknown language {code}",
                script.name
            );
            langs.push(format!("Lang::{}", variant(code)));
        }
        writeln!(
            out,
            "    ScriptRow {{ name: {:?}, langs: &[{}] }},",
            script.name,
            langs.join(", ")
        )?;
    }
    out.push_str("];\n\n");

    out.push_str("pub(crate) const ALL_SCRIPTS: &[Script] = &[");
    for script in scripts {
        write!(out, "Script::{}, ", script.name)?;
    }
    out.push_str("];\n\n");
    Ok(())
}

fn write_script_ranges(out: &mut String, scripts: &[ScriptRow]) -> fmt::Result {
    let mut ranges = Vec::new();
    for script in scripts {
        for &(low, high) in &script.ranges {
            ranges.push((low, high, script.name.as_str()));
        }
    }
    ranges.sort_unstable();
    for pair in ranges.windows(2) {
        assert!(
            pair[1].0 > pair[0].1,
            "scripts.tsv: {} and {} overlap at U+{:04X}",
            pair[0].2,
            pair[1].2,
            pair[1].0
        );
    }

    out.push_str("/// Script of each ASCII character, for a fast path.\n");
    out.push_str("pub(crate) const ASCII_SCRIPTS: [Option<Script>; 128] = [\n");
    for code_point in 0u32..128 {
        match ranges.iter().find(|(low, high, _)| (*low..=*high).contains(&code_point)) {
            Some((_, _, name)) => writeln!(out, "    Some(Script::{name}),")?,
            None => out.push_str("    None,\n"),
        }
    }
    out.push_str("];\n\n");

    out.push_str("/// Disjoint code point ranges, sorted, for binary search.\n");
    out.push_str("pub(crate) const SCRIPT_RANGES: &[(u32, u32, Script)] = &[\n");
    for (low, high, name) in ranges {
        let (low, high) = (hex_literal(low.into()), hex_literal(high.into()));
        writeln!(out, "    ({low}, {high}, Script::{name}),")?;
    }
    out.push_str("];\n\n");
    Ok(())
}

/// Letters per language, indexed like `Lang::all()`, sorted for binary search.
fn write_alphabets(
    out: &mut String,
    alphabets: &[(String, Vec<char>)],
    languages: &[Language],
) -> fmt::Result {
    for (code, _) in alphabets {
        assert!(
            languages.iter().any(|language| &language.code == code),
            "alphabets.tsv: unknown language {code}"
        );
    }

    out.push_str("/// Letters per language, indexed like `Lang::all()`, sorted.\n");
    out.push_str("pub(crate) const ALPHABETS: &[Option<&[char]>] = &[\n");
    for language in languages {
        match alphabets.iter().find(|(code, _)| *code == language.code) {
            Some((_, letters)) => {
                let letters: Vec<String> = letters.iter().map(|&ch| char_literal(ch)).collect();
                writeln!(out, "    Some(&[{}]), // {}", letters.join(", "), language.code)?;
            }
            None => writeln!(out, "    None, // {}", language.code)?,
        }
    }
    out.push_str("];\n\n");
    Ok(())
}

/// Trigram profiles indexed like `Lang::all()`, packed (see `trigram::pack`),
/// most frequent first.
fn write_trigrams(
    out: &mut String,
    profiles: &[(String, Vec<[char; 3]>)],
    languages: &[Language],
) -> fmt::Result {
    out.push_str("/// Trigram profiles, indexed like `Lang::all()`, most frequent first.\n");
    out.push_str("pub(crate) const TRIGRAMS: &[Option<&[u64]>] = &[\n");
    for language in languages {
        let Some((_, trigrams)) = profiles.iter().find(|(code, _)| *code == language.code) else {
            writeln!(out, "    None, // {}", language.code)?;
            continue;
        };
        writeln!(out, "    Some(&[ // {}", language.code)?;
        for &trigram in trigrams {
            let text: String = trigram.iter().collect();
            writeln!(out, "        {}, // {text:?}", hex_literal(pack(trigram)))?;
        }
        out.push_str("    ]),\n");
    }
    out.push_str("];\n");
    Ok(())
}
