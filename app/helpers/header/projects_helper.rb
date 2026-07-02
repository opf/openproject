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

module Header
  module ProjectsHelper
    def project_node_label(project, favorited: false, query_terms: [])
      name_html = query_terms.any? ? content_tag(:span, highlight_name(project.name, query_terms)) : project.name
      parts = [name_html]
      parts << favorite_icon if favorited
      parts << workspace_type_badge(project) if show_workspace_type_badge?(project)

      text = parts.length == 1 ? parts.first : safe_join(parts)
      render(Primer::BaseComponent.new(tag: :span, display: :inline_flex, align_items: :center)) { text }
    end

    private

    def highlight_name(name, query_terms)
      ranges = find_highlight_ranges(name, query_terms)
      return h(name) if ranges.empty?

      build_highlighted_segments(name, merge_highlight_ranges(ranges))
    end

    def find_highlight_ranges(name, query_terms)
      query_terms.flat_map { |term| occurrences_of(term, in_string: name) }
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

    # Splits +name+ into plain-text and highlighted segments according to +ranges+,
    # then joins them into a single HTML-safe string.
    def build_highlighted_segments(name, ranges)
      pos = 0
      segments = ranges.flat_map do |range|
        before = pos < range.begin ? h(name[pos...range.begin]) : nil
        highlighted = content_tag(:span, name[range], class: "op-search-highlight")
        pos = range.end
        [before, highlighted].compact
      end
      segments << h(name[pos..]) if pos < name.length
      safe_join(segments)
    end

    # Merges overlapping or adjacent ranges into a minimal set of non-overlapping ranges.
    def merge_highlight_ranges(ranges)
      ranges.sort_by(&:begin).each_with_object([]) do |range, merged|
        if merged.empty? || range.begin >= merged.last.end
          merged << range
        else
          last = merged.last
          merged[-1] = (last.begin...[last.end, range.end].max)
        end
      end
    end

    def favorite_icon
      render(Primer::Beta::Octicon.new(icon: :"star-fill", size: :small, classes: "op-primer--star-icon", ml: 2))
    end

    def workspace_type_badge(project)
      render(Primer::BaseComponent.new(tag: :span, display: :inline_flex, align_items: :center,
                                       color: :subtle, font_size: :small, ml: 2, classes: "description")) do
        safe_join([
                    render(Primer::Beta::Octicon.new(icon: workspace_icon(project.workspace_type), size: :xsmall, mr: 1)),
                    content_tag(:span, I18n.t(:"label_#{project.workspace_type}"))
                  ])
      end
    end

    def show_workspace_type_badge?(project)
      project.workspace_type.in?(%w[portfolio program])
    end
  end
end
