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
  module UpdateInlineWikiPageLinks
    extend ActiveSupport::Concern

    def update_inline_wiki_page_links(linkable, *texts)
      Wikis::InlinePageLink.where(linkable:).delete_all
      texts.flat_map { |text| find_wiki_links(text) }.uniq.each do |provider_id, identifier|
        provider = Wikis::Provider.find_by(id: provider_id)
        next if provider.nil?

        Wikis::InlinePageLink.create!(linkable:, provider:, identifier:)
      end
    end

    private

    def find_wiki_links(text)
      return [] if text.blank?

      # The text is markdown that escapes literal [ and ] characters. We unescape them first.
      text = text.gsub("\\[", "[").gsub("\\]", "]")
      text.scan(Wikis::TextFormatting::WikiLinkMatcher.regexp)
    end
  end
end
