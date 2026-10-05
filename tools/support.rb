# frozen_string_literal: true

require_relative '../lib/psychowl/data_file'

# Helpers shared by the data tools (import_whatlang.rb, train_profile.rb).
module DataTools
  DATA = File.expand_path('../ext/psychowl_native/core/data', __dir__)

  module_function

  # Lines of a data file, without blank lines and # comments.
  def data_lines(path) = Psychowl::DataFile.lines(path)

  # Writes trigrams/<code>.txt: a header, then one trigram per line, most
  # frequent first, "_" standing for a word boundary.
  #
  # @return [String] the path written
  def write_profile(code, trigrams, provenance)
    header = <<~TXT
      # #{code}: #{trigrams.size} most frequent trigrams, most frequent first. "_" marks a word boundary.
      # #{provenance}
    TXT
    path = File.join(DATA, 'trigrams', "#{code}.txt")
    body = trigrams.map { it.tr(' ', '_') }.join("\n")
    File.write(path, "#{header}#{body}\n")
    path
  end
end
