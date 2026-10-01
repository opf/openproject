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

module Wikis
  module TextFormatting
    class WikiLinkMatcher < OpenProject::TextFormatting::Matchers::RegexMatcher
      include Dry::Monads[:result]

      class << self
        def applicable?(*)
          super && OpenProject::FeatureDecisions.wiki_enhancements_active?
        end

        def regexp
          /\[\[\[([0-9]+):([^\]\n]+)\]\]\]/
        end

        def process_match(match, _matched_string, _context)
          instance = new(
            provider_id: match[1],
            identifier: match[2]
          )

          instance.process
        end
      end

      attr_reader :provider_id, :identifier

      def initialize(provider_id:, identifier:)
        super()

        @provider_id = provider_id
        @identifier = identifier
      end

      def process
        view_context = ApplicationController.new.view_context

        DeferredInlinePageLinkMacroComponent.new(provider_id:, identifier:).render_in(view_context)
      end
    end
  end
end
