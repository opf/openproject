# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module ProjectIdentifiers
  module IdentifierAutofix
    # Generates a short uppercase semantic identifier for each project.
    #
    # Identifiers are 2–10 uppercase alphanumeric characters that always start
    # with a letter.
    #
    # == Algorithm
    #
    # *Multi-word names* use word initials, truncated to +IDENTIFIER_LENGTH[:base]+ (5):
    #   "Flight Planning Algorithm" → "FPA"
    #   "A B C D E F G H I J K"   → "ABCDE"
    #
    # *Single-word names* use the first +IDENTIFIER_LENGTH[:single_word]+ (3) characters:
    #   "Banana" → "BAN"
    #
    # *Accented characters* are transliterated ("Cécile" → "CEC").
    # *Non-Latin scripts* that have no transliteration fall back to "PROJ".
    #
    # == Collision resolution
    #
    # When a candidate is already taken, the identifier is progressively widened
    # with more characters from the name, up to +IDENTIFIER_LENGTH[:max]+ (10):
    #
    #   Multi-word:  "SC" → "STC" → "STCO" → "STRCO" → … → "STREACOMMU"
    #   Single-word: "BAN" → "BANA" → "BANAN" → "BANANA"
    #   Initials:    "ABCDE" → "ABCDEF" → … → "ABCDEFGHIJ"
    #
    # If all expansion candidates are exhausted, a numeric suffix is appended
    # as a last resort ("GO" → "GO2").
    #
    class ProjectIdentifierSuggestionGenerator
      IDENTIFIER_LENGTH = { min: 2, max: 10, base: 5, single_word: 3 }.freeze
      FALLBACK_IDENTIFIER = "PROJ"
      SUFFIX_LIMIT = 10_000

      def self.call(projects, exclude: Set.new)
        new.call(projects, exclude:)
      end

      # Returns a single suggested identifier string for the given project name.
      #
      def self.suggest_identifier(name, exclude: Set.new)
        new.suggest_identifier(name, exclude:)
      end

      def call(projects, exclude:)
        generate_suggestions(projects, exclude:)
      end

      def suggest_identifier(name, exclude: Set.new)
        candidates = identifier_candidates(name)
        find_unique(candidates, exclude)
      end

      private

      def generate_suggestions(projects, exclude:)
        excluded = exclude.dup

        projects.map do |project|
          candidates = identifier_candidates(project.name)
          identifier = find_unique(candidates, excluded)
          excluded << identifier

          {
            project:,
            current_identifier: project.identifier,
            suggested_identifier: identifier
          }
        end
      end

      # Returns an ordered list of progressively longer identifier candidates
      # derived from the project name. The first unique candidate wins.
      def identifier_candidates(name)
        words = transliterated_words(name)
        return [FALLBACK_IDENTIFIER] if words.empty?

        candidates = words.size == 1 ? single_word_candidates(words.first) : multi_word_candidates(words)
        candidates = candidates.filter_map do |c|
          stripped = ensure_starts_with_letter(c)
          stripped if stripped&.length.to_i >= IDENTIFIER_LENGTH[:min]
        end
        candidates.presence || [FALLBACK_IDENTIFIER]
      end

      # Splits a name into words and transliterates each, returning only words
      # that contain at least one ASCII-alphanumeric character.
      def transliterated_words(name)
        # Use POSIX [[:alpha:]] so accented letters (é, ñ, ü…) are kept inside
        # their word rather than treated as separators by the ASCII-only [a-zA-Z].
        raw_words = name.to_s.scan(/[[:alpha:][:digit:]]+/)
        raw_words.filter_map do |word|
          t = I18n.with_locale(:en) { I18n.transliterate(word) }
          clean = t.gsub(/[^A-Za-z0-9]/, "")
          clean.presence
        end
      end

      # "Banana" → ["BAN", "BANA", "BANAN", "BANANA"]
      def single_word_candidates(word)
        chars = word.upcase
        max_len = [chars.length, IDENTIFIER_LENGTH[:max]].min
        return [] if max_len < IDENTIFIER_LENGTH[:min]

        start_len = IDENTIFIER_LENGTH[:single_word].clamp(IDENTIFIER_LENGTH[:min], max_len)
        (start_len..max_len).map { chars[0, it] }
      end

      # "Stream Communicator" → ["SC", "STC", "STCO", "STRCO", …]
      # "A B C D E F G H I J K" → ["ABCDE", "ABCDEF", …, "ABCDEFGHIJ"]
      #
      # Starts with initials truncated to IDENTIFIER_LENGTH[:base], progressively
      # includes more initials, then expands words beyond single chars.
      def multi_word_candidates(words)
        upcased_words = words.map(&:upcase)
        candidates = initial_candidates(upcased_words)

        append_expansion_candidates!(candidates, upcased_words) if candidates.last.length < IDENTIFIER_LENGTH[:max]
        candidates
      end

      def initial_candidates(upcased_words)
        initials = upcased_words.pluck(0).join[0, IDENTIFIER_LENGTH[:max]]
        start = [IDENTIFIER_LENGTH[:base], initials.length].min
        (start..initials.length).map { initials[0, it] }
      end

      # Progressively pulls more characters from each word left-to-right.
      def append_expansion_candidates!(candidates, upcased_words)
        chars_per_word = upcased_words.map { 1 }

        loop do
          expandable = upcased_words.each_index.find { |i| chars_per_word[i] < upcased_words[i].length }
          break unless expandable

          chars_per_word[expandable] += 1
          candidate = build_candidate(upcased_words, chars_per_word)
          candidates << candidate unless candidates.include?(candidate)
          break if candidate.length >= IDENTIFIER_LENGTH[:max]
        end
      end

      def build_candidate(upcased_words, chars_per_word)
        parts = upcased_words.each_with_index.map { |w, i| w[0, chars_per_word[i]] }
        parts.join[0, IDENTIFIER_LENGTH[:max]]
      end

      # Strips leading digits so identifiers always start with a letter.
      # For names like "3D Printing Lab", initials "3PL" become "PL".
      # This is lossy but acceptable for auto-generated suggestions.
      def ensure_starts_with_letter(candidate)
        candidate.sub(/\A\d+/, "").presence
      end

      # Iterates through expansion candidates, then falls back to numeric suffix.
      # Candidates are already filtered to start with a letter and meet min length.
      def find_unique(candidates, used_identifiers)
        candidates.each do |candidate|
          return candidate unless used_identifiers.include?(candidate)
        end

        base = candidates.last || FALLBACK_IDENTIFIER
        numeric_suffix_fallback(base, used_identifiers)
      end

      def numeric_suffix_fallback(base, used_identifiers)
        # Ensure the base itself starts with a letter before appending digits.
        base = ensure_starts_with_letter(base) || FALLBACK_IDENTIFIER

        counter = 2
        loop do
          raise "Could not find a unique identifier for base '#{base}' within #{SUFFIX_LIMIT} attempts" \
            if counter > SUFFIX_LIMIT

          suffix = counter.to_s
          candidate = "#{base[0, IDENTIFIER_LENGTH[:max] - suffix.length]}#{suffix}"
          return candidate unless used_identifiers.include?(candidate)

          counter += 1
        end
      end
    end
  end
end
