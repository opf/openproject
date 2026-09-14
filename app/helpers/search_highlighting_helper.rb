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

module SearchHighlightingHelper
  def highlight_text_by_terms(text, query_terms, css_class: "op-search-highlight")
    return "".html_safe if text.blank?

    terms = query_terms.filter_map { |term| term.to_s.presence }
    ranges = find_highlight_ranges(text, terms)
    return h(text) if ranges.empty?

    build_highlighted_segments(text, merge_highlight_ranges(ranges), css_class:)
  end

  private

  def find_highlight_ranges(text, query_terms)
    query_terms.flat_map { |term| occurrences_of(term, in_string: text) }
  end

  # Returns all character ranges where +term+ appears case-insensitively in +in_string+.
  def occurrences_of(term, in_string:)
    regex = Regexp.new(Regexp.escape(term), Regexp::IGNORECASE)
    ranges = []
    start = 0

    while (match = regex.match(in_string, start))
      ranges << (match.begin(0)...match.end(0))
      start = match.begin(0) + 1
    end

    ranges
  end

  # Splits +text+ into plain-text and highlighted segments according to +ranges+,
  # then joins them into a single HTML-safe string.
  def build_highlighted_segments(text, ranges, css_class:)
    pos = 0
    segments = ranges.flat_map do |range|
      before = pos < range.begin ? h(text[pos...range.begin]) : nil
      highlighted = content_tag(:span, text[range], class: css_class)
      pos = range.end

      [before, highlighted].compact
    end

    segments << h(text[pos..]) if pos < text.length
    safe_join(segments)
  end

  # Merges overlapping or adjacent ranges into a minimal set of non-overlapping ranges.
  def merge_highlight_ranges(ranges)
    ranges.sort_by(&:begin).each_with_object([]) do |range, merged|
      if merged.empty? || range.begin > merged.last.end
        merged << range
      else
        last = merged.last
        merged[-1] = (last.begin...[last.end, range.end].max)
      end
    end
  end
end
