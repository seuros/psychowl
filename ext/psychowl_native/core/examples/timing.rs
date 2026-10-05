//! Rough timing of the core engine, without Ruby in the way.
//! cargo run --release --example timing -p psychowl

use std::time::Instant;

fn main() {
    let sentence = "Es ist die Zeit des Sommers, des üppigen Wachstums, des Eintritts in \
                    die Pubertät und der Entfaltung der Vegetation. Die Tage sind lang, \
                    die Nächte kurz, und die Sonne scheint warm auf die Felder, Wiesen \
                    und Wälder des Landes.";
    let document = sentence.repeat(450);

    for (name, text, iterations) in
        [("sentence", sentence, 20_000), ("document", document.as_str(), 20)]
    {
        let start = Instant::now();
        for _ in 0..iterations {
            std::hint::black_box(psychowl::detect(std::hint::black_box(text)));
        }
        let each = start.elapsed() / iterations;
        println!("{name:>9} ({:>6} bytes): {each:?}", text.len());
    }
}
