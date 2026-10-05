# Training corpora

Plain UTF-8 text, one file per language: `corpus/<code>.txt`. Used by
`rake "psychowl:train[<code>]"` to (re)build `trigrams/<code>.txt`. Not
shipped in the gem.

Only use text you may redistribute, and record where it came from in
`SOURCES.md` next to it, for example:

- Universal Declaration of Human Rights translations (public domain)
- Tatoeba sentences (CC BY 2.0 FR)
- Wikipedia articles (CC BY-SA 4.0; attribution required)

A few hundred kilobytes of varied prose per language is plenty. After
training, run `rake test:all`: every sample must still be detected, and
both engines must still agree.
