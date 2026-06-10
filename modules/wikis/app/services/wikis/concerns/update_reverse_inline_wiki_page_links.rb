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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Wikis::Concerns
  module UpdateReverseInlineWikiPageLinks
    extend ActiveSupport::Concern

    # Mirrors the prefix character class of the inline-text macro matcher.
    # The trailing `(?!\w)` on the semantic branch keeps `#PROJ-1abc` from
    # matching `#PROJ-1`; the numeric branch deliberately has no trailing
    # boundary to preserve historic behaviour for inputs like `#13-blubb`.
    # rubocop:disable Style/RedundantRegexpEscape
    WP_REF_RE = /
      (?:[[:space:],~>\#\(\[\-]|^)\#
      (?:
        (\d+)
        |
        (#{WorkPackage::SemanticIdentifier::SEMANTIC_ID_PATTERN.source})(?!\w)
      )
    /x
    # rubocop:enable Style/RedundantRegexpEscape

    def update_reverse_inline_wiki_page_links(wiki_page)
      provider = Wikis::InternalProvider.enabled.first
      return if provider.nil?

      Wikis::ReverseInlinePageLink.where(provider:, identifier: wiki_page.id).delete_all

      identifiers = find_wp_links(wiki_page.text).uniq
      return if identifiers.empty?

      WorkPackage.where_display_id_in(identifiers).find_each do |wp|
        Wikis::ReverseInlinePageLink.create!(linkable: wp, provider:, identifier: wiki_page.id)
      end
    end

    private

    def find_wp_links(text)
      return [] if text.blank?

      text.scan(WP_REF_RE).map { |numeric, semantic| numeric || semantic }
    end
  end
end
